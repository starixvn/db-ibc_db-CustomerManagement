ALTER PROCEDURE  [dbo].[Agw_SelCustomerGivenCredit]
@CustID int

AS

/*
Creator: QuiNV
Date: 10/24/2008
DB: DBCUST.custDB
Task: Get given credit of a customer (belonging have been checked on web already)

Revisions
	- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]

Returns: username, givencredit

*/

SET NOCOUNT ON
SELECT c.username as username, 
		c.roleid as roleid,
		credit as givencredit  
FROM Customer c with(nolock) INNER JOIN Custinfo ci with(nolock) ON c.CustID = ci.CustID
WHERE c.CustID = @CustID

GO
GRANT EXECUTE ON [dbo].[Agw_SelCustomerGivenCredit] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_SelCustomerGivenCredit] TO [vnteam] AS [dbo]