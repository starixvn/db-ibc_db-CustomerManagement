/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_AdminSelByCustID]
	@CustID INT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get info of account by ID in User Control 
	DB: DBCUST/NAP_UserControl
 
	Revisions:
		- 20110526@Tom: Remove condition @System
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/
BEGIN
	SELECT c.custid,
		   c.username,
		   c.firstname,
		   c.lastname,
		   ac.groupid,
		   c.roleid,
		   ci.closed,
		   c.userpwd
	FROM   AccCustomer AS ac WITH (NOLOCK)
		   INNER JOIN CUSTDB.dbo.Customer AS c WITH (NOLOCK)
		   ON c.custid = ac.custid
		   INNER JOIN CUSTDB.dbo.Custinfo AS ci WITH (NOLOCK)
		   ON c.custid = ci.custid
	WHERE  ac.custid = @custid
END	
GO
GRANT VIEW DEFINITION
   ON [dbo].[Acc_Con_AdminSelByCustID] TO [vnteam];
GO
GRANT EXECUTE
   ON [dbo].Acc_Con_AdminselbyCustID TO [bodbadminnet];

