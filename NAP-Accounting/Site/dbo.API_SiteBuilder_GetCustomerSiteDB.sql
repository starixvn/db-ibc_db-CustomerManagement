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
		- 20250610@Tacy: Setup KL [Redmine: #223922]

	Example:	EXEC API_SiteBuilder_GetCustomerSiteDB @SiteDBGroupId = 1
*/
BEGIN
	SET NOCOUNT ON  	
	
	IF EXISTS (SELECT 1 FROM Site WITH (NOLOCK) WHERE SiteDBGroupID = CustDBGroupID AND SiteDBGroupID = @SiteDBGroupId)
		SELECT	cc.CustDBGroupID, 
			cc.LinkedServerName AS LinkedServerNameDBCUST, 
			cc.ClientAccessName AS ClientAccessNameDBCUST, 
			CASE cc.CustDBGroupID 
				WHEN 0 THEN '10.146.11.150' 
				WHEN 1 THEN '10.146.11.160' 
				WHEN 2 THEN '10.146.11.161' 
				WHEN 3 THEN '10.146.11.162' 
			END AS AGIP_DBCUST,
			cc.FQDN AS FQDN_DBCUST,
			sc.SiteDBGroupID, 
			sc.LinkedServerName, 
			sc.ClientAccessName, 
			CASE sc.SiteDBGroupID 
				WHEN 0 THEN '10.146.11.130' 
				WHEN 1 THEN '10.146.11.160' 
				WHEN 2 THEN '10.146.11.161' 
				WHEN 3 THEN '10.146.11.162' 
			END AS AGIP,
			sc.FQDN
		FROM CustDBSiteConfig cc WITH (NOLOCK) 
			INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON cc.CustDBGroupID = sc.SiteDBGroupID
		WHERE CustDBGroupID = @SiteDBGroupId
	ELSE 
		SELECT	cc.CustDBGroupID, 
			cc.LinkedServerName AS LinkedServerNameDBCUST, 
			cc.ClientAccessName AS ClientAccessNameDBCUST, 
			CASE cc.CustDBGroupID 
				WHEN 0 THEN '10.146.11.150' 
				WHEN 1 THEN '10.146.11.160' 
				WHEN 2 THEN '10.146.11.161' 
				WHEN 3 THEN '10.146.11.162' 
			END AS AGIP_DBCUST,
			cc.FQDN AS FQDN_DBCUST,
			sc.SiteDBGroupID, 
			sc.LinkedServerName, 
			sc.ClientAccessName, 
			CASE sc.SiteDBGroupID 
				WHEN 0 THEN '10.146.11.130' 
				WHEN 1 THEN '10.146.11.160' 
				WHEN 2 THEN '10.146.11.161' 
				WHEN 3 THEN '10.146.11.162' 
			END AS AGIP,
			sc.FQDN
		FROM CustDBSiteConfig cc WITH (NOLOCK) 
			CROSS JOIN SiteDBConfig sc WITH (NOLOCK)
		WHERE CustDBGroupID = 0 AND SiteDBGroupID = @SiteDBGroupId
		
END
GO