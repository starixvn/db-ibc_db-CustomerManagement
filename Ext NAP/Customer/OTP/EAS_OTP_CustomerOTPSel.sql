USE [CustDB]
GO
/*
	Creator: David
	Date: 2018-05-03
	DB: DBCUST.CustDB
	Task: Select Customer OTP

	Revisions:

	Param's Explanation:
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[EAS_OTP_CustomerOTPSel]
	@CustID INT
AS
BEGIN
	SET NOCOUNT ON

	SELECT [SecretKey], [Enabled], [ModifiedDate]
	FROM dbo.EASCustOTP WITH(NOLOCK)
	WHERE CustID = @CustID
END
GO
GRANT VIEW DEFINITION ON [dbo].[EAS_OTP_CustomerOTPSel] TO [bodbExtAccNet]
GO