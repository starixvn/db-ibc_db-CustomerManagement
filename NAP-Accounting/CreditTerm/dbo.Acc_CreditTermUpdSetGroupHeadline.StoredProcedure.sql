/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermUpdSetGroupHeadline]
	@CustID INT,
	@groupID INT,
	@UserID INT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = '',
	@Case INT = 0 OUTPUT,
	@Old_Headline INT = 0 OUTPUT,
	@New_Headline INT = 0 OUTPUT
AS
--Original: ADMIN\account\creditterm_group_feed_add.asp
/*	Created by: [Creator]
	DB: DBCUST/CUSTDB
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
		- 20090919@Shifu: Log IP
		- 20100112@Kiwi: amend to write log in xml format.				
		- 20101021@Henry: Record execution time 
		- 20110709@Johnson: Change to use new server BD053 instead DB052
		- 20130131@Elodie: Change link server DB03 to DBPOLICY, DB053 to DBAGE
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
		- 20160607@Elodie: Add headline type and their owner [Redmine:#51923]
		- 20160915@Elodie: SMA Mangement allows to input freetext for Owner info [Redmine:#63349]
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181107@Louis: Credit Collection [Redmine: #98621]
		- 20200717@Malcolm : Integrate Credit Term & Staff/Boss Management [RedmineID : #137144]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241225@July: Scale out DB - In-house Replicator - Support change for SMA TO Control [Redmine: #207042]
		- 20250102@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

	Param's Explanation:
		@Case = 0 : No change
		      = 1 : IsGroupHeadline 0-> 0, the user change group
			  = 2 : IsGroupHeadline 1-> 0
			  = 3 : IsGroupHeadline 0-> 1, the user don't change group
			  = 4 : IsGroupHeadline 0-> 1, the user change group

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	DECLARE @oldchecker INT, @CustID_oldGroupHeadline INT, @UserName VARCHAR(30)
	
	DECLARE @NotificationInfo VARCHAR(MAX)
	
	SET @startRun = GETDATE()

	--Check an account disabled or not
	 EXEC Acc_CustomerSelCheckEnable @custid = @CustID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	 IF @ErrCode <>0        RETURN

	IF NOT EXISTS (SELECT 1 FROM custaccount WITH (NOLOCK) WHERE custid = @custid and groupid = @groupID)
	BEGIN
		SELECT @ErrMsg = 'This user does not belong to this group.',
			@ErrCode = 101
		Return
	END
		 
	EXEC dbo.Acc_CreditTermUpdCollStatus @CustId = @custid, @UserID = @UserID, @IP = @IP, @Language = @Language, @Mode = 2
		,@OldGroupId = @groupid, @NewGroupId = @groupid, @Old_IsGroupHeadline = 0, @New_IsGroupHeadline = 1	
					
	SELECT @oldchecker = checker, @CustID_oldGroupHeadline = custid FROM custaccount WITH (NOLOCK) 
	WHERE groupid =@groupid and isgroupheadline = 1 

	SELECT @UserName = Username FROM dbo.Customer WITH(NOLOCK) WHERE custid = @CustID

	UPDATE custAccount SET Isgroupheadline = 0 ,checker = 0, RepUpdateTime = dbo.f_GetDateTime2() WHERE groupid = @groupID

	UPDATE custAccount SET Isgroupheadline = 1, checker = @oldchecker, RepUpdateTime = dbo.f_GetDateTime2() WHERE custid = @CustID

	UPDATE dbo.CustGroupHeadline WITH (ROWLOCK, UPDLOCK) 
	SET CustID = @CustID,
		OwnerName = '',
		RepUpdateTime = dbo.f_GetDateTime2()
	WHERE GroupID = @groupID

	SELECT @Case = 3, @New_Headline = @CustID_oldGroupHeadline, @Old_Headline = @CustID_oldGroupHeadline
	
	-- Update TO Control for Global setting
	IF EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH (NOLOCK) WHERE CustID = @CustID_oldGroupHeadline AND IsGroupHeadLine = 1 )
	BEGIN
		UPDATE GS
			SET CustID = @CustID
			  , RepUpdateTime = dbo.f_GetDateTime2()
		FROM dbo.TOControl_GlobalSetting GS WITH (ROWLOCK,UPDLOCK)
		WHERE GS.CustID = @CustID_oldGroupHeadline AND GS.IsGroupHeadLine = 1
		
		UPDATE TOs
			SET CustID = @CustID
		FROM dbo.TOControl_Setting TOs WITH (ROWLOCK,UPDLOCK)
		WHERE TOs.CustID = @CustID_oldGroupHeadline AND TOs.IsGroupHeadLine = 1
		
	END
	-- TO Control: Email Notification
	SELECT @NotificationInfo = '<GroupHeadline custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" ' +
							'oldcustid="'+ COALESCE(CAST(@CustID_oldGroupHeadline AS VARCHAR(50)),SPACE(1)) + '" ' +
							'GroupID="'+ COALESCE(CAST(@groupid AS VARCHAR(50)),SPACE(1)) + '" />'
	EXEC dbo.NAP_Email_NotificationInfoInsert @ActionID = 1003,@NotificationInfo = @NotificationInfo, @CreateDate = @startRun
		
	DECLARE @LogData nvarchar(1000)
	SELECT @LogData = '<Acc_CreditTermUpdSetGroupHeadline Custid="' + convert(varchar(20), @CustID) + '" ' +
	'GroupID="' + convert(varchar(20), @groupID) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
	'ErrMsg="'+ @ErrMsg  + '" />'

	SET @endRun = getdate()
	SET @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1003,
			@TrackingValue = @LogData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_CreditTermUpdSetGroupHeadline Custid="' + convert(varchar(20), @CustID) + '" ' +
							'GroupID="' + convert(varchar(20), @groupID) + '" ' +
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
							'ErrMsg="'+ @ErrMsg + ' ' + error_message() + '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1003,
			@TrackingValue = @LogData,
			@duration = @duration

	END CATCH

	BEGIN TRY
		SELECT @LogData = '<Acc_CreditTermUpdSetGroupHeadline HeadlineID="'+ 
							CAST(@CustID AS VARCHAR(20))+'" HeadlineName="'+ ISNULL(@UserName,'') +'" IsGroupHeadline="1"/>'
		EXEC DBCRM.bodb_CRM.dbo.WriteLog_UserLog_crmUserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 912,
			@IP = @IP,
			@NewValues = @LogData
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 107, @ErrMsg = 'Internal error! Please try again or contact the administrator!'
		RETURN
	END CATCH

END
GO