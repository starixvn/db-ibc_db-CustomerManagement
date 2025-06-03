/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_BankAccountAgent_List
	@CustID				INT,			-- SMA_ID Input
	@BankID				INT = 0,
	@BankAccountStatus		BIT = NULL,
	@TransTypeList			VARCHAR(10) = NULL,
	@SearchAccount			NVARCHAR(255) = NULL
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - BankAccount List [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]   

	Param:
		exec Age_CashService_BankAccountAgent_List @CustID =  1176086
*/  
BEGIN
	SET NOCOUNT ON;
	     
	SELECT
		aba.AgentBankAccountID,
		aba.AccountNickname,
		ab.BankName,
		ab.BankID,
		ab.BankCode,
		aba.AccountHolderName,
		aba.BankAccountNumber,
		aba.TransTypeList,
		aba.BankAccountStatus,
		aba.RepUpdateTime AS LastUpdated
	FROM CashAgentBankAccount aba WITH (NOLOCK)
	INNER JOIN CashBankList ab WITH (NOLOCK) ON aba.BankID = ab.BankID
	WHERE aba.AgentID = @CustID
	AND aba.IsActive = 1											-- Get Bank Account Is Active
	AND (@BankID		= 0 OR aba.BankID = @BankID)
	AND (@TransTypeList IS NULL OR aba.TransTypeList LIKE '%' + @TransTypeList + '%')
	AND (@BankAccountStatus IS NULL OR aba.BankAccountStatus = @BankAccountStatus)
	AND (@SearchAccount IS NULL 
			OR aba.AccountNickname LIKE '%' + @SearchAccount + '%'
			OR aba.AccountHolderName LIKE '%' + @SearchAccount + '%'
			OR aba.BankAccountNumber LIKE '%' + @SearchAccount + '%')
	
END
