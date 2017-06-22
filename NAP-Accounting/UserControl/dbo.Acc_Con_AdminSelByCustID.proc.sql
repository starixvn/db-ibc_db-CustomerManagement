ALTER PROCEDURE [dbo].[Acc_Con_AdminSelByCustID]
	@CustID INT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get info of account by ID in User Control 
	DB: DB03.BODB02
 
	Revisions:
		- 20110526@Tom: Remove condition @System
*/
SELECT c.custid,
       c.username,
       c.firstname,
       c.lastname,
       ac.groupid,
       c.roleid,
       ci.closed,
       c.userpwd
FROM   AccCustomer_1 AS ac WITH (NOLOCK)
       INNER JOIN
       Customer AS c WITH (NOLOCK)
       ON c.custid = ac.custid
       INNER JOIN
       Custinfo AS ci WITH (NOLOCK)
       ON c.custid = ci.custid
WHERE  ac.custid = @custid;


GO
GRANT VIEW DEFINITION
   ON [dbo].[Acc_Con_AdminSelByCustID] TO [vnteam];


GO
GRANT EXECUTE
   ON [dbo].Acc_Con_AdminselbyCustID TO [bodbadminnet];

