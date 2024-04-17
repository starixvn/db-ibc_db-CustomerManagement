ALTER PROCEDURE [dbo].[Acc_SelCustomerGivenCredit]
	@CustID INT
AS

/*
	Created: 20081024@QuiNV
	Task: Get given credit of a customer (belonging have been checked on web already). Returns: username, givencredit
	DB: DBCUST.CustDB
	Original:
	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/

SET NOCOUNT ON

SELECT 
	c.username AS username, 
	c.roleid AS roleid,
	credit AS givencredit
FROM Customer c WITH (NOLOCK) 
	INNER JOIN Custinfo ci WITH (NOLOCK) ON c.CustID = ci.CustID
WHERE c.CustID = @CustID



GO
GRANT EXECUTE ON [dbo].[Acc_SelCustomerGivenCredit] TO [bodbDownlineNet,wsv_alp]
GO

GO
GRANT EXECUTE ON [dbo].[Acc_SelCustomerGivenCredit] TO [wsv_nap]
GO

GRANT VIEW DEFINITION ON [dbo].[Acc_SelCustomerGivenCredit] TO [vnteam]

GO
