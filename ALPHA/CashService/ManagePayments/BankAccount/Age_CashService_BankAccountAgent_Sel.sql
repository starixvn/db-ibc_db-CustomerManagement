/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_BankAccountAgent_Sel
	@AgentBankAccountID	INT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - BankAccount Sel [Redmine #223896] 
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]   

	Param:
		exec Age_CashService_BankAccountAgent_Sel_UAT2 @AgentBankAccountID = 44
*/  
BEGIN
	SET NOCOUNT ON;
	     
	SELECT
		aba.AgentBankAccountID,
		aba.BankID,
		aba.AccountNickname,
		aba.BankAccountStatus,
		vc.username AS CreatedBy,
		aba.RepUpdateTime AS LastUpdated,
		ab.BankName,
		ab.TransTypeList AS Bank_TransTypeList,
		ab.DepositMode AS Bank_DepositMatchingMode,
		aba.TransTypeList AS Agent_TransTypeList,
		aba.DepositMatching AS Agent_DepositMatchingMode,
		aba.AccountHolderName,
		aba.BankAccountNumber,
		aba.AccountNickname,
		aba.PromptPayEnabled,
		aba.PromptPayMobile
	FROM CashAgentBankAccount aba WITH (NOLOCK)
	INNER JOIN CashBankList ab WITH (NOLOCK) ON aba.BankID = ab.BankID
	INNER JOIN CustDB.dbo.vw_CashService_Customer vc WITH (NOLOCK) ON aba.AgentID = vc.custid
	WHERE aba.AgentBankAccountID = @AgentBankAccountID
	AND aba.IsActive = 1											-- Get Bank Account Is Active
	
END