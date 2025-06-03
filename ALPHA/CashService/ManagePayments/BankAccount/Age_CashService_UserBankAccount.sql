/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_UserBankAccount
	@CustID		INT			-- SMA_ID Input
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - Dropdownlist Bank [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896] 

	Param:
		exec Age_CashService_UserBankAccount @CustID =  1176086


*/  
BEGIN
	SET NOCOUNT ON;
	     
	SELECT DISTINCT ab.BankID , ab.BankCode , ab.BankName
	FROM CashAgentBankAccount aba WITH (NOLOCK)
	INNER JOIN CashBankList ab WITH (NOLOCK) ON aba.BankID = ab.BankID
	WHERE aba.AgentID = @CustID
	AND aba.IsActive = 1											-- Get Bank Account Is Active
END

GO