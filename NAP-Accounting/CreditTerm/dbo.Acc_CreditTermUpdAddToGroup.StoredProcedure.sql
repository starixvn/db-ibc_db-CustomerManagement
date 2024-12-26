/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_CreditTermUpdAddToGroup]
	@username varchar(30),
	@groupID int,
	@UserID int,
	@DeniedList	NVARCHAR(MAX)=NULL,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = '',
	@Case INT = 0 OUTPUT,
	@Old_Headline INT = 0 OUTPUT,
	@New_Headline INT = 0 OUTPUT,
	@AffectedSupers	VARCHAR(MAX) = '' OUTPUT
AS
--Original: adm_acct_UpdateCustAccount
/*	Created by: [Creator]
	DB: DBCUST/CUSTDB
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
		- 20090916@Shifu: Write log to DB06			
		- 20090917@Phuc: Write log to dblog
		- 20100112@Kiwi: amend to write log in xml format.		
		- 20101021@Henry: Record execution time
		- 20110709@Johnson: Change to use new server BD053 instead DB052
		- 20130131@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181105@Louis: Credit Collection Summary  [RedmineID: #98621]
		- 20190528@Winnie: NAP - Support CN88 Headline RedmineID: #112999
		- 20200717@Malcolm : Integrate Credit Term & Staff/Boss Management [RedmineID : #137144]
		- 20210301@Percy: Auto add Super into External Group (follow Headline) [RedmineID: #146710]
		- 20240528@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20240911@Tacy: add param - update CustAccount [Redmine: #209807]
	Param's Explanation:
		@Case = 0 : No change
		      = 1 : IsGroupHeadline 0-> 0, the user change group
			  = 2 : IsGroupHeadline 1-> 0
			  = 3 : IsGroupHeadline 0-> 1, the user don't change group
			  = 4 : IsGroupHeadline 0-> 1, the user change group
*/
BEGIN

	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	
	DECLARE @CustID_Headline INT, @NotificationInfo VARCHAR(MAX), @HeadlineName VARCHAR(30)
	DECLARE @srecommend INT,@site VARCHAR(10),@siteHeadline VARCHAR(10),@srecommendHeadline INT, @Old_GroupId INT

	Declare @Custid int, @SiteId int, @Currency int, @RoleId tinyint

	select @custid = custid,@srecommend=srecommend,@site=Site,@Currency=currency, @RoleId = RoleId from customer with (nolock) where username = @username
	select @SiteId = siteid from dbo.Site with (nolock) where site = @site
	select @custid = isnull(@custid, 0)

	if @custid = 0
	BEGIN
		SELECT @ErrMsg = 'Username is not valid',
			@ErrCode = 102
		Return
	END

	--Check an account disabled or not
	 EXEC Acc_CustomerSelCheckEnable @username = @username, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	 if @ErrCode <>0        return
	--end
	
	--Check permission on Site/Currency
	DECLARE @tmpSite TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)
	
	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmpSite (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	IF EXISTS (SELECT 1 FROM @tmpSite WHERE site=@site)
	OR EXISTS (SELECT 1 FROM @tmpExchange WHERE exchangeID=@Currency)
	BEGIN
		SELECT @ErrMsg = 'You don''t have permission to access: ' + @username,
			@ErrCode = 101
		Return
	END

	if exists (select 1 from custaccount with (nolock) where custid = @custid and isgroupheadline = 1)
	BEGIN
		SELECT @ErrMsg = 'Cannot add this user because this user is already headline in some group.',
			@ErrCode = 103
		Return
	END
			
	-- TO Control: Email Notification
	SELECT @Old_GroupId = ISNULL(GroupId,0) FROM dbo.custAccount WITH(NOLOCK) WHERE custid = @Custid
	SELECT @Old_Headline = CustID FROM dbo.CustGroupHeadline WITH(NOLOCK) WHERE GroupID = @Old_GroupId 
	SELECT @CustID_Headline = CustID FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupID = @groupID
	SELECT @HeadlineName = UserName FROM dbo.Customer WITH(NOLOCK) WHERE custid = @CustID_Headline
	SELECT @srecommendHeadline=srecommend,@siteHeadline=Site FROM Customer WITH(NOLOCK) WHERE Custid=@CustID_Headline
	IF(@siteHeadline IS NULL)
	BEGIN
		select @siteHeadline=Site from customer with (nolock) where Custid = @srecommendHeadline
	END
	IF (@siteHeadline='CN88' AND @site<>'CN88') OR  (@siteHeadline<>'CN88' AND @site='CN88')
	BEGIN
		SELECT @ErrMsg = 'Cannot add this user because difference site.',
			@ErrCode = 104
		RETURN
	END

	-- Check super prefix
	IF @RoleId = 4
	BEGIN
		DECLARE @tblPrefix TABLE (GroupName VARCHAR(50), Prefix VARCHAR(10), AllowNewSuper BIT)
		INSERT INTO @tblPrefix (GroupName, Prefix, AllowNewSuper)
		SELECT sp.GroupName, sp.Prefix, sp.AllowNewSuper
		FROM dbo.EaGroupHeadline egh WITH (NOLOCK)
			INNER JOIN dbo.Acc_SuperPrefix sp WITH (NOLOCK) ON egh.GroupName = sp.GroupName
		WHERE egh.GroupHeadlineId = @GroupId AND egh.SiteId = @SiteId AND egh.ExchangeId = @Currency
		
		IF @@ROWCOUNT <> 0
		BEGIN
			SET @ErrMsg = NULL
			SELECT @ErrMsg = COALESCE(@ErrMsg + ', ', '') + a.GroupName
			FROM (SELECT DISTINCT t.GroupName FROM @tblPrefix t WHERE t.GroupName NOT IN (SELECT p.GroupName FROM @tblPrefix p WHERE @UserName LIKE p.Prefix + '%' AND AllowNewSuper = 1)) a
			
			SELECT @ErrMsg = ISNULL(@ErrMsg, '')
			
			IF @ErrMsg <> ''
			BEGIN
				SELECT @ErrCode = 105, @ErrMsg = 'Wrong username prefix for the group(s) ' + @ErrMsg + '.'
				RETURN
			END
		END
	END

	Declare @creditgrade nvarchar(1),
		@preagreeamount money,
		@installmentamount money,
		@installmentdate nvarchar(50),
		@accountremark nvarchar(200)

	select @creditgrade = creditgrade, 
		@installmentdate = installmentdate,
		@installmentamount = installmentamount,
		@preagreeamount = preagreeamount,
		@accountremark = ' '
	from custaccount with (nolock)
	where isgroupheadline = 1 and groupid = @groupID

	EXEC dbo.Acc_CreditTermUpdCollStatus @CustId = @custid, @UserID = @UserID, @IP = @IP, @Language = @Language, @Mode = 3
		,@OldGroupId = 0, @NewGroupId = @groupID, @Old_IsGroupHeadline = 0, @New_IsGroupHeadline = 0	
	
	EXEC dbo.Acc_CreditTermUpdCustAccount 
		@custid = @custid,
		@creditgrade = @creditgrade,
		@preagreeamount = @preagreeamount,
		@installmentamount = @installmentamount,
		@installmentdate = @installmentdate,
		@accountremark = @accountremark,
		@groupID = @groupID,
		@isgroupheadline = 0,
		@UserID = @UserID, 
		@IP = @IP

	IF ISNULL(@Old_GroupId,0) = @groupID
		SELECT @Case = 0, @New_Headline = 0, @Old_Headline = ISNULL(@Old_Headline,0)
	ELSE
		SELECT @Case = 1, @New_Headline = @CustID_Headline, @Old_Headline = ISNULL(@Old_Headline,0) 

	SELECT @NotificationInfo = '<GroupHeadline custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" ' +
								'GroupID="'+ COALESCE(CAST(@groupid AS VARCHAR(50)),SPACE(1)) + '" />'
	-- Send email notification for create new
	EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 1000,@NotificationInfo = @NotificationInfo, @CreateDate = @startRun							
	
	-- Auto add External Group (follow Headline)
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.EaGroupHeadline WITH (NOLOCK) WHERE GroupHeadlineId IN (@GroupId, @Old_GroupId))
			EXEC dbo.Acc_ExternalGroupHeadline_UpdSuper
				@UserId					= @UserId
				,@CustId				= @CustId
				,@GroupHeadlineId		= @GroupId
				,@Old_GroupHeadlineId	= @Old_GroupId
				,@HeadlineId			= @CustID_Headline
				,@SPName 				= 'Acc_CreditTermUpdAddToGroup'
				,@AffectedSupers		= @AffectedSupers OUTPUT
	END

	declare @LogSPData nvarchar(1000)

	Select @LogSPData = '<Acc_CreditTermUpdAddToGroup Custid="' + convert(varchar(20), @CustID) + '" ' +
	'GroupID="'+ convert(varchar(20), @groupID) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
	'ErrMsg="'+ @ErrMsg  + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @Custid,
			@ActionID = 1000,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY	
	BEGIN CATCH
		SELECT @LogSPData = '<Acc_CreditTermUpdAddToGroup Custid="' + convert(varchar(20), @CustID) + '" ' +
							'GroupID="'+ convert(varchar(20), @groupID) + '" ' +
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
							'ErrMsg="'+ @ErrMsg + ' ' + error_message() + '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @Custid,
			@ActionID = 1000,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END CATCH
	BEGIN TRY
		SELECT @LogSPData = '<Acc_CreditTermUpdAddToGroup HeadlineID ="'+ CAST(@CustID_Headline AS VARCHAR(20))+'"  HeadlineName ="' + ISNULL(@HeadlineName,'') +'"/>'
		EXEC DBCRM.bodb_CRM.dbo.WriteLog_UserLog_crmUserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 909,
			@IP = @IP,
			@NewValues = @LogSPData				
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 107, @ErrMsg = 'Internal error! Please try again or contact the administrator!'
		RETURN
	END CATCH
END
GO