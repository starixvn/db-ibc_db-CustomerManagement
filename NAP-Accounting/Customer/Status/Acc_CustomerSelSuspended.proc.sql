ALTER PROCEDURE [dbo].[Acc_CustomerSelSuspended]
	@CustID INT
AS

/*
Created: 
Task : Get status suspended by custid
DB: DBCUST.CustDB
Original:Accounting site

Revisions:
	- 20090527@Pluto: Get customer suspended status
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
Param's Explanation:
	@CustID: id of customer
*/

SET NOCOUNT ON

SELECT ISNULL(reject, 0) AS Suspended
FROM custinfo WITH (NOLOCK)
WHERE CustID = @CustID

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSuspended] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSuspended] TO [vnteam]

