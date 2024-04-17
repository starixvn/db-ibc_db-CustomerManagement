/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdSecurityCode_Sub]
	@subAccid	INT,	
	@custid		INT,			
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
		Task: Sub-account reset Security code
		Revisions:
			- 20190618@Elodie: Input metadata
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
	
	SET @startRun = GETDATE()
	
	IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfoSub WITH(NOLOCK) WHERE subAccId = @subAccID and custid = @custid)
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
				@ErrCode = 100
		RETURN
	END
	
	UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
	SET SecurityCode = @SecurityCode
		,isForcedChangeSecuritycode = 0
		,LastChangedSecurityCodeDate = GETDATE()
	WHERE SubAccID = @SubAccId and custid = @custid

	IF @@Error > 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
				@ErrCode = 101
		RETURN
	END
	
	DECLARE @LogSPData VARCHAR(MAX)
	
	SELECT @LogSPData = '<Age_CustomerUpdSecurityCode_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 							
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @custid,
			@CustID = @CustID, 
			@ActionID = 919, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Age_CustomerUpdSecurityCode_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 						
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @custid,
			@CustID = @CustID, 
			@ActionID = 919, 
			@TrackingValue = @LogSPData,
			@duration = @duration 
	END CATCH

GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdSecurityCode_Sub] TO [wsv_alp] AS [dbo]