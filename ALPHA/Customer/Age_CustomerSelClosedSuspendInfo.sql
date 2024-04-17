/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Age_CustomerSelClosedSuspendInfo
	@custid int,
	@RoleID TINYINT
AS
/*
	Created by: Elodie
	Date:[]
	Task: Customer List get suspend info
	DB: DBCUST/CustDB
	
	Revisions:	
		- 20210616@Elodie: apply color for closed and suspend account [RedmineID: #157050]
		- 20210701@Tina: All Sites - Lock account & indirect close account [RedmineID: #148600]
*/
BEGIN
	SET NOCOUNT ON

	IF @roleid = 2
	BEGIN		
		SELECT c.custid, cs.SuspendInfo, ISNULL(cl.ClosedReason,0) AS ClosedReason, cs.closed, cs.Locked, c.[Enabled]
		FROM custinfo c WITH (NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS closed
										, SuspendInfo
										, Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cs
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE c.roleid = 1 AND c.recommend = @custid AND (cs.SuspendInfo <> 0 OR cs.closed = 1 OR cs.Locked > 0 OR c.[Enabled] = 0)
		ORDER BY CASE WHEN c.[Enabled] = 0 THEN 4 WHEN ISNULL(cs.closed,0) <> 0 THEN 3 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 2 WHEN cs.Locked > 0 THEN 1 ELSE 0 END
	END
	ELSE IF @roleid = 3
	BEGIN
		SELECT c.custid, cs.SuspendInfo, ISNULL(cl.ClosedReason,0) AS ClosedReason, cs.closed, cs.Locked, c.[Enabled]
		FROM custinfo c WITH (NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS closed
										, SuspendInfo
										, Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cs
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE c.roleid = 2 AND c.mrecommend = @custid AND (cs.SuspendInfo <> 0 OR cs.closed = 1  OR cs.Locked > 0 OR c.[Enabled] = 0)
		ORDER BY CASE WHEN c.[Enabled] = 0 THEN 4 WHEN ISNULL(cs.closed,0) <> 0 THEN 3 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 2 WHEN cs.Locked > 0 THEN 1 ELSE 0 END
	END
	ELSE IF @roleid = 4
	BEGIN
		SELECT c.custid, cs.SuspendInfo, ISNULL(cl.ClosedReason,0) AS ClosedReason, cs.closed, cs.Locked, c.[Enabled]
		FROM custinfo c WITH (NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS closed
										, SuspendInfo
										, Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cs
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE c.roleid = 3 AND c.srecommend = @custid AND (cs.SuspendInfo <> 0 OR cs.closed = 1  OR cs.Locked > 0 OR c.[Enabled] = 0)
		ORDER BY CASE WHEN c.[Enabled] = 0 THEN 4 WHEN ISNULL(cs.closed,0) <> 0 THEN 3 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 2 WHEN cs.Locked > 0 THEN 1 ELSE 0 END
	END
END

GO
