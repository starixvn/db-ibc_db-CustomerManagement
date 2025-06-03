/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_BankList
	@Site		VARCHAR(50)
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get All Bank List [Redmine #223896] 
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]   

	Param:
		exec Age_CashService_BankList_UAT2 @Site ='222227' 

	@ModeView:  0 : Provider  || 1 : Bank
		 
*/  
BEGIN
	SET NOCOUNT ON;
	

	DECLARE @SiteID INT = 0

	SELECT @SiteID = (SELECT s.siteid FROM GlobCustDB.dbo.Site s WITH (NOLOCK) WHERE s.site = @Site)

	SELECT cb.BankID , Bankcode, cb.BankName AS Bank , cb.TransTypeList , cb.DepositMode
	FROM CashBankConfig cbc WITH (NOLOCK)
	INNER JOIN CashBankList cb WITH (NOLOCK) ON cbc.BankId = cb.BankID
	WHERE cbc.SiteId = @SiteID


END
