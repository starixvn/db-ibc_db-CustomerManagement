/*<info serverAlias="DBACC-bodb02" executers="wsv_nap,wsv_lap,asv_cust" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_Dep_ServerDBConfigSel_KL
AS
/*
	Created by: Elodie
	Date: 20240716
	Task : Get CustDBSiteConfig info
	DB: DBACC/bodb02
	Revisions:
		- 20240716@Elodie: Initial SP 
		- 20250610@Tacy: Setup KL [Redmine: #223922]

	Example:	EXEC Acc_Dep_ServerDBConfigSel
*/
BEGIN
	SET NOCOUNT ON  	
	
	SELECT	c.custid, ds.site,
			cc.CustDBGroupID, 
			cc.LinkedServerName AS LinkedServerNameDBCUST, 
			cc.ClientAccessName AS ClientAccessNameDBCUST, 
			'dbcust.dp.gamora.prod,7105' AS AGIP_DBCUST,
			cc.FQDN AS FQDN_DBCUST,
			sc.SiteDBGroupID, 
			sc.LinkedServerName, 
			sc.ClientAccessName, 
			'dbtrans.dp.gamora.prod,7104' AS AGIP,
			sc.FQDN
	FROM custinfo c WITH (NOLOCK)
		INNER JOIN Dep_CustSuper ds WITH (NOLOCK) ON c.srecommend = ds.custid
		INNER JOIN Site s WITH (NOLOCK) ON ds.site = s.site
		INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON s.CustDBGroupID = cc.CustDBGroupID
		INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON s.SiteDBGroupID = sc.SiteDBGroupID 
	WHERE c.roleid = 2 
		AND s.isDeposit = 1
		AND s.isActive = 1
		AND NOT EXISTS ( SELECT 1
						FROM customer ci (NOLOCK)
						WHERE c.mrecommend = ci.custid 
							AND (ci.username LIKE '%Acc%' OR ci.username LIKE '%LocalBank%' OR ci.username LIKE '%AFF%' OR ci.username LIKE 'AB88'+'CAS%')
							AND ci.roleid = 3)
END
GO