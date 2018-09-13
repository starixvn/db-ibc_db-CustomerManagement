/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermSelCheckerList]
/*
	Created by: N/A
	Task: 
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/			
AS
BEGIN
	SET NOCOUNT ON
	SELECT c.username , c.custid 
	FROM NAP_UserControl.dbo.accCustomer ac with (nolock)
		INNER JOIN dbo.Customer c with (nolock) ON ac.custid = c.custid 
	WHERE groupid = 111 -- From Settlemement group
	    
END
GO
GRANT EXECUTE ON [dbo].[Acc_CreditTermSelCheckerList] TO [bodbAdminNet]
GO