/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelClosedReason]
	@custid int,
	@RoleID TINYINT
AS

/*
	Created by: Winnie
	Date:[]
	Task: Customer List get closed reason
	DB: DBCUST.CustDB
	
	Revisions:	
		- 20170620@Winnie: apply color for closed account [RedmineID: #74494]
		- 20210408@Tina: apply color for locked account [redmine: #148600]
			
*/

SET NOCOUNT ON

if @roleid = 2
BEGIN		
	SELECT c.custid,ISNULL(cl.ClosedReason,0) AS ClosedReason, ISNULL(ps.Locked,0) Locked
	FROM custinfo c WITH (NOLOCK)
		INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
		LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	WHERE c.roleid = 1 and c.recommend = @custid AND (ps.CloseInfo > 0 OR ps.Locked > 0)
	UNION ALL
	SELECT cl.custid,cl.ClosedReason, ISNULL(ps.Locked,0) Locked
	FROM CustLoginInfo cl WITH(NOLOCK) 
		INNER JOIN CustProductStatus ps WITH (NOLOCK) ON cl.custid = ps.CustID
	WHERE cl.CustID = @custid
	
END
else if @roleid = 3
BEGIN
	SELECT c.custid,ISNULL(cl.ClosedReason,0) AS ClosedReason, ISNULL(ps.Locked,0) Locked
	FROM custinfo c WITH (NOLOCK)
		INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
		LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	WHERE c.roleid = 1 and c.recommend = @custid  AND (ps.CloseInfo>0 OR ps.Locked > 0)	
	UNION ALL	
	SELECT  c.custid,ISNULL(cl.ClosedReason,0) AS ClosedReason, ISNULL(ps.Locked,0) Locked
	FROM custinfo c WITH (NOLOCK)
		INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	WHERE c.roleid = 2 and c.mrecommend = @custid AND (ps.CloseInfo>0 OR ps.Locked > 0)
END
ELSE IF @roleid = 4
BEGIN
	SELECT c.custid,ISNULL(cl.ClosedReason,0) AS ClosedReason, ISNULL(ps.Locked,0) Locked
	FROM custinfo c WITH (NOLOCK)
		INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
		LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	WHERE c.roleid = 1 and c.recommend = @custid  AND (ps.CloseInfo>0 OR ps.Locked > 0)	
	UNION ALL		
	SELECT  c.custid,ISNULL(cl.ClosedReason,0) AS ClosedReason, ISNULL(ps.Locked,0) Locked
	FROM custinfo  c WITH (NOLOCK)
		INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	WHERE c.roleid IN(2,3) and c.srecommend = @custid  AND (ps.CloseInfo>0 OR ps.Locked > 0)	
END
GO
