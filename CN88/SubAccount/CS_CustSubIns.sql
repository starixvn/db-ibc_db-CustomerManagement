/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustSubIns	
	@custid INT, -- agentid or masterid or superid
	@username VARCHAR(30),
	@userpwd VARCHAR(40),
	@firstname NVARCHAR(50) = '-',
	@PageAccess VARCHAR(50),
	@Language VARCHAR(2) = 'E',
	@LoginIP VARCHAR(20)='',
	@UserID INT=0,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20190329
	Task : Create new sub-account for agent of CN88
	DB: DBCust/CustDB

	Revisions:    
		- 20190329@Elodie: Initial SP [Redmine:#110497]

	Param's Explanation:
		• @ErrCode:
			= 0: Create successfully.
			> 0: Specific Error.
  
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData VARCHAR(MAX)
	DECLARE @ErrLog NVARCHAR(200), @NoOfSubAcc TINYINT, @MaxOfSubAcc TINYINT, @PwdExpiry DATETIME
	DECLARE	@UplineSecurityCode	VARCHAR(50) , @isForcedChangeSecurityCode BIT, @subaccid INT

	SET @startRun = GETDATE()

	SELECT @PwdExpiry = dbo.f_CS_GetPwdExpiryDate(2)
	SELECT @username = LTRIM(RTRIM(@username))

	--check duplicate username
	IF (EXISTS (SELECT 1 FROM custsub WITH (NOLOCK) WHERE username = @username))
		OR (EXISTS (SELECT 1 FROM customer WITH (NOLOCK) WHERE username = @username OR username2 = @username))
		OR EXISTS(SELECT 1 FROM Dep_Customer_Archived WITH (NOLOCK) WHERE username= @username)
		OR EXISTS (SELECT 1 FROM Dep_Customer_Archived WITH (NOLOCK) WHERE username2 = @username)
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' then 'This user name is not available.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40001,@Language) END,
				@ErrCode=102		
		RETURN	
	END

	--check no of subacc (must <= @MaxOfSubAcc)
	SELECT @NoOfSubAcc = count(1) FROM custsub WITH(NOLOCK) WHERE custid = @custid

	SELECT @MaxOfSubAcc = CASE roleid WHEN 4 THEN 10 ELSE 5 END
	FROM customer  WITH(NOLOCK)
	WHERE custid = @custid

	if @NoOfSubAcc >= @MaxOfSubAcc
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' then 'You have exceeded your sub-accounts limit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40008,@Language) END,
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
		createdate			
	)
	VALUES
	(
		@custid,
		@username,			
		@userpwd,
		@firstname,
		'',
		@PageAccess,
		GETDATE()
	)

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' then 'Create sub-account failed. Please try again.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40009,@Language) END, 
				@ErrCode = 104
		RETURN	
	END

	SELECT @subaccid = @@IDENTITY

	EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Ins @custid, @subaccid, 0, @ErrCode, @ErrMsg
	
	IF @ErrCode <> 0
	BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Create sub-account failed. Please try again.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language) END,
					@ErrCode = 106
		 -- ROLLBACK MANUALLY
			DELETE FROM custsub WITH(ROWLOCK) WHERE subaccid = @subaccid
		
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
		@subaccid, @CustID, NULL, @PwdExpiry, GETDATE(), 1,
		0, NULL, @isForcedChangeSecurityCode, NULL
	)
	
	if @@ERROR <> 0
	BEGIN
		DELETE FROM custsub WITH(ROWLOCK) WHERE subaccid = @subaccid

		EXEC DBMSG.bodb_Message.dbo.Age_MsgCustReadStatus_Del @custid, @subaccid
	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Create sub-account failed. Please try again.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language) END,
				@ErrCode = 105

		RETURN
	END

	--Write log
	Select @LogSPData =	'<R subaccid="'+ COALESCE(CAST(@SubAccID as varchar(30)),SPACE(1)) + '" ' +
						'username="'+ COALESCE(CAST(@username as varchar(30)),SPACE(1)) + '" ' +
						'fname="'+ COALESCE(CAST(@firstname as varchar(100)),SPACE(1)) + '" ' +
						'PageAccess="'+ COALESCE(CAST(@PageAccess as varchar(50)),SPACE(1)) + '" ' +
						'Language="'+ COALESCE(CAST(@Language as varchar(2)),SPACE(1)) + '" ' +
						'LoginIP="'+ COALESCE(CAST(@LoginIP as varchar(20)),SPACE(1)) + '" ' +
						'UserID="'+ COALESCE(CAST(@UserID as varchar(50)),SPACE(1)) + '" ' +
						'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),SPACE(1)) + '" ' +
						'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(8000)),SPACE(1)) + '" />'

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 685,
		@TrackingValue = @LogSPData,
		@duration = @duration	
END	
GO

