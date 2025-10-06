/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_GetOfferedProductByCust_Extra]
	@custid INT
	, @CashServiceSites VARCHAR(MAX)
	, @SettingStatus TINYINT = 0
AS
/*
	Created: 20250527@Virgil
	DB: DBAGE-bodb02
	Task: Get all dummy products which offered for customer

	Revisions:
		- 20250527@Virgil: Agency Cash Service - Billing service and Report changes [Redmine: #227984]
		- 20250718@Virgil: Cash Service Billing - Sprint 6 - Enhance code [RedmineId: #231700]

	Param's Explanation:
		- @SettingStatus: 0: Pro, 1: UAT
		- @CashServiceSites: list Sites offer Cash Service

	Example: EXEC Age_GetOfferedProductByCust_Extra @CustID = 1176086
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @Currency INT, @Site VARCHAR(50);

	--Get: site/currency
	SELECT @Currency = c.currency, @Site = c.site
	FROM Customer c WITH (NOLOCK)
	WHERE custid = @custid

	SELECT t.ProductID,
			CASE
				WHEN ',' + @CashServiceSites + ',' LIKE '%,' + @Site + ',%' THEN 0
				WHEN @CashServiceSites = '*' THEN 0
				ELSE 1 
			END isHidden,
			t.EndOfSupportDate
	FROM dbo.Products t (NOLOCK)
	WHERE ProductID IN (111)
	ORDER BY ProductID

END
GO