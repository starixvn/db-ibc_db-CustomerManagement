ALTER PROCEDURE [dbo].[Age_CustomerSelEditSuspend_Ag]
	@CustID INT 	--MemberID
AS

/*
Created: 
Task : 
DB: DBCUST.CustDB
Original: 
Revisions:
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/

SET NOCOUNT ON

SELECT ISNULL(reject, 0) UplineSuspended 
FROM CustInfo WITH (NOLOCK)
WHERE custid = (SELECT recommend FROM Custinfo WITH (NOLOCK) WHERE custid = @CustID )




GO
GRANT EXECUTE ON [Age_CustomerSelEditSuspend_Ag] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [Age_CustomerSelEditSuspend_Ag] TO [bodbDownlineNetView]
