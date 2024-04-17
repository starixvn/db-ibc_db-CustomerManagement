/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustSubIns	
	@custid INT, -- agentid or masterid or superid
	@username VARCHAR(30),
	@userpwd VARCHAR(40),
	@firstname NVARCHAR(50) = '-',
	@PageAccess VARCHAR(50),
	@Language VARCHAR(2) = 'E',
	@LoginIP VARCHAR(20)='',
	@UserID INT=0,
	@SubAccId INT = 0 OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190329
	Task : Create new sub-account for agent of CN88
	DB: DBCust/CustDB

	Revisions:    
		- 20190329@Elodie: Initial SP [Redmine:#110497]
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
		- 20190716@Elodie: Change maximum sub accounts [Redmine: #116825]
		- 20190715@Elodie: Sub account management [Redmine:#116825] 

	Param's Explanation:
		• @ErrCode:
			= 0: Create successfully.
			> 0: Specific Error.
  
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData NVARCHAR(MAX)
	DECLARE @ErrLog NVARCHAR(200), @NoOfSubAcc TINYINT, @MaxOfSubAcc TINYINT, @PwdExpiry DATETIME
	DECLARE	@UplineSecurityCode	VARCHAR(50) , @isForcedChangeSecurityCode BIT

	SET @startRun = GETDATE()

	SELECT @PwdExpiry = dbo.f_CS_GetPwdExpiryDate(2)
	SELECT @username = LTRIM(RTRIM(@username))

	--check duplicate username
	DECLARE @IsExists BIT 
	EXEC CS_CustomerCheckExists @username = @username, @Mode = 0, @IsExists = @IsExists OUTPUT

	IF @IsExists = 1
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' then 'This username is not available.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40001,@Language) END,
				@ErrCode=102		
		RETURN	
	END

	--check no of subacc (must <= @MaxOfSubAcc)
	SELECT @NoOfSubAcc = count(1) FROM custsub WITH(NOLOCK) WHERE custid = @custid AND IsDeleted = 0
	SELECT @MaxOfSubAcc = 10

	if @NoOfSubAcc >= @MaxOfSubAcc
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' then 'You have exceeded the maximum number of Sub Account. Unable to proceed with account creation.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40042,@Language) END,
				@ErrCode=103		
		RETURN	
	END

	--Insert data to db
	INSERT INTO custsub
	(
		custid,
		username,
		userpwd,
		firstname,
		lastname,
		PageAccess,
		createdate,
		IsAllDownline,
		IsDeleted			
	)
	VALUES
	(
		@custid,
		@username,			
		@userpwd,
		@firstname,
		'',
		@PageAccess,
		GETDATE(),
		0,
		0
	)

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' then 'Create sub-account failed. Please try again.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40009,@Language) END, 
				@ErrCode = 104
		RETURN	
	END

	SELECT @SubAccId = @@IDENTITY

	EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Ins @custid, @SubAccId, 0, @ErrCode, @ErrMsg
	
	IF @ErrCode <> 0
	BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Create sub-account failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language) END,
					@ErrCode = 106
		 -- ROLLBACK MANUALLY
			DELETE FROM custsub WITH(ROWLOCK) WHERE subaccid = @SubAccId
		
			RETURN
	END

	SELECT @UplineSecurityCode = NULL,
		   @isForcedChangeSecurityCode = 0

	SELECT	@UplineSecurityCode = SecurityCode,
			@isForcedChangeSecurityCode = isForcedChangeSecurityCode
	  FROM dbo.CustLoginInfo WITH(NOLOCK)
	 WHERE CustID = @CustID

	IF @UplineSecurityCode IS NOT NULL OR @isForcedChangeSecurityCode = 1
		SELECT @isForcedChangeSecurityCode = 1

	INSERT INTO dbo.CustLoginInfoSub
	(
		SubAccID, CustID, OldUserPwd, PwdExpiry, LastChangedPwdDate, isFirstLogin,
		SecurityCodeCount, SecurityCode, isForcedChangeSecurityCode, LastChangedSecurityCodeDate
	)
	VALUES
	(   
		@SubAccId, @CustID, NULL, @PwdExpiry, GETDATE(), 1,
		0, NULL, @isForcedChangeSecurityCode, NULL
	)
	
	if @@ERROR <> 0
	BEGIN
		DELETE FROM custsub WITH(ROWLOCK) WHERE subaccid = @SubAccId

		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del @custid, @SubAccId
	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Create sub-account failed. Please try again.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language) END,
				@ErrCode = 105

		RETURN
	END

	--Write log
	Select @LogSPData =	'<R subaccid="'+ COALESCE(CAST(@SubAccId as VARCHAR(30)),SPACE(1)) + '" ' +
						'username="'+ COALESCE(CAST(@username as VARCHAR(30)),SPACE(1)) + '" ' +
						'fname="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@firstname AS NVARCHAR(50)),SPACE(1))) + '" ' +
						'PageAccess="'+ COALESCE(CAST(@PageAccess as VARCHAR(50)),SPACE(1)) + '" ' +
						'Language="'+ COALESCE(CAST(@Language as VARCHAR(2)),SPACE(1)) + '" ' +
						'LoginIP="'+ COALESCE(CAST(@LoginIP as VARCHAR(20)),SPACE(1)) + '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 685,
		@TrackingValue = @LogSPData,
		@duration = @duration,
		@SubAccId = @SubAccId
END	
GO

