USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Age_OTP_CustomerOTPSel]
	@CustID INT,
	@SubAccID INT = 0
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

	SELECT CustID, SubAccId, SecretKey, [Enabled], CreatedDate
	FROM dbo.CustOTP WITH(NOLOCK)
	WHERE CustID = @CustID AND SubAccId = @SubAccID AND IsDelete = 0
END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPSel] TO [bodbDownlineNetView] AS [dbo]
GO