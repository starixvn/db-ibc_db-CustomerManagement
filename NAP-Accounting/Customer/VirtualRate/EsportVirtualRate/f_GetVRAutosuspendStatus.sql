/*<info serverAlias="DBCust-CustDB,DBCTS-bodb02" selecters="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_GetVRAutosuspendStatus] (
	@custid INT,	
	@SportType INT,
	@BetType INT,
	@LeagueGroupID INT,
	@IsLive BIT
)	       
RETURNS TABLE
AS
/*
	Created by: 20191216@Eden
	Task: Get Autosuspend status for Customer VR system
	DB: DBCust/CustDB,DBCTS/bodb02
	Original: 
	
	Revisions:
		- 20191216@Eden: Initial SP [Redmine: #121876]

	Explanation's Param:
		
*/ 
RETURN
	WITH Tmp_VRSettingHierarchy AS (
	SELECT h.LevelID
		,h.ParentLevelID
	FROM VRSettingHierarchy h WITH(NOLOCK)
		INNER JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID 
		INNER JOIN VRLeagueGroupMapping lm WITH(NOLOCK) ON lg.GroupID = lm.VRLeagueGroupID 
	WHERE h.SportType = @SportType AND h.BetType = @BetType AND lm.LeagueGroupID = @LeagueGroupID
	UNION ALL
	SELECT c.LevelID, c.ParentLevelID
	FROM VRSettingHierarchy c WITH (NOLOCK)
		INNER JOIN Tmp_VRSettingHierarchy p on p.ParentLevelID = c.LevelID 
	) 
	, Tmp_VRSettingHierarchy1 AS (
		SELECT LevelID,ParentLevelID
		FROM Tmp_VRSettingHierarchy
		UNION SELECT 1,0
	)
	,tempVR AS(
	SELECT h.BetType
		,h.LevelID
		,vlive.Value ValueLIVE
		,vnonlive.Value ValueNonLIVE
		,live.value  AS IsLiveAutoSuspend
		,nonlive.value  AS IsNonLiveAutoSuspend
		,h.ParentLevelID
		,h.VRAutoSuspendThreshold
	FROM Tmp_VRSettingHierarchy1 tmp
	INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
	LEFT JOIN VRCustSetting vr WITH(NOLOCK) 
		ON vr.CustID = @CustID
			AND vr.LevelID = h.LevelID
	LEFT JOIN VRValueMapping vlive WITH(NOLOCK) ON vr.ValueIDLIVE = vlive.ValueID
	LEFT JOIN VRValueMapping vnonlive WITH(NOLOCK) ON vr.ValueIDNonLIVE = vnonlive.ValueID
	OUTER APPLY (	SELECT AutoSuspendLive, AutoSuspendNonLive
					FROM dbo.CustSettingAutoSuspend WITH(NOLOCK)
					WHERE custid = @CustID
				)t
	CROSS APPLY dbo.f_CustSetting_ProductStatusSel (ISNULL(t.AutoSuspendLive,0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF),h.BitmapOrderAutoSuspend) Live
	CROSS APPLY dbo.f_CustSetting_ProductStatusSel (ISNULL(t.AutoSuspendNonLive,0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF),h.BitmapOrderAutoSuspend) NonLive
	)
	SELECT CASE WHEN @IsLive = 1 THEN (CASE  WHEN COALESCE(h.ValueLIVE,pr1.ValueLIVE,pr2.ValueLIVE,pr3.ValueLIVE) >= pr3.VRAutoSuspendThreshold AND ISNULL(h.IsLiveAutoSuspend,1) = 1 THEN 1 ELSE 0 END)
								 ELSE (CASE WHEN COALESCE(h.ValueNonLIVE,pr1.ValueNonLIVE,pr2.ValueNonLIVE,pr3.ValueNonLIVE) >= pr3.VRAutoSuspendThreshold AND ISNULL(h.IsNonLiveAutoSuspend,1) = 1 THEN 1 ELSE 0 END) 
				END IsVRAutoSuspend
	FROM tempVR pr3
		LEFT JOIN tempVR pr2
			ON pr2.ParentLevelID = pr3.LevelID 
		LEFT JOIN tempVR pr1 
			ON pr1.ParentLevelID = pr2.LevelID 
		LEFT JOIN tempVR h 
			ON h.ParentLevelID = pr1.LevelID 
	WHERE pr3.LevelID = 1
GO