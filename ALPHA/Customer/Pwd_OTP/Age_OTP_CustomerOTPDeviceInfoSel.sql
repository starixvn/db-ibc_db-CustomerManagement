/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" selecters=""></info>*/
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
		- 20221129@Johnson: dont check CustOTP for OTP telegram chatbot [redmine:#178790]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	IF @ExpiredMins IS NULL
		SELECT @ExpiredMins = 129600 -- default 3 months

	;WITH CTE_Info AS (
		SELECT cd.CustID, cd.SubAccId, cd.DeviceId, ROW_NUMBER() OVER(PARTITION BY cd.DeviceId ORDER BY LastVerifiedDate DESC) AS rownum
		FROM dbo.CustOTPDetail cd WITH(NOLOCK)
		WHERE cd.CustID = @CustID AND cd.SubAccId = @SubAccID			
			AND DATEADD(MINUTE, @ExpiredMins, cd.LastVerifiedDate) > GETDATE()
	)
	SELECT CustID, SubAccId, DeviceId
	FROM CTE_Info
	WHERE rownum = 1

END
GO
