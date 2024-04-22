/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_CriteriaMatrix_Sel] 
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - get Criteria Maxtrix (Sport, Bettype, Leagroup, league) apply VR1 or VR2
	DB: DBACC-bodb02
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20220228@Eden: All sites - Integrate new Customer Class for PA Probation [Redmine:#170666]
	- 20240319@Luke: [NAP CM] VR Engine - Add in new criteria: Apply follow the VR accumulated balance, Currency [Redmine: #201333]

	Parameter explanation:

	Example: 
	EXEC NAP_VREngine_CriteriaMatrix_Sel 

	*/
BEGIN
	CREATE TABLE #SportBettypeVR(sporttype smallint, bettype smallint PRIMARY KEY (Sporttype,bettype))
	CREATE TABLE #SportVR(sporttype smallint PRIMARY KEY)
	CREATE TABLE #LeagueGroup(LeagueGroupID smallint PRIMARY KEY, GroupName VARCHAR(200))
	--CREATE TABLE #League(leagueid INT PRIMARY KEY, leaguename NVARCHAR(500), LeagueGroupID SMALLINT, Sporttype SMALLINT)

	INSERT INTO #SportBettypeVR(sporttype,bettype)
	SELECT Sporttype,bettype
	FROM OPENQUERY (DBTXN, 'SELECT DISTINCT r.Sporttype,r.bettype FROM bodb02.dbo.Sport_Bettype_Reference_VirtualRate r WITH(NOLOCK)')
	UNION 
	SELECT r.Sporttype,r.bettype
	FROM dbo.VRSettingHierarchy r WITH(NOLOCK)
	WHERE BetType <> -1
	UNION 
	SELECT r.Sporttype,r.bettype
	FROM dbo.ProfileVirtualSetting r WITH(NOLOCK)
	UNION 
	SELECT r.Sporttype,r.bettype
	FROM dbo.VRSettingReference r WITH(NOLOCK)

	INSERT INTO #SportVR(sporttype)
	SELECT DISTINCT sporttype FROM #SportBettypeVR

	INSERT INTO #LeagueGroup(LeagueGroupID,GroupName)
	SELECT r.GroupID,r.GroupName
	FROM dbo.LeagueGroup r WITH(NOLOCK)
		INNER JOIN #SportVR s ON s.sporttype = r.SportType
	WHERE r.IsActive = 1
	UNION ALL
	SELECT GroupID,GroupName
	FROM dbo.LeagueGroup r WITH(NOLOCK)
	WHERE SportType = 0
		AND r.IsActive = 1

	SELECT SiteID,Site, CASE WHEN isLicensee = 1 THEN 2 ELSE 1 END SiteType
	FROM dbo.[Site] WITH(NOLOCK)
	WHERE isActive = 1
	ORDER BY Site

	SELECT CustomerClass,Name FROM dbo.f_NAP_VREngine_GetCustomerClass() ORDER BY 1
	SELECT BetFrom,Name FROM dbo.f_NAP_VREngine_GetBetFrom() ORDER BY 2

	SELECT * FROM #SportVR
	SELECT DISTINCT bettype FROM #SportBettypeVR
	SELECT * FROM #LeagueGroup

	SELECT ExchangeId AS CurrencyID, currency AS CurrencyName
	FROM Exchange WITH (NOLOCK)
	WHERE IsActive = 1
	ORDER BY ExchangeId

	DROP TABLE #SportBettypeVR
	DROP TABLE #LeagueGroup
	DROP TABLE #SportVR
END
GO

