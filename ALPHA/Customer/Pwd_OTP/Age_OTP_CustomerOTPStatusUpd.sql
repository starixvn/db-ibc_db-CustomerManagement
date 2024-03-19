USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Age_OTP_CustomerOTPStatusUpd]
	@UserID INT,
	@CustID INT,
	@SubAccID INT = 0,
	@Enable BIT = 0,

	@Language VARCHAR(2) = 'E',
	@IP NVARCHAR(200),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = N'' OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-10-13
	DB: DBCUST.CustDB
	Task: Enable/disable secret key

	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = N''

	DECLARE @Status NVARCHAR(7), @ActionID INT
	IF @Enable = 1
	BEGIN
		SELECT @Status = N'enable', @ActionID = 927
	END
	ELSE
	BEGIN
		SELECT @Status = N'disable', @ActionID = 928
	END

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData VARCHAR(MAX), @DeviceInfo NVARCHAR(2000)
	SELECT  @startRun = GETDATE()

	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustOTP WITH(NOLOCK) WHERE CustID = @CustID AND SubAccId = @SubAccID AND [Enabled] = @Enable AND IsDelete = 0)
	BEGIN
		SELECT	@ErrCode = 100,
				@ErrMsg = N'Secret Key of this account has been ' + @Status + 'd before!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.CustOTP WITH(ROWLOCK, UPDLOCK)
		SET [Enabled] = @Enable
		WHERE CustID = @CustID AND SubAccId = @SubAccID
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 101,
				@ErrMsg = N'Fail to ' + @Status + ' Secret Key!'
		RETURN
	END CATCH

	-- write log
	IF @SubAccID = 0
		SELECT @LogSPData = '<Age_OTP_CustomerOTPStatusUpd custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	ELSE
		SELECT @LogSPData = '<Age_OTP_CustomerOTPStatusUpd custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
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
			@ActionID = @ActionID, 
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		IF @SubAccID = 0
			SELECT @LogSPData = '<Age_OTP_CustomerOTPStatusUpd custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
		ELSE
			SELECT @LogSPData = '<Age_OTP_CustomerOTPStatusUpd custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
									
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustID, 
			@ActionID = @ActionID, 
			@TrackingValue = @LogSPData,
			@duration = @duration 
	END CATCH

	IF @ErrCode IS NULL
		SELECT @ErrCode = 0
	IF @ErrMsg IS NULL
		SELECT @ErrMsg = N''
END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPStatusUpd] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPStatusUpd] TO [bodbDownlineNetView,wsv_alpv] AS [dbo]
GO