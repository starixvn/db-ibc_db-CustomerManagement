/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelPlayerID]
	@UserId			INT,
	@Permission		VARCHAR(20) = '',
	@ProductID		INT,
	@PlayerIDs		VARCHAR(MAX) = NULL,
	@Usernames		VARCHAR(MAX) = NULL
AS

/*
	Created by: 20181134@Phillip
	Task: #104848 - Poker Games - Support feature to allow search Player3rdID and identify who is this member is our system
	DB: DBCUST/CustDB
	Original:	
	
	Revisions:
		- 20180924@Phillip: Init
		- 20190605@Kan: Add new permission control to view CN88 Accounts [RedmineId:#114215]
	
	Param's Explanation:
	- @UserId: User ID
	- @Permission:
		- 1: Credit sites
		- 2: Deposit sites
		- 3: CN88
	- @ProductID: Product ID
	- @PlayerIDs: List 3rd Player IDs
	- @Usernames: List User Name
*/

BEGIN
	SET NOCOUNT ON
	SELECT siteid, site, SpecialGroup 
	INTO #DeniedSites
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser(@UserId) 
	
	IF @Permission <> ''
	BEGIN
		INSERT INTO #DeniedSites (SiteId, Site, SpecialGroup)
		SELECT
			s.siteid,
			s.site,
			s.SpecialGroup
		FROM dbo.Site AS s WITH (NOLOCK)
		WHERE NOT EXISTS (SELECT 1 FROM #DeniedSites WHERE SiteId = s.siteid)
			AND ((s.isLicensee = 0 -- Don't have Credit sites permission
				AND s.site <> 'cn88'
				AND ',' + @Permission + ',' NOT LIKE '%,1,%')
			OR (s.isLicensee = 1 -- Don't have Deposit sites permission
				AND s.site <> 'cn88'
				AND ',' + @Permission + ',' NOT LIKE '%,2,%')
			OR (s.site = 'cn88' -- Don't have CN88 site permission
				AND ',' + @Permission + ',' NOT LIKE '%,3,%'))
	END
	
	IF (ISNULL(@PlayerIDs, '') <> '')
	BEGIN
		SELECT DISTINCT LTRIM(RTRIM(val)) AS val INTO #PlayerIDs FROM dbo.f_StringSplit(@PlayerIDs,',') OPTION(MAXRECURSION 0)
		
		SELECT DISTINCT c.VendorID, c.PlayerID3rd, c.Custid
		INTO #Player3rd
		FROM dbo.CustUserMapping3rd c WITH (NOLOCK)
		JOIN (SELECT val FROM #PlayerIDs) p ON c.PlayerID3rd LIKE '%' + p.val+'%' AND c.VendorID = @ProductID
		
		SELECT	c.custid AS MemberId, 
				c.username AS MemberName, 
				c.recommend AS AgentId, 
				dbo.f_Get_CustNameByCustID(c.recommend) AS AgentName,
				c.mrecommend AS MasterId, 
				dbo.f_Get_CustNameByCustID(c.mrecommend) AS MasterName,
				c.srecommend AS SuperId, 
				dbo.f_Get_CustNameByCustID(c.srecommend) AS SuperName,
				c3rd.PlayerID3rd
		FROM dbo.Customer c WITH (NOLOCK) 
			INNER JOIN dbo.Customer uplinec WITH (NOLOCK) ON c.srecommend = uplinec.custid
			INNER JOIN #Player3rd c3rd WITH (NOLOCK) ON c.CustId = c3rd.CustId
		WHERE uplinec.site NOT IN (SELECT site FROM #DeniedSites)
		ORDER BY c.username
		
		DROP TABLE #PlayerIDs
		DROP TABLE #Player3rd
	END
	
	IF (ISNULL(@Usernames, '') <> '')
	BEGIN
		SELECT DISTINCT LTRIM(RTRIM(val)) AS val INTO #Usernames FROM dbo.f_StringSplit(@Usernames,',') OPTION(MAXRECURSION 0)
		
		SELECT	c.custid AS MemberId, 
				c.username AS MemberName, 
				c.recommend AS AgentId, 
				dbo.f_Get_CustNameByCustID(c.recommend) AS AgentName,
				c.mrecommend AS MasterId, 
				dbo.f_Get_CustNameByCustID(c.mrecommend) AS MasterName,
				c.srecommend AS SuperId, 
				dbo.f_Get_CustNameByCustID(c.srecommend) AS SuperName,
				c3rd.PlayerID3rd
		FROM dbo.custinfo c WITH (NOLOCK)
			INNER JOIN dbo.Customer uplinec WITH (NOLOCK) ON c.srecommend = uplinec.custid
			LEFT OUTER JOIN dbo.CustUserMapping3rd c3rd WITH (NOLOCK) ON c.CustId = c3rd.CustId AND c3rd.VendorID = @ProductID
		WHERE c.roleid = 1 
			AND c.username IN (SELECT val FROM #Usernames)
			AND uplinec.site NOT IN (SELECT site FROM #DeniedSites)
		ORDER BY c.username
		
		DROP TABLE #Usernames
	END
	
	DROP TABLE #DeniedSites
END