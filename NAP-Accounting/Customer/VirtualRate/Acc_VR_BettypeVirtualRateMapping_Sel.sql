/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_BettypeVirtualRateMapping_Sel]
	  @SportType INT = 2
AS
/*    
	Created: 20200616@Eden    
	Task :  Select Bettype VirrtualRate mapping
	DB: CustDB/DBCUST
	    
	Revisions:    
		- 20200616@Eden : First commit [Redmind: #134978]

	Example:
		Exec [Acc_VR_BettypeVirtualRateMapping_Sel] 2
  
*/ 
BEGIN
	IF @SportType = 2
	BEGIN
		SELECT 'USA 1 league group' AS LeagueGroup, h.BetType, CONVERT(VARCHAR(10),h.BetType) AS VRSetting ,Level = 'Bet Type', 1 AS LeagueGroupOrder
		FROM VRSettingHierarchy h WITH(NOLOCK)
			INNER JOIN VRLeagueGroup lg WITH(NOLOCK) ON lg.GroupID = h.VRLeagueGroupID AND lg.GroupName = 'USA 1'
		WHERE h.SportType = @SportType
			AND bettype <> -1
		UNION ALL
		SELECT 'USA 1 league group', ref.BetType, CONVERT(VARCHAR(10),h.BetType) AS VRSetting ,Level = 'Bet Type', 1 AS LeagueGroupOrder
		FROM VRSettingReference ref WITH(NOLOCK)
			INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON ref.RefLevelID = h.LevelID
			INNER JOIN VRLeagueGroup lg WITH(NOLOCK) ON lg.GroupID = h.VRLeagueGroupID AND lg.GroupName = 'USA 1'
		WHERE ref.SportType = @SportType 
		UNION ALL
		SELECT 'Other League groups', ref.BetType, bg.GroupName, Level = 'Bet Type Group', 2 AS LeagueGroupOrder
		FROM VRSettingReference ref WITH(NOLOCK)
			INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON ref.RefLevelID = h.LevelID
			INNER JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
			INNER JOIN VRLeagueGroup lg WITH(NOLOCK) ON lg.GroupID = h.VRLeagueGroupID AND lg.GroupName = '3X3 1'
		WHERE ref.SportType = @SportType 
		UNION ALL
		SELECT 'Other League groups', ref.BetType, 'Follow the same league groups''s VR setting', Level = 'League Group', 2 AS LeagueGroupOrder
		FROM VRSettingReference ref WITH(NOLOCK)
			INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON ref.RefLevelID = h.LevelID AND h.VRBetTypeGroupID = -1
			INNER JOIN VRLeagueGroup lg WITH(NOLOCK) ON lg.GroupID = h.VRLeagueGroupID AND lg.GroupName = '3X3 1'
		WHERE ref.SportType = @SportType 
		ORDER BY LeagueGroupOrder,Bettype
	END
END
GO