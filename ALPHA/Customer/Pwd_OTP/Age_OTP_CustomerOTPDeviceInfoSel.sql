USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Age_OTP_CustomerOTPDeviceInfoSel]
	@CustID			INT,
	@SubAccID		INT = 0,
	@ExpiredMins	INT = 129600 -- expire minutes
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

	IF @ExpiredMins IS NULL
		SELECT @ExpiredMins = 129600 -- default 3 months

	;WITH CTE_Info AS (
		SELECT c.CustID, c.SubAccId, cd.DeviceId, ROW_NUMBER() OVER(PARTITION BY cd.DeviceId ORDER BY LastVerifiedDate DESC) AS rownum
		FROM dbo.CustOTP c WITH(NOLOCK)
			INNER JOIN dbo.CustOTPDetail cd WITH(NOLOCK) ON c.CustID = cd.CustID AND c.SubAccId = cd.SubAccId
		WHERE c.CustID = @CustID AND c.SubAccId = @SubAccID
			AND c.IsDelete = 0
			AND DATEADD(MINUTE, @ExpiredMins, cd.LastVerifiedDate) > GETDATE()
	)
	SELECT CustID, SubAccId, DeviceId
	FROM CTE_Info
	WHERE rownum = 1

END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPDeviceInfoSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerOTPDeviceInfoSel] TO [bodbDownlineNetView] AS [dbo]
GO