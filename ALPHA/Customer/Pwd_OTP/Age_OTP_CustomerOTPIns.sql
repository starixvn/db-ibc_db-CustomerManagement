USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Age_OTP_CustomerOTPIns]
	@CustID		INT,
	@SubAccID	INT = 0,
	@SecretKey	VARCHAR(50),
	@DeviceId	NVARCHAR(100),
	@DeviceInfo NVARCHAR(2000),

	@Language	VARCHAR(2) = 'E',
	@IP			NVARCHAR(200),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = N'' OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-10-13
	DB: DBCUST.CustDB
	Task: Insert secret key

	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = N''

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData VARCHAR(MAX), @IsInsert BIT, @CreateDate DATETIME
	SELECT  @startRun = GETDATE()

	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustOTP WITH(NOLOCK) WHERE CustID = @CustID AND SubAccId = @SubAccID AND IsDelete = 0)
	BEGIN
		SELECT	@ErrCode = 100,
				@ErrMsg = N'This account have a serect key before!'
		RETURN
	END

	BEGIN TRY
		IF EXISTS (SELECT TOP 1 1 FROM dbo.CustOTP WITH(NOLOCK) WHERE CustID = @CustID AND SubAccId = @SubAccID AND IsDelete = 1)
		BEGIN
			SELECT @IsInsert = 0, @CreateDate = CreatedDate FROM dbo.CustOTP WITH(NOLOCK) WHERE CustID = @CustID AND SubAccId = @SubAccID

			UPDATE dbo.CustOTP WITH(ROWLOCK, UPDLOCK)
			SET [Enabled] = 0, SecretKey = @SecretKey, IsDelete = 0, CreatedDate = @startRun
			WHERE CustID = @CustID AND SubAccId = @SubAccID
		END
		ELSE
		BEGIN
			SELECT @IsInsert = 1

			INSERT INTO dbo.CustOTP (CustID, SubAccId, [Enabled], IsDelete, SecretKey, CreatedDate)
			VALUES (@CustID, @SubAccID, 0, 0, @SecretKey, @startRun)
		END

		INSERT INTO dbo.CustOTPDetail (CustID, SubAccId, DeviceId, DeviceInfo, LastVerifiedDate)
		VALUES (@CustID, @SubAccID, @DeviceId, @DeviceInfo, @startRun)

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
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 101,
				@ErrMsg = N'Fail to insert new serect key!'

		-- rollback --
		IF @IsInsert = 1 -- just insert main table
		BEGIN
			DELETE dbo.CustOTP WITH(ROWLOCK, UPDLOCK)
			WHERE CustID = @CustID AND SubAccId = @SubAccID
		END
		ELSE -- just update main table
		BEGIN
			UPDATE dbo.CustOTP WITH(ROWLOCK, UPDLOCK)
			SET IsDelete = 1, CreatedDate = @CreateDate
			WHERE CustID = @CustID AND SubAccId = @SubAccID
		END

		RETURN
	END CATCH

	-- write log
	IF @SubAccID = 0
		SELECT @LogSPData = '<Age_OTP_CustomerOTPIns custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	ELSE
		SELECT @LogSPData = '<Age_OTP_CustomerOTPIns custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
					
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND, @startRun, @endRun)
			
	BEGIN TRY
		-- try to insert into DBLOG
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @CustID,
			@CustID = @CustID, 
			@ActionID = 926, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		IF @SubAccID = 0
			SELECT @LogSPData = '<Age_OTP_CustomerOTPIns custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
		ELSE
			SELECT @LogSPData = '<Age_OTP_CustomerOTPIns custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
									
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @CustID,
			@CustID = @CustID, 
			@ActionID = 926, 
			@TrackingValue = @LogSPData,
			@duration = @duration 
	END CATCH

	IF @ErrCode IS NULL
		SELECT @ErrCode = 0
	IF @ErrMsg IS NULL
		SELECT @ErrMsg = N''
END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPIns] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPIns] TO [bodbDownlineNetView,wsv_alpv] AS [dbo]
GO