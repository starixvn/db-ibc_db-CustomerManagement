/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0"></info>*/
/****** Object:  StoredProcedure [dbo].[Acc_CustomerSelPlayerID]    Script Date: 11/26/2018 00:00:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelPlayerID]
	@UserId			INT,
	@SiteType		TINYINT = 0,
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
		-20180924@Phillip: Init
	
	
	Param's Explanation:
	- @UserId: User ID
	- @SiteType:
		- 0 : Get all
		- 1 : Exclude deposit sites
		- 2 : Exclude credit sites
	- @ProductID: Product ID
	- @PlayerIDs: List 3rd Player IDs
	- @Usernames: List User Name
*/

BEGIN
	SET NOCOUNT ON
	SELECT siteid, site, SpecialGroup 
	INTO #DeniedSites
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser(@UserId) 
	
	IF @SiteType <> 0
	BEGIN
		INSERT INTO  #DeniedSites (SiteId, Site, SpecialGroup)
		SELECT
			s.siteid,
			s.site,
			s.SpecialGroup
		FROM dbo.Site AS s WITH (NOLOCK)
		WHERE NOT EXISTS (SELECT 1 FROM #DeniedSites WHERE SiteId = s.siteid)
			AND s.isLicensee = CASE
				WHEN @SiteType = 1 THEN 1
				WHEN @SiteType = 2 THEN 0
			END
	END
	
	IF (ISNULL(@PlayerIDs, '') <> '')
	BEGIN
		SELECT DISTINCT LTRIM(RTRIM(val)) AS val INTO #PlayerIDs FROM dbo.f_StringSplit(@PlayerIDs,',') OPTION(MAXRECURSION 0)
		
		SELECT VendorID, PlayerID3rd, Custid
		INTO #Player3rd
		FROM dbo.CustUserMapping3rd WITH (NOLOCK)
		WHERE PlayerID3rd IN (SELECT val FROM #PlayerIDs)
			AND VendorID = @ProductID
		
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