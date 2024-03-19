  /*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
  ALTER PROCEDURE [dbo].[Age_CustomerUpdSecurityCode_Sub2]
	@subAccid	INT,	
	@custid		INT,	
	@userid		INT,
	@isForcedChangeSecuritycode BIT = 0,
	@Securitycode	VARCHAR(50) = '',
	@language	VARCHAR(2) = 'E' ,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT,
	@IP			VARCHAR(20) = ''
 AS
	/*
		Created: Johnson
		Date: 2013-04-12
		DB: DBCUST/CustDB
		Task: Main-account/upline update Security code of sub-account
		Revisions:
			- 20190618@Elodie: Input metadata
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
			,@uplineSecurityCode VARCHAR(50)
			
	SET @startRun = GETDATE()
	
	IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfoSub WITH(NOLOCK) WHERE subAccId = @subAccID and custid = @custid)
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
				@ErrCode = 100
		RETURN
	END
	
	SELECT @uplineSecurityCode = ISNULL(SecurityCode,'')
	FROM dbo.CustLoginInfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @custid = @userid AND @uplineSecurityCode = ''
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'You are not authorized on this function'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40028,@Language) END,
				@ErrCode = 101
		RETURN
	END
	
	--hard code to force sub-account change SC
	SELECT @isForcedChangeSecuritycode = 1
	
	UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
	SET SecurityCode = @SecurityCode
		,isForcedChangeSecuritycode = @isForcedChangeSecuritycode
		,LastChangedSecurityCodeDate = GETDATE()
	WHERE SubAccID = @SubAccId and custid = @custid

	IF @@Error > 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
				@ErrCode = 102
		RETURN
	END
	
	DECLARE @LogSPData VARCHAR(MAX)
	
	SELECT @LogSPData = '<Age_CustomerUpdSecurityCode_Sub2 SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
							+ 'isForcedChangeSecuritycode="' + COALESCE(CAST(@isForcedChangeSecuritycode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @userID,
			@CustID = @CustID, 
			@ActionID = 920, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Age_CustomerUpdSecurityCode_Sub2 SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
							+ 'isForcedChangeSecuritycode="' + COALESCE(CAST(@isForcedChangeSecuritycode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @userID,
			@CustID = @CustID, 
			@ActionID = 920, 
			@TrackingValue = @LogSPData,
			@duration = @duration 
	END CATCH
	
	
	
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdSecurityCode_Sub2] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdSecurityCode_Sub2] TO [bodbDownlineNetView,wsv_alpv]