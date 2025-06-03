/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_CountryCodeSel
	@Site			NVARCHAR(50)
AS 
/* 
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get Member Site Management [Redmine #223896] 
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		exec Age_CashService_CountryCodeSel	@Site =  '222227' 

*/  
BEGIN
	SET NOCOUNT ON;
	
	SELECT csc.CountryCode
	FROM GlobCustDB.dbo.Site s WITH (NOLOCK)
	INNER JOIN CashSiteConfig csc WITH (NOLOCK) ON s.siteid = csc.SiteId
	WHERE s.Site = @Site

END

