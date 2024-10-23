/*<info serverAlias="DBGLOB-GlobCustDB" executers="asv_cust" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE API_SiteBuilder_GetCustomerSiteDB
	@SiteDBGroupId SMAlLINT
AS
/*
	Created by: Elodie
	Date: 20240716
	Task : Get CustDBSiteConfig info
	DB: DBCUST/CustDB
	Revisions:
		- 20240716@Elodie: Initial SP 

	Example:	EXEC API_SiteBuilder_GetCustomerSiteDB @SiteDBGroupId = 1
*/
BEGIN
	SET NOCOUNT ON  	
	
	IF EXISTS (SELECT 1 FROM Site WITH (NOLOCK) WHERE SiteDBGroupID = CustDBGroupID AND SiteDBGroupID = @SiteDBGroupId)
		SELECT	cc.CustDBGroupID, 
			cc.LinkedServerName AS LinkedServerNameDBCUST, 
			cc.ClientAccessName AS ClientAccessNameDBCUST, 
			cc.AGIP AS AGIP_DBCUST,
			cc.FQDN AS FQDN_DBCUST,
			sc.SiteDBGroupID, 
			sc.LinkedServerName, 
			sc.ClientAccessName, 
			sc.AGIP,
			sc.FQDN
		FROM CustDBSiteConfig cc WITH (NOLOCK) 
			INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON cc.CustDBGroupID = sc.SiteDBGroupID
		WHERE CustDBGroupID = @SiteDBGroupId
	ELSE 
		SELECT	cc.CustDBGroupID, 
			cc.LinkedServerName AS LinkedServerNameDBCUST, 
			cc.ClientAccessName AS ClientAccessNameDBCUST, 
			cc.AGIP AS AGIP_DBCUST,
			cc.FQDN AS FQDN_DBCUST,
			sc.SiteDBGroupID, 
			sc.LinkedServerName, 
			sc.ClientAccessName, 
			sc.AGIP,
			sc.FQDN
		FROM CustDBSiteConfig cc WITH (NOLOCK) 
			CROSS JOIN SiteDBConfig sc WITH (NOLOCK)
		WHERE CustDBGroupID = 0 AND SiteDBGroupID = @SiteDBGroupId
		
END
GO