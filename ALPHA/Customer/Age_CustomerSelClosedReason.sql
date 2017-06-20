/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelClosedReason]
	@custid int,
	@RoleID TINYINT
AS

/*
	Created by: Winnie
	Date:[]
	Task: Customer List get closed reason for casino PT page
	DB: DBCUST.CustDB
	
	Revisions:	
		- 20170620@Winnie: apply color for closed account [RedmineID: #74494]	
*/

SET NOCOUNT ON

if @roleid = 2
BEGIN		
	SELECT c.custid,cl.ClosedReason
	from custinfo c with (nolock)
	LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 1 and c.recommend = @custid	
	UNION ALL
	SELECT cl.custid,cl.ClosedReason
	from CustLoginInfo cl WITH(NOLOCK) 
	where cl.CustID = @custid
	
END
else if @roleid = 3
BEGIN
	SELECT c.custid,cl.ClosedReason
	from custinfo c with (nolock)
	LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 1 and c.recommend = @custid	
	UNION ALL	
	SELECT  c.custid,cl.ClosedReason
	from custinfo c with (nolock)
	LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 2 and c.mrecommend = @custid	
END
else if @roleid = 4
BEGIN
	SELECT c.custid,cl.ClosedReason
	from custinfo c with (nolock)
	LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 1 and c.recommend = @custid	
	UNION ALL		
	SELECT  c.custid,cl.ClosedReason
	from custinfo  c with (nolock)
	LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid IN(2,3) and c.srecommend = @custid	
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelList] TO [bodbAdminNet]
GO
