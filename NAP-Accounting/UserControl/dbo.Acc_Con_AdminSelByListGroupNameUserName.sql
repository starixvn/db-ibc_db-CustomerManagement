/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_Con_AdminSelByListGroupNameUserName
	@ListGroupName VARCHAR (1000), 
	@Username VARCHAR (30)='', 
	@CustID INT=0
AS

/*
	Created: HuyNguyen
	Task : Check exist UserName in a list of GroupNames
	DB: DBCUST/NAP_UserControl
	Original:Accounting site
	  
	Revisions:  
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		
	Params:
		@ListGroupName: list group name will be denied ex:'THB,CSD'
	Revisions:
*/
BEGIN
	SET NOCOUNT ON;
	IF (@CustID = 0)
		SELECT ac.custid
		FROM   CUSTDB.dbo.customer AS c WITH (NOLOCK)
			   INNER JOIN
			   acccustomer AS ac WITH (NOLOCK)
			   ON c.custid = ac.custid
			   INNER JOIN
			   acc_groupinfo AS gi WITH (NOLOCK)
			   ON ac.groupid = gi.groupid
		WHERE  gi.GroupName IN (SELECT val
								FROM   dbo.strSplit (@ListGroupName, ','))
			   AND c.username = @Username;
	ELSE
		SELECT ac.custid
		FROM   CUSTDB.dbo.customer AS c WITH (NOLOCK)
			   INNER JOIN
			   acccustomer AS ac WITH (NOLOCK)
			   ON c.custid = ac.custid
			   INNER JOIN
			   acc_groupinfo AS gi WITH (NOLOCK)
			   ON ac.groupid = gi.groupid
		WHERE  gi.GroupName IN (SELECT val
								FROM   dbo.strSplit (@ListGroupName, ','))
			   AND c.custid = @CustID;
END
GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_AdminSelByListGroupNameUserName] TO [vnteam];


GO
GRANT EXECUTE
    ON [dbo].[Acc_Con_AdminSelByListGroupNameUserName] TO [bodbAdminNet];

