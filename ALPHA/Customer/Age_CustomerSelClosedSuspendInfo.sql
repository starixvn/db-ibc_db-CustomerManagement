/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbdownlineNet,bodbdownlineNetView" viewers="" isFunction="0"></info>*/
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
*/
BEGIN
	SET NOCOUNT ON

	IF @roleid = 2
	BEGIN		
		SELECT c.custid, cs.SuspendInfo, ISNULL(cl.ClosedReason,0) AS ClosedReason
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustProductStatus cs WITH(NOLOCK) ON c.custid = cs.CustID
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE c.roleid = 1 AND c.recommend = @custid AND (cs.SuspendInfo <> 0 OR c.closed = 1) --cs.CloseInfo <> 0)
		ORDER BY CASE WHEN ISNULL(c.closed,0) <> 0 THEN 2 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 1 ELSE 0 END
		--ORDER BY CASE WHEN ISNULL(CloseInfo,0) <> 0 THEN 2 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 1 ELSE 0 END
	END
	ELSE IF @roleid = 3
	BEGIN
		SELECT c.custid, cs.SuspendInfo, ISNULL(cl.ClosedReason,0) AS ClosedReason
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustProductStatus cs WITH(NOLOCK) ON c.custid = cs.CustID
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE c.roleid = 2 AND c.mrecommend = @custid AND (cs.SuspendInfo <> 0 OR c.closed = 1) --cs.CloseInfo <> 0)
		ORDER BY CASE WHEN ISNULL(c.closed,0) <> 0 THEN 2 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 1 ELSE 0 END
		--ORDER BY CASE WHEN ISNULL(CloseInfo,0) <> 0 THEN 2 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 1 ELSE 0 END
	END
	ELSE IF @roleid = 4
	BEGIN
		SELECT c.custid, cs.SuspendInfo, ISNULL(cl.ClosedReason,0) AS ClosedReason
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustProductStatus cs WITH(NOLOCK) ON c.custid = cs.CustID
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid = cl.CustID
		WHERE c.roleid = 3 AND c.srecommend = @custid AND (cs.SuspendInfo <> 0 OR c.closed = 1) --cs.CloseInfo <> 0)
		ORDER BY CASE WHEN ISNULL(c.closed,0) <> 0 THEN 2 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 1 ELSE 0 END
		--ORDER BY CASE WHEN ISNULL(CloseInfo,0) <> 0 THEN 2 WHEN ISNULL(SuspendInfo,0) <> 0 THEN 1 ELSE 0 END
	END
END

GO
