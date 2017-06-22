ALTER PROCEDURE dbo.Acc_Con_AdminSelByListGroupNameUserName
	@ListGroupName VARCHAR (1000), 
	@Username VARCHAR (30)='', 
	@CustID INT=0
AS
SET /*
Created: HuyNguyen
Task : Check exist UserName in a list of GroupNames
DB: DB03.bodb02
Original:Accounting site
Params:
	@ListGroupName: list group name will be denied ex:'THB,CSD'
Revisions:
*/
NOCOUNT ON;
IF (@CustID = 0)
    SELECT ac.custid
    FROM   customer AS c WITH (NOLOCK)
           INNER JOIN
           acccustomer_1 AS ac WITH (NOLOCK)
           ON c.custid = ac.custid
           INNER JOIN
           acc_groupinfo_1 AS gi WITH (NOLOCK)
           ON ac.groupid = gi.groupid
    WHERE  gi.GroupName IN (SELECT val
                            FROM   dbo.strSplit (@ListGroupName, ','))
           AND c.username = @Username;
ELSE
    SELECT ac.custid
    FROM   customer AS c WITH (NOLOCK)
           INNER JOIN
           acccustomer_1 AS ac WITH (NOLOCK)
           ON c.custid = ac.custid
           INNER JOIN
           acc_groupinfo_1 AS gi WITH (NOLOCK)
           ON ac.groupid = gi.groupid
    WHERE  gi.GroupName IN (SELECT val
                            FROM   dbo.strSplit (@ListGroupName, ','))
           AND c.custid = @CustID;


GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_AdminSelByListGroupNameUserName] TO [vnteam];


GO
GRANT EXECUTE
    ON [dbo].[Acc_Con_AdminSelByListGroupNameUserName] TO [bodbAdminNet];

