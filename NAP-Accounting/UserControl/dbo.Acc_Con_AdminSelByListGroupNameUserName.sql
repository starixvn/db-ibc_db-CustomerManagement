/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
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
		- 20220613@Elodie: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
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
		WHERE  gi.GroupName IN (SELECT value
								FROM   string_split (@ListGroupName, ',')
								WHERE value <> '')
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
		WHERE  gi.GroupName IN (SELECT value
								FROM   string_split (@ListGroupName, ',')
								WHERE value <> '')
			   AND c.custid = @CustID;
END
GO


