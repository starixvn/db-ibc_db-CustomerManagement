/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,wsv_nap, bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CustomerSelTotalDownline]
	@CustId INT,
	@RoleId TINYINT
AS
/*
	Creator: 20181108@Elodie
	Task: Get total downline info in left panel (Put on DB053 to use index IX_CI_srecommend for super, IX_custinfo for master and IX_custinfo_1 for agent)
	DB: DBAGE/bodb02
	
	Revisions:	
		- 20181108@Elodie: Get total downline info [RedmineID: #58776]
		- 20210524@Tina: Lock account & indirect close account [redmine: #148600]	

	Explanation: 
	
	Example: EXEC Acc_CustomerSelTotalDownline @CustID=24471545, @RoleId = 4
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TotalDownline TABLE (RoleId TINYINT, TotalActive INT, TotalClosed INT, TotalSuspended INT)					
		
	IF @RoleId = 2
	BEGIN
		INSERT INTO @TotalDownline (RoleId, TotalActive, TotalClosed, TotalSuspended)		
		SELECT	RoleID,
				ISNULL(SUM(CASE WHEN cps.Closed = 0 AND ISNULL(cps.reject,0) = 0 THEN 1 ELSE 0 END), 0),
				ISNULL(SUM(CASE WHEN cps.Closed = 1 THEN 1 ELSE 0 END), 0),
				ISNULL(SUM(CASE WHEN ISNULL(cps.reject,0) = 1 AND cps.closed = 0 THEN 1 ELSE 0 END), 0) 
		FROM custinfo ci (NOLOCK) 
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
		WHERE recommend = @custID AND RoleId = 1
		GROUP BY roleid	
	END
	ELSE IF @RoleId = 3
	BEGIN
		INSERT INTO @TotalDownline (RoleId, TotalActive, TotalClosed, TotalSuspended)		
		SELECT	RoleID,
				ISNULL(SUM(CASE WHEN cps.Closed = 0 AND ISNULL(cps.reject,0) = 0 THEN 1 ELSE 0 END), 0),
				ISNULL(SUM(CASE WHEN cps.Closed = 1 THEN 1 ELSE 0 END), 0),
				ISNULL(SUM(CASE WHEN ISNULL(cps.reject,0) = 1 AND cps.closed = 0 THEN 1 ELSE 0 END), 0)				
		FROM custinfo ci (NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps 
		WHERE mrecommend = @custID  AND RoleId IN (2,1)
		GROUP BY roleid
	END	
	ELSE IF @RoleId = 4
	BEGIN
		INSERT INTO @TotalDownline (RoleId, TotalActive, TotalClosed, TotalSuspended)		
		SELECT	RoleID,
				ISNULL(SUM(CASE WHEN cps.Closed = 0 AND ISNULL(cps.reject,0) = 0 THEN 1 ELSE 0 END), 0),
				ISNULL(SUM(CASE WHEN cps.Closed = 1 THEN 1 ELSE 0 END), 0),
				ISNULL(SUM(CASE WHEN ISNULL(cps.reject,0) = 1 AND cps.closed = 0 THEN 1 ELSE 0 END), 0)	
		FROM custinfo ci (NOLOCK) 
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps 
		WHERE srecommend = @custID  AND RoleId IN (3,2,1)
		GROUP BY roleid		
	END	

	SELECT RoleId, TotalActive, TotalClosed, TotalSuspended FROM @TotalDownline
END

GO
