USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Age_OTP_CustomerOTPDel]
	@UserID		INT,
	@CustID		INT,
	@SubAccID	INT = 0,
	@DeviceInfo	NVARCHAR(2000) = '',

	@Language	VARCHAR(2) = 'E',
	@IP			NVARCHAR(200),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = N'' OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-10-13
	DB: DBCUST.CustDB
	Task: Delete secret key

	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = N''

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData VARCHAR(MAX)
	SELECT  @startRun = GETDATE()

	-- Check disable user
    EXEC dbo.Acc_CustomerSelCheckEnable
		@custid = @custid,
        @ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
    
	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = N'Failed to remove the registered device from disabled user.'
        
		RETURN
	END
	-- End

	IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.CustOTP WITH(NOLOCK) WHERE CustID = @CustID AND SubAccId = @SubAccID AND IsDelete = 0)
	BEGIN
		SELECT	@ErrCode = 100,
				@ErrMsg = N'This user has no registered device to be removed.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.CustOTP WITH(ROWLOCK, UPDLOCK)
		SET IsDelete = 1, [Enabled] = 0
		WHERE CustID = @CustID AND SubAccId = @SubAccID
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 101,
				@ErrMsg = N'Failed to remove OTP!'
		
		RETURN
	END CATCH

	IF @SubAccID = 0
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE CustID = @CustID)
		BEGIN
			UPDATE CustLoginInfo WITH(ROWLOCK, UPDLOCK)
			SET VerifyOTPCount = 0
			WHERE CustID = @CustID
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfoSub WITH(NOLOCK) WHERE CustID = @CustID)
		BEGIN
			UPDATE CustLoginInfoSub WITH(ROWLOCK, UPDLOCK)
			SET VerifyOTPCount = 0
			WHERE CustID = @CustID AND SubAccID = @SubAccID
		END
	END

	-- write log
	IF @SubAccID = 0
		SELECT @LogSPData = '<Age_OTP_CustomerOTPDel custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	ELSE
		SELECT @LogSPData = '<Age_OTP_CustomerOTPDel custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
					
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND, @startRun, @endRun)
			
	BEGIN TRY
		-- try to insert into DBLOG
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID, 
			@ActionID = 929, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		IF @SubAccID = 0
			SELECT @LogSPData = '<Age_OTP_CustomerOTPDel custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
		ELSE
			SELECT @LogSPData = '<Age_OTP_CustomerOTPDel custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
									
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustID, 
			@ActionID = 929, 
			@TrackingValue = @LogSPData,
			@duration = @duration 
	END CATCH

	IF @ErrCode IS NULL
		SELECT @ErrCode = 0
	IF @ErrMsg IS NULL
		SELECT @ErrMsg = N''
END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPDel] TO [wsv_nap] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPDel] TO [bodbExtAccNet,wsv_xnap] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPDel] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPDel] TO [bodbDownlineNetView,wsv_alpv] AS [dbo]
GO