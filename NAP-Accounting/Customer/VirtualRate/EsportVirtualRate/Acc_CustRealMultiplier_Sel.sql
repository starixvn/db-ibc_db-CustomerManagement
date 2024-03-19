/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CustRealMultiplier_Sel]
	@CustID INT
	, @SportType INT
	, @ErrCode TINYINT OUT
	, @ErrMsg NVARCHAR(200) OUT
AS
/*    
	Created: 20190722@Dominic    
	Task :  Support page to view real VR setting value  [Redmind: #117090]
	DB: DBCUST/CustDB    
	    
	Revisions:    
		- 20190722@Dominic : First commit
		- 20220422@Eden: SQL Server Upgrade to 2019 Phase 5 [Redmine: #171831]
		- 20221219@Johnson: sort by LeagueGroupOrder [Redmine:#177594]
  
*/ 
BEGIN
	DECLARE @UserName VARCHAR(100)
	DECLARE @ActualRate FLOAT, @Currency NVARCHAR(50)

	CREATE TABLE #VRLineCustID (CustID INT, RoleID TINYINT)
	CREATE TABLE #VRCustSetting (CustID INT, LevelID INT, ValueIDLive TINYINT, ValueIDNonLive TINYINT)
	CREATE TABLE #ResultData (LevelID INT, ValueIDLive TINYINT, ValueIDNonLive TINYINT
						, FollowingCustID INT,FollowingValueIDLive TINYINT,FollowingValueIDNonLive TINYINT
						, RowNo_Live INT, RowNo_NonLive INT
						, FollowingLevelID INT
					)

	SELECT @Username = username
			, @ActualRate = e.actualrate
			, @Currency = e.currency
	FROM Customer c(NOLOCK)
		INNER JOIN exchange e (NOLOCK) ON  e.exchangeid = c.currency
	WHERE CustID = @CustID 
		AND roleid IN (1,2,3,4)	

	IF @Username IS NULL
	BEGIN
		SELECT @ErrCode = 1
		SELECT @ErrMsg = 'This account is not valid.'
		RETURN
	END

	IF NOT EXISTS(
		SELECT 1 
		FROM [dbo].[VRSettingHierarchy] h (NOLOCK) 
			INNER JOIN [dbo].[VRCustSetting] vr (NOLOCK) ON vr.CustID = 0 AND vr.[LevelID] = h.[LevelID]
		WHERE h.[SportType] = @SportType
	)
	BEGIN
		SELECT @ErrCode = 2
		SELECT @ErrMsg = 'This SportType is not supported'
		RETURN
	END


	INSERT INTO #VRLineCustID(CustID, RoleID)
	SELECT v.custid, MAX(v.roleid) AS RoleID
	FROM Customer c WITH (NOLOCK)
	CROSS APPLY
		(VALUES (c.custid, 1),
				 (c.recommend, 2),
				 (c.mrecommend, 3),
				 (c.srecommend, 4),
				 (0, 5)
		 ) v(CustID, RoleId)
	WHERE c.custid = @CustID
	GROUP BY v.custid
	--SELECT CustID,MAX(RoleID) RoleID
	--FROM (
	--	SELECT upv.Val CustID, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) RoleID
	--	FROM (
	--		SELECT custid,recommend,mrecommend,srecommend,0 [Global]
	--		FROM Customer (NOLOCK)
	--		WHERE CustID=@CustID
	--	) t
	--	UNPIVOT
	--	(
	--		Val
	--		FOR col IN (custid,recommend,mrecommend,srecommend,[Global])
	--	) upv
	--) tmp
	--GROUP BY CustID

	INSERT INTO #VRCustSetting(CustID, LevelID, ValueIDLive, ValueIDNonLive)
	SELECT vr.CustID, vr.LevelID, ValueIDLive, ValueIDNonLive
	FROM VRSettingHierarchy h (NOLOCK)
	INNER JOIN VRCustSetting vr (NOLOCK)
		ON h.LevelID = vr.LevelID
	WHERE CustID IN (SELECT CustID FROM #VRLineCustID) 
		AND h.SportType = @SportType

	CREATE UNIQUE CLUSTERED INDEX PK_LevelID ON #VRCustSetting(CustID, LevelID)


	;WITH VR_Hierachy AS (
	   SELECT LevelID SrcLevelID, LevelID, ParentLevelID, 1 LayerNo
	   FROM VRSettingHierarchy h (NOLOCK)
	   WHERE SportType = @SportType 
	   UNION ALL
	   SELECT p.SrcLevelID, c.LevelID, c.ParentLevelID, p.LayerNo + 1  LayerNo
	   FROM VRSettingHierarchy c (NOLOCK)
		 INNER JOIN VR_Hierachy p on p.ParentLevelID = c.LevelID  -- this is the recursion
	)
	INSERT INTO #ResultData(LevelID, ValueIDLive, ValueIDNonLive, FollowingCustID, FollowingValueIDLive, FollowingValueIDNonLive,
					RowNo_Live, RowNo_NonLive, FollowingLevelID)
	SELECT LevelID,ValueIDLive,ValueIDNonLive,FollowingCustID,FollowingValueIDLive,FollowingValueIDNonLive,
				RowNo_Live, RowNo_NonLive, FollowingLevelID
	FROM (
		SELECT h.SrcLevelID LevelID
			, ISNULL(vrc.ValueIDLive, 0) ValueIDLive, ISNULL(vrc.ValueIDNonLive,0) ValueIDNonLive
			, vr.CustID FollowingCustID
			, vr.LevelID FollowingLevelID
			, vr.ValueIDLive FollowingValueIDLive, vr.ValueIDNonLive FollowingValueIDNonLive
			, ROW_NUMBER() OVER(PARTITION BY h.SrcLevelID ORDER BY CASE WHEN ISNULL(vr.ValueIDLive, 0) = 0 THEN 2 ELSE 1 END, RoleID, LayerNo) RowNo_Live
			, ROW_NUMBER() OVER(PARTITION BY h.SrcLevelID ORDER BY CASE WHEN ISNULL(vr.ValueIDNonLive,0) = 0 THEN 2 ELSE 1 END, RoleID, LayerNo) RowNo_NonLive
		FROM VR_Hierachy h (NOLOCK)
		CROSS JOIN #VRLineCustID c
		LEFT JOIN #VRCustSetting vrc (NOLOCK) 
			ON vrc.LevelID = h.SrcLevelID
				AND vrc.CustID = @CustID
		LEFT JOIN #VRCustSetting vr (NOLOCK) 
			ON vr.LevelID = h.LevelID
				AND vr.CustID = c.CustID
	) as tmp
	WHERE RowNo_Live=1 OR RowNo_NonLive=1

	SELECT @Username Username, @Currency Currency, @ActualRate ActualRate

	;WITH Hierarchy AS (
		SELECT h.LevelID,h.VRLeagueGroupID, h.VRBetTypeGroupID,CASE WHEN h.BetType = -1 THEN NULL ELSE h.BetType END BetType
			, bg.GroupName VRBetTypeGroupName
			, lg.GroupName VRLeagueGroupName
			, h.SportType
			, SortOrder
			, LeagueGroupOrder
		FROM VRSettingHierarchy h (NOLOCK)
		LEFT JOIN VRLeagueGroup lg (NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
		LEFT JOIN VRBettypeGroup bg (NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
	)
	SELECT
		h.SportType  
		, h.VRLeagueGroupID LeagueGroupID , h.VRLeagueGroupName LeagueGroup
		, h.VRBetTypeGroupID BettypeGroupID, h.VRBetTypeGroupName BettypeGroup
		, h.BetType BetTypeID
		, h.LevelID
		--Live
		, vrl.FollowingLevelID Live_FollowingLevelID
		, v1.Value Live_FollowingValue
		, CASE 
				WHEN vrl.FollowingCustID = 0 THEN 'Global'
				WHEN vrl.FollowingCustID = @CustID THEN NULL
				WHEN cl.roleid = 4 THEN 'Super'
				WHEN cl.roleid = 3 THEN 'Master'
				WHEN cl.roleid = 2 THEN 'Agent'
			END Live_FollowingRole
		, hl.BetType Live_FollowingBetTypeID
		, hl.VRBetTypeGroupName Live_FollowingBettypeGroup
		, hl.VRLeagueGroupName Live_FollowingLeagueGroup
		--NonLive
		, vrnl.FollowingLevelID NonLive_FollowingLevelID
		, v2.Value NonLive_FollowingValue
		, CASE 
				WHEN vrnl.FollowingCustID = 0 THEN 'Global'
				WHEN vrnl.FollowingCustID = @CustID THEN NULL
				WHEN cnl.roleid = 4 THEN 'Super'
				WHEN cnl.roleid = 3 THEN 'Master'
				WHEN cnl.roleid = 2 THEN 'Agent'
			END NonLive_FollowingRole
		, hnl.BetType NonLive_FollowingBetTypeID
		, hnl.VRBetTypeGroupName NonLive_FollowingBettypeGroup
		, hnl.VRLeagueGroupName NonLive_FollowingLeagueGroup
	FROM Hierarchy h (NOLOCK)
		INNER JOIN #ResultData vrl (NOLOCK) 
			ON vrl.LevelID = h.LevelID
				AND vrl.RowNo_Live = 1
		INNER JOIN #ResultData vrnl (NOLOCK) 
			ON vrnl.LevelID = h.LevelID
				AND vrnl.RowNo_NonLive = 1
		INNER JOIN VRValueMapping v1 (NOLOCK) ON v1.ValueID = vrl.FollowingValueIDLive
		INNER JOIN VRValueMapping v2 (NOLOCK)ON v2.ValueID = vrnl.FollowingValueIDNonLive
		INNER JOIN Hierarchy hl (NOLOCK) ON hl.LevelID = vrl.FollowingLevelID
		INNER JOIN Hierarchy hnl (NOLOCK) ON hnl.LevelID = vrnl.FollowingLevelID
		LEFT JOIN Customer cl (NOLOCK) ON cl.custid = vrl.FollowingCustID
		LEFT JOIN Customer cnl (NOLOCK) ON cnl.custid = vrnl.FollowingCustID
	WHERE h.SportType = @SportType 
	ORDER BY h.LeagueGroupOrder, h.SortOrder

END