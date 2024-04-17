/*<info serverAlias="DBLIC-bodb_Licensee" executers="wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE NAP_SpecialCustSetting_LicenseeList
AS
/*
		Created: Dom
		Date: 2014-08-29
		Task: Licesee List
		DB: DBLIC/bodb_Licensee
		
		Revisions:
		- 20230224@Winfred: NAP LM - Enhance Bet Setting function for AM to use [redmine:#178105]
		- 20240117@Tacy: Get Active Licensee [Redmine: #199521]

*/ 
BEGIN
	SELECT [site].SiteName,[site].SiteID 
	FROM bodb02.dbo.[Site] ibcsite 
		LEFT JOIN bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1 AND ibcsite.isActive=1
	ORDER BY SiteName
END
GO
