ALTER PROCEDURE [dbo].[Acc_OperatorSelByID] 
	@CustID INT
AS
/*
Created:
Task : 
DB: DBCUST.CustDB
Original: 

Revisions:
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/
--Original: EditOperator.asp
SET NOCOUNT ON

SELECT
	CustID, 
	UserName, 
	FirstName, 
	LastName, 
	Address, 
	City, 
	State, 
	Country, 
	Postal, 
	Email, 
	Phone, 
	MobilePhone, 
	Fax, 
	RoleID 
FROM Customer WITH (NOLOCK) 
WHERE CustID = @CustID


GO
GRANT EXECUTE ON [dbo].[Acc_OperatorSelByID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_OperatorSelByID] TO [vnteam] AS [dbo]