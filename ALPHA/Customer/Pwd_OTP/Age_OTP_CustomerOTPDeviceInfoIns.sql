/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OTP_CustomerOTPDeviceInfoIns]
	@CustID				INT,
	@SubAccID			INT = 0,
	@DeviceID			NVARCHAR(100),
	@DeviceInfo			NVARCHAR(2000),
	@Language			VARCHAR(2) = 'E',
	@IP					NVARCHAR(200),
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(200) = N'' OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-10-13
	DB: DBCUST.CustDB
	Task: Insert device info

	Revisions:
		- 20240813@Elodie: Insert device info for telegram chatbot OTP
		- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = N''

	--IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.CustOTP WITH(NOLOCK) WHERE CustID = @CustID AND SubAccId = @SubAccID AND IsDelete = 0)
	--BEGIN
	--	SELECT	@ErrCode = 100,
	--			@ErrMsg = N'This account don''t use OTP!'
		
	--	RETURN
	--END

	BEGIN TRY
		INSERT INTO dbo.CustOTPDetail (CustID, SubAccId, DeviceId, DeviceInfo, LastVerifiedDate, RepUpdateTime)
		VALUES (@CustID, @SubAccID, @DeviceID, @DeviceInfo, GETDATE(), dbo.f_GetDateTime2())
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode = 101,
				@ErrMsg = N'Fail to insert device!'
		
		RETURN
	END CATCH

	IF @ErrCode IS NULL
		SELECT @ErrCode = 0
	IF @ErrMsg IS NULL
		SELECT @ErrMsg = N''
END
GO
