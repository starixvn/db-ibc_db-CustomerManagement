/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_ProviderBankList
	@Site		VARCHAR(50)
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get Bank List Offer by Provider [Redmine #223896] 
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250822@Helios: Agency Cash Service -Customer Setting Sprint 9 [redmine: #236430]

	Param:
		exec Age_CashService_ProviderBankList_UAT2 @Site ='222227' 

	@ModeView:  0 : Provider  || 1 : Bank
		 
*/  
BEGIN
	SET NOCOUNT ON;
	

	DECLARE @SiteID INT = 0

	SELECT @SiteID = (SELECT s.siteid FROM GlobCustDB.dbo.Site s WITH (NOLOCK) WHERE s.site = @Site)

	-- Get bank list from CashProviderBankConfig
	SELECT	cp.ProviderID,
			cb.BankID,
			cb.BankCode,
			cb.BankName AS Bank
			-- cb.TransTypeList,
			-- cb.DepositMode
	FROM CashProviderConfig cp WITH (NOLOCK) 
	INNER JOIN CashProviderBankConfig cpbc WITH (NOLOCK) ON cp.ProviderID = cpbc.ProviderID
	INNER JOIN CashBankList cb WITH (NOLOCK) ON cpbc.BankID = cb.BankID
	WHERE cp.SiteID = @SiteID
	AND cpbc.IsActive = 1;


END
