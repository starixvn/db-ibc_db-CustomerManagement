/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermSelCheckerList]
/*
	Created by: N/A
	Task: 
	DB: DBCUST/NAP_UserControl
	
	Revisions:
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/			
AS
BEGIN
	SET NOCOUNT ON
	SELECT c.username , c.custid 
	FROM dbo.accCustomer ac with (nolock)
		INNER JOIN dbo.Customer c with (nolock) ON ac.custid = c.custid 
	WHERE groupid = 111 -- From Settlemement group
	    
END
GO
GRANT EXECUTE ON [dbo].[Acc_CreditTermSelCheckerList] TO [bodbAdminNet]
