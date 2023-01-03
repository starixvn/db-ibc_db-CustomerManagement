/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_AutoSuspendThreshold_Sel]
	  @SportType		INT = 43
AS
/*    
	Created: 20200305@Eden    
	Task :  Select Global AutoSuspendThreshold
	DB: CustDB/DBCUST
	    
	Revisions:    
		- 20200305@Eden : First commit [Redmind: #128749]
		- 20221214@Johnson: sort by LeagueGroupOrder for Esports [redmine:#177594]
  
*/ 
BEGIN
	
	SELECT h.SportType 
		,lg.GroupID LeagueGroupID
		,lg.GroupName LeagueGroup
		,bg.GroupID BettypeGroupID
		,bg.GroupName BettypeGroup
		,h.BetType BetTypeID
		,h.LevelID 
		,h.VRAutoSuspendThresholdLive
		,h.VRAutoSuspendThresholdNonLive
	FROM VRSettingHierarchy h WITH(NOLOCK)
		LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
		LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
	WHERE h.SportType = @SportType
	ORDER BY lg.LeagueGroupOrder,h.SortOrder
END