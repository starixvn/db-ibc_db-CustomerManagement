/*<info serverAlias="DBCUST-CUSTDB" executers="bodbLicenseeNet" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_CurrencyList]
AS
/*
	Created: Dom
	Date: 2014-08-29
	Task: Currency List
	DB: DBCUST-CUSTDB
		
	Revisions:
		- 20240117@Tacy: Get active currency [Redmine: #199521]

	Example:
		EXEC NAP_SpecialCustSetting_CurrencyList 
*/
BEGIN
	SELECT exchangeid,currency FROM Exchange WITH(NOLOCK)
	WHERE IsActive=1 AND OfferSite IN (0,2)
END
GO