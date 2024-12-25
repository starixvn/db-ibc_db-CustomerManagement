/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_CreditTermUpdCustomer]
	@custid int,
	@creditgrade nvarchar(1) = '',
	@preagreeamount money,
	@installmentamount money,
	@installmentdate nvarchar(50),
	@accountremark nvarchar(200),
	@groupID int,
	@IsGroupHeadline bit,
	@UserID int,
	@checker int =0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = '',
	@Case INT = 0 OUTPUT,
	@Old_Headline INT = 0 OUTPUT,
	@New_Headline INT = 0 OUTPUT
AS
/*
Created: 
Task : 
DB: DBCUST/CUSTDB
Original:

	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
		- 20090916@Shifu: Write log to db06				
		- 20090917@Phuc: Write log to dblog
		- 20100101@Lewin: Replace commas of Autoremark by string.Empty
		- 20100917@Kiwi: Correct "convert wrong datatype when writing log"				
		- 20101021@Henry: Record execution time 
		- 20110607@Amy: Write log Old values
		- 20110709@Johnson: Change to use new server BD053 instead DB052
		- 20130131@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181107@Louis: Credit Collection [Redmine: #98621]
		- 20200120@Tiara: Change message and allow to remove group which has 1 member [Redmine: #125991]
		- 20200717@Malcolm : Integrate Credit Term & Staff/Boss Management [RedmineID : #137144]
		- 20210301@Percy: Auto add Super into External Group (follow Headline) [RedmineID: #146710]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20240911@Tacy: add param - update CustAccount [Redmine: #209807]
		- 20241225@July: Scale out DB - In-house Replicator - Support change for SMA TO Control [Redmine: #207042]

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

	Declare @NewGroupID int, @db_groupID int, @db_IsGroupHeadline int,
			@NotFound bit,
			@db_checker int ,
			@old_creditgrade nvarchar(1),
			@old_preagreeamount money,
			@old_installmentamount money,
			@old_installmentdate nvarchar(50),
			@old_accountremark nvarchar(200),
			@CustID_oldGroupHeadline INT,
			@NotificationInfo VARCHAR(MAX),
			@CustID_Headline INT,
			@TotalMember INT,
			@Old_HeadlineName VARCHAR(30),
			@New_HeadlineName VARCHAR(30),
			@HeadlineID INT

	--Check disable user
		EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		if @ErrCode <>0 return
	--end

	-- Check super prefix
	DECLARE @RoleId TINYINT, @SiteId INT, @Currency INT, @UserName VARCHAR(50)
	SELECT @RoleId	= c.RoleId
		,@SiteId	= s.SiteId
		,@Currency	= c.Currency
		,@UserName	= c.UserName
	FROM dbo.Customer c WITH (NOLOCK)
		INNER JOIN dbo.Site s WITH (NOLOCK) ON c.Site = s.Site
	WHERE c.CustId = @CustId

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

	set @NotFound = 0

	select @NewGroupID = MAX(groupid) + 1
	from custaccount with (nolock)

	set @db_groupID = NULL

	select @db_groupID = groupID, @db_IsGroupHeadline = IsGroupHeadline ,@db_checker = isnull(checker,0),
		 @old_creditgrade = creditgrade,
			@old_preagreeamount = preagreeamount,
			@old_installmentamount = installmentamount,
			@old_installmentdate = installmentdate,
			@old_accountremark = accountremark
	from custAccount with (nolock)
	where custid = @custid
	--Get number of member in a group -20200120@Tiara
	SELECT @TotalMember= ISNULL(B.TotalMember,0)
	FROM custaccount CA WITH (NOLOCK)
		INNER JOIN (SELECT groupID, CASE WHEN groupID=0 THEN 0 ELSE (count(CA.custid)) END TotalMember FROM custAccount CA WITH (NOLOCK) INNER JOIN customer C WITH (NOLOCK) ON CA.custid = C.custid  GROUP BY groupID) B ON B.groupID = CA.groupID
		RIGHT JOIN customer C WITH (NOLOCK) ON CA.custid = C.custid 
	WHERE C.custid = @Custid AND ISNULL(C.site,'')<>'CN88'

	if @db_groupID is null
		select @NotFound = 1
		
	select @db_groupID = isnull(@db_groupID, 0),
		@db_IsGroupHeadline = isnull(@db_IsGroupHeadline, 0)

	IF @db_groupID <> 0
	BEGIN
		SELECT @Old_Headline = CustId FROM dbo.CustGroupHeadline WITH(NOLOCK) WHERE GroupID = @db_groupID
		SELECT @Old_HeadlineName = username FROM dbo.Customer WITH(NOLOCK) WHERE custid = @Old_Headline
	END

	if @NotFound = 1 and @IsGroupHeadline = 1
	BEGIN
		select @ErrMsg = 'New group created successfully.',
			@groupID = @NewGroupID,
			@IsGroupHeadline = 1			
	END	
	ELSE IF @NotFound = 1 and @IsGroupHeadline = 0
	BEGIN
		select @ErrMsg = 'Update Successfully.',
			@groupID = @groupID,
			@IsGroupHeadline = 0
			
		EXEC dbo.Acc_CreditTermUpdCollStatus @CustId = @custid, @UserID = @UserID, @IP = @IP, @Language = @Language, @Mode = 1
			,@OldGroupId = @db_groupID, @NewGroupId = @groupID, @Old_IsGroupHeadline = @db_IsGroupHeadline, @New_IsGroupHeadline = @IsGroupHeadline
		
		-- TO Control: Email Notification
		SELECT @CustID_Headline = CustID FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupID = @groupID

		SELECT @NotificationInfo = '<GroupHeadline custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" ' +
									'GroupID="'+ COALESCE(CAST(@groupid AS VARCHAR(50)),SPACE(1)) + '" />'
		-- Send email notification for create new
		EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 1000,@NotificationInfo = @NotificationInfo, @CreateDate = @startRun							
		
	END	
	else if @NotFound = 0 and @IsGroupHeadline = 1
	BEGIN
		if @db_IsGroupHeadline = 1 and @groupID <> @db_groupID
			Select @ErrMsg = 'Cannot change group.',
				@ErrCode = 100,
				@groupID = @db_groupID,			
				@IsGroupHeadline = 1,
				@checker = @db_checker
		else if @db_IsGroupHeadline = 1 and @groupID = @db_groupID
			Select @ErrMsg = 'Update Successfully.',
				@groupID = @db_groupID,			
				@IsGroupHeadline = 1
		else if @groupID = 0
			BEGIN
				Select @ErrMsg = 'New group created successfully.',
					@groupID = @NewGroupID,			
					@IsGroupHeadline = 1	
			END		
		else if @groupID <> 0
			BEGIN
				SELECT @ErrMsg = 'Update Successfully.',
					@groupID = @groupID,			
					@IsGroupHeadline = 1
					
				EXEC dbo.Acc_CreditTermUpdCollStatus @CustId = @custid, @UserID = @UserID, @IP = @IP, @Language = @Language, @Mode = 2
					,@OldGroupId = @db_groupID, @NewGroupId = @groupID, @Old_IsGroupHeadline = @db_IsGroupHeadline, @New_IsGroupHeadline = @IsGroupHeadline	
				
				-- TOControl: Update new headline in the global setting and TO Setting
				
				SELECT @CustID_oldGroupHeadline = custid 
				FROM custaccount WITH (NOLOCK) 
				WHERE groupid = @groupid AND isgroupheadline = 1
				
				-- Update TO Control for Global setting
				
				UPDATE GS
					SET CustID = @CustID
					  , RepUpdateTime = dbo.f_GetDateTime2()
				FROM dbo.TOControl_GlobalSetting GS WITH (ROWLOCK,UPDLOCK)
				WHERE GS.CustID = @CustID_oldGroupHeadline AND GS.IsGroupHeadLine = 1
				
				UPDATE TOs
					SET CustID = @CustID
				FROM dbo.TOControl_Setting TOs WITH (ROWLOCK,UPDLOCK)
				WHERE TOs.CustID = @CustID_oldGroupHeadline AND TOs.IsGroupHeadLine = 1
				
				-- TO Control: Email Notification FOR changing group headline
				SELECT @NotificationInfo = '<GroupHeadline custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" ' +
								'oldcustid="'+ COALESCE(CAST(@CustID_oldGroupHeadline AS VARCHAR(50)),SPACE(1)) + '" ' +
								'GroupID="'+ COALESCE(CAST(@groupid AS VARCHAR(50)),SPACE(1)) + '" />'
								
				EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 1003,@NotificationInfo = @NotificationInfo, @CreateDate = @startRun
					
				--select @checker = isnull(checker,0) from custaccount where groupid = @groupID and isgroupheadline =1 
				update custAccount set isgroupheadline = 0, checker = 0 where groupid = @groupID and custid <> @custid		
			END
	END
	else if @NotFound = 0 and @IsGroupHeadline = 0
	BEGIN
		if @db_IsGroupHeadline = 1 AND @TotalMember >1
			SELECT @ErrMsg = 'Cannot change group.',
				@ErrCode = 101,
				@groupID = @db_groupID,			
				@IsGroupHeadline = 1,
				@checker = @db_checker 
		ELSE IF @TotalMember = 1
		BEGIN
			SELECT @ErrMsg = 'Update Successfully.',
				@groupID = 0,
				@IsGroupHeadline = 0
		END
		ELSE
		BEGIN
			Select @ErrMsg = 'Update Successfully.',
				@groupID = @groupID,			
				@IsGroupHeadline = 0
		
			-- TO Control: Email Notification
			SELECT @CustID_Headline = CustID FROM dbo.CustGroupHeadline WITH (NOLOCK) WHERE GroupID = @groupID

			SELECT @NotificationInfo = '<GroupHeadline custid="'+ COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" ' +
										'GroupID="'+ COALESCE(CAST(@groupid AS VARCHAR(50)),SPACE(1)) + '" />'
			-- Send email notification for create new
			EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 1000,@NotificationInfo = @NotificationInfo, @CreateDate = @startRun	
	
		END		
	END
	if @IsGroupHeadline = 0 
	begin
		set @checker = 0
	end 
	
	-- get case
	SELECT @New_Headline = CustID FROM dbo.CustGroupHeadline WITH(NOLOCK) WHERE GroupID = @groupID

	SELECT @Case = CASE WHEN @IsGroupHeadline = 0 AND @db_IsGroupHeadline = 0 AND @groupID <> @db_groupID THEN 1
	                    WHEN @IsGroupHeadline = 0 AND @db_IsGroupHeadline = 1 AND @groupID <> @db_groupID THEN 2
						WHEN @IsGroupHeadline = 1 AND @db_IsGroupHeadline = 0 AND @groupID =  @db_groupID THEN 3
						WHEN @IsGroupHeadline = 1 AND @db_IsGroupHeadline = 0 AND @groupID <> @db_groupID AND @NewGroupID <>  @groupID THEN 4 
				   ELSE 0 END,
		   @New_Headline = ISNULL(@New_Headline,0)

	EXEC dbo.Acc_CreditTermUpdCustAccount
		@custid = @custid,
		@creditgrade = @creditgrade,
		@preagreeamount = @preagreeamount,
		@installmentamount = @installmentamount,
		@installmentdate = @installmentdate,
		@accountremark = @accountremark,
		@groupID = @groupID,
		@IsGroupHeadline = @IsGroupHeadline,
		@checker = @checker,
		@UserID = @UserID, 
		@IP = @IP

	-- Auto add External Group (follow Headline)
	BEGIN
		DECLARE @AffectedSupers VARCHAR(MAX)
		IF EXISTS (SELECT 1 FROM dbo.EaGroupHeadline WITH (NOLOCK) WHERE GroupHeadlineId IN (@GroupId, @db_groupID))
			EXEC dbo.Acc_ExternalGroupHeadline_UpdSuper
				@UserId					= @UserId
				,@CustId				= @CustId
				,@GroupHeadlineId		= @GroupId
				,@Old_GroupHeadlineId	= @db_groupID
				,@HeadlineId			= @Old_Headline
				,@SPName				= 'Acc_CreditTermUpdCustomer'
				,@AffectedSupers		= @AffectedSupers OUTPUT

		IF @db_groupID <> 0 AND ISNULL(@AffectedSupers, '') <> ''
		BEGIN
			IF @TotalMember = 1
				SELECT @ErrCode = 0, @ErrMsg = 'The headline group has been removed, the former headline is enqueued to be removed from its old External Groups on 0:00 tomorrow.'
			ELSE
				SELECT @ErrCode = 0, @ErrMsg = 'The super has been successfully removed from the Headline Group. This super is enqueued to be removed from its old External Groups on 0:00 tomorrow.'
		END
	END


	DECLARE @LogSPData AS NVARCHAR(MAX)
	DECLARE @TrackingValue2 AS NVARCHAR(MAX)

	SELECT @LogSPData = '<Acc_CreditTermUpdCustomer Custid="' + convert(varchar(20), @CustID) + '" '+
	'GroupID="' + convert(varchar(20), @groupID)+ '" '+
	'CreditGrade="' + coalesce(cast(@creditgrade as varchar(1)), space(1)) + '" '+
	'PreAgreeAmount="' + coalesce(cast(@preagreeamount as varchar(50)), space(1)) + '" '+
	'InstallmentAmount="' + coalesce(cast(@installmentamount as varchar(50)), space(1)) + '" '+
	'InstallmentDate="' + coalesce(cast(@installmentdate as varchar(50)), space(1)) + '" '+
	'AccountRemark="' +  dbo.f_EncodeXMLValue(coalesce(cast(@accountremark as nvarchar(200)), space(1))) + '" '+
	'IsGroupHeadline="' + coalesce(cast(@IsGroupHeadline as varchar(10)), space(1)) + '" '+
	'Checker="' + coalesce(cast(@checker as varchar(10)), space(1)) + '" '+
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" '+
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1))+ '" '+	
	'ErrMsg="'+ @ErrMsg + '" />'

	SELECT @TrackingValue2 = '<Acc_CreditTermUpdCustomer Custid="' + convert(varchar(20), @CustID) + '" '+
	'GroupID="' + convert(varchar(20), @db_groupID)+ '" '+
	'CreditGrade="' + coalesce(cast(@old_creditgrade as varchar(1)), space(1)) + '" '+
	'PreAgreeAmount="' + coalesce(cast(@old_preagreeamount as varchar(50)), space(1)) + '" '+
	'InstallmentAmount="' + coalesce(cast(@old_installmentamount as varchar(50)), space(1)) + '" '+
	'InstallmentDate="' + coalesce(cast(@old_installmentdate as varchar(50)), space(1)) + '" '+
	'AccountRemark="' +  dbo.f_EncodeXMLValue(coalesce(cast(@old_accountremark as nvarchar(200)), space(1))) + '" '+
	'IsGroupHeadline="' + coalesce(cast(@db_IsGroupHeadline as varchar(10)), space(1)) + '" '+
	'Checker="' + coalesce(cast(@db_checker as varchar(10)), space(1)) + '" '+
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" '+
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1))+ '" '+	
	'ErrMsg="'+ @ErrMsg + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	/*1001	Acc_CreditTermUpdCustomer	Update Credit Term*/
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1001,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Acc_CreditTermUpdCustomer Custid="' + convert(varchar(20), @CustID) + '" '+
							'GroupID="' + convert(varchar(20), @groupID)+ '" '+
							'CreditGrade="' + coalesce(cast(@creditgrade as varchar(1)), space(1)) + '" '+
							'PreAgreeAmount="' + coalesce(cast(@preagreeamount as varchar(50)), space(1)) + '" '+
							'InstallmentAmount="' + coalesce(cast(@installmentamount as varchar(50)), space(1)) + '" '+
							'InstallmentDate="' + coalesce(cast(@installmentdate as varchar(50)), space(1)) + '" '+
							'AccountRemark="' +  dbo.f_EncodeXMLValue(coalesce(cast(@accountremark as nvarchar(200)), space(1))) + '" '+
							'IsGroupHeadline="' + coalesce(cast(@IsGroupHeadline as varchar(10)), space(1)) + '" '+
							'Checker="' + coalesce(cast(@checker as varchar(10)), space(1)) + '" '+
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+ '" '+
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1))+ '" '+	
							'ErrMsg="'+ @ErrMsg + ' ' + error_message() +'" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1001,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH	

	BEGIN TRY
	    SET @HeadlineID = @New_Headline
		IF @IsGroupHeadline = 1
			SET @HeadlineID = @custid
		
		SELECT @New_HeadlineName = username FROM dbo.Customer WITH(NOLOCK) WHERE custid = @HeadlineID

		SELECT @TrackingValue2  =	'<Acc_CreditTermUpdCustomer HeadlineID ="' + CAST(ISNULL(@Old_Headline,0) AS VARCHAR(20))+ '" '
									+'HeadlineName ="' + ISNULL(@Old_HeadlineName,'Not assigned group') + '" '
									+'IsGroupHeadline ="' + CAST(ISNULL(@db_IsGroupHeadline, 0) AS VARCHAR(3)) + '" />'

		SELECT @LogSPData = '<Acc_CreditTermUpdCustomer HeadlineID ="' + CAST(ISNULL(@HeadlineID,0) AS VARCHAR(20))+ '" '
							+'HeadlineName ="' + ISNULL(@New_HeadlineName,'Not assigned group') + '" '
							+'IsGroupHeadline ="' + CAST(ISNULL(@IsGroupHeadline, 0) AS VARCHAR(3)) + '" />'

		EXEC DBCRM.bodb_CRM.dbo.WriteLog_UserLog_crmUserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 910,
			@IP = @IP,
			@NewValues = @LogSPData,
			@OldValues = @TrackingValue2
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 107, @ErrMsg = 'Internal error! Please try again or contact the administrator!'
		RETURN
	END CATCH
END
GO