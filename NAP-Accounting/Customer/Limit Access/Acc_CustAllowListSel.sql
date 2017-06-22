ALTER PROCEDURE [dbo].[Acc_CustAllowListSel]
AS
/*
Created: 20120312@Elodie
Task : get all user info in the monitoring list
DB: DBTrans.bodb02
Original:

Revisions:
	
Param's Explanation:
*/
SET NOCOUNT ON
BEGIN	
	SELECT c1.custid,
	c1.username, 
	CASE l.RoleID WHEN 1 THEN 'Member' WHEN 2 THEN 'Agent' WHEN 3 THEN 'Master' WHEN 4 THEN 'Super' END Role,
	l.isAllowed,
	l.CreatedDate,	
	c2.username CreatedBy,
	l.LastModifiedTime,
	c3.username LastModifiedBy,
	isnull(l.Remark,'') Remark
	FROM custinfo c1 (nolock) inner join Acc_CustAllowList l (nolock) on l.CustID = c1.custid
		inner join custInfo c2 (nolock) ON l.Creator = c2.custid  
		left join custInfo c3 (nolock) ON l.LastModifiedBy = c3.custid	
END


