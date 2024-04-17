USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Age_OTP_CustomerCheckEnableOTP]
	@CustID INT,
	@SubAccID INT = 0,
	@Enable BIT = 0 OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-10-13
	DB: DBCUST.CustDB
	Task: Select secret key

	Revisions:

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT @Enable = [Enabled]
	FROM dbo.CustOTP WITH(NOLOCK)
	WHERE CustID = @CustID AND SubAccId = @SubAccID AND IsDelete = 0

	SELECT @Enable = ISNULL(@Enable, CONVERT(BIT, 0))
END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerCheckEnableOTP] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerCheckEnableOTP] TO [wsv_alpv] AS [dbo]
GO