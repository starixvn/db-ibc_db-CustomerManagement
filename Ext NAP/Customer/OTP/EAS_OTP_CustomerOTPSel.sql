/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE [CustDB]
GO
ALTER PROCEDURE [dbo].[EAS_OTP_CustomerOTPSel]
	@CustID INT
AS
/*
    Creator: David
	Date: 2018-05-10
	Task: Implement External OTP
	DB: DBCUST/CustDB

	Revisions:
		- 20180516@David: Select OTP [Redmine:#94192]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	SELECT [SecretKey], [Enabled], [ModifiedDate]
	FROM dbo.EASCustOTP WITH(NOLOCK)
	WHERE CustID = @CustID
END
GO