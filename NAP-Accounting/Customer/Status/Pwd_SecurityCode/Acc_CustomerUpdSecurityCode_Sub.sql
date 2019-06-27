/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdSecurityCode_Sub]
	@subAccid	INT,	
	@custid		INT,	
	@userid		INT,	
	@Securitycode	VARCHAR(50) = '',
	@language	VARCHAR(2) = 'E' ,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT,
	@IP			VARCHAR(20) = ''
 AS
	/*
		Created: Johnson
		Date: 2013-05-02
		Task: Admin update Security Code for sub-account by tool
		DB: DBCUST/CUSTDB
		
		Revisions:
			- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
			
		Parameter's Explanation:
	*/
BEGIN	
	SET NOCOUNT ON
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
			,@uplineSecurityCode VARCHAR(50)
			
	SET @startRun = GETDATE()
	
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SecurityCode]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	
	IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfoSub WITH(NOLOCK) WHERE subAccId = @subAccID and custid = @custid)
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
				@ErrCode = 100
		RETURN
	END
		
	UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
	SET SecurityCode = @SecurityCode
		,isForcedChangeSecuritycode = 1
		,LastChangedSecurityCodeDate = GETDATE()
	WHERE SubAccID = @SubAccId and custid = @custid

	IF @@Error > 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccessful. Please try again.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
				@ErrCode = 101
		RETURN
	END
	
	DECLARE @LogSPData VARCHAR(MAX)
	
	SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 							
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @userID,
			@CustID = @CustID, 
			@ActionID = 923, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 							
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @userID,
			@CustID = @CustID, 
			@ActionID = 923, 
			@TrackingValue = @LogSPData,
			@duration = @duration 
	END CATCH
END	
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSecurityCode_Sub] TO [bodbAdminNet]