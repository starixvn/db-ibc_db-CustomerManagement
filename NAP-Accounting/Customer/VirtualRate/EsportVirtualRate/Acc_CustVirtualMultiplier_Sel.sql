/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustVirtualMultiplier_Sel]
	@CustID INT
	, @SportType INT
	, @ErrCode TINYINT OUT
	, @ErrMsg NVARCHAR(200) OUT
AS
/*    
	Created: 20190626@Dominic    
	Task :  Retrieve VR setting of an account for a specific sport  [Redmind: #114830]
	DB: CustDB@DBCUST
	    
	Revisions:    
		- 20190626@Dominic : First commit
		- 20190626@Eden : Esport VR Phase 2 - Integrate Auto Suspend [Redmind: #121876]
		- 20200306@Eden: E-sport VR Phase 3 [Redmine: #128749] 
		- 20200610@Eden: Virtual Rate for Basketball [Redmine: #134978] 
		- 20211125@Eden: Override Auto Suspend [Redmine: #164888] 
		- 20220617@Johnson: define temp table to avoid dump db [redmine:#174035]
		- 20221103@Johnson: Change data type of CustSettingAutoSuspend [Redmine: #179782]
*/ 
BEGIN
	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @RoleID INT, @recommend INT, @mrecommend INT, @srecommend INT, @Username NVARCHAR(50)
	DECLARE @ActualRate FLOAT, @Currency NVARCHAR(50), @UplineUsername NVARCHAR(50)
	DECLARE @UplineCustID INT
	
	SELECT @RoleID =roleid
			, @recommend = recommend, @mrecommend = mrecommend
			, @srecommend = srecommend
			, @ActualRate = e.actualrate
			, @Currency = e.currency
			, @Username = Username
	FROM Customer c WITH(NOLOCK)
		INNER JOIN exchange e WITH(NOLOCK) ON  e.exchangeid = c.currency  
	WHERE CustID = @CustID AND c.roleid IN (1,2,3,4)
		

	IF @CustID IS NULL OR (@CustID <> 0 AND @Currency IS NULL) 
	BEGIN
		SELECT @ErrCode = 1
		SELECT @ErrMsg = 'This account is not existing'
		RETURN
	END

	IF NOT EXISTS(
		SELECT 1 
		FROM [dbo].[VRSettingHierarchy] h WITH(NOLOCK) 
			INNER JOIN [dbo].[VRCustSetting] vr WITH(NOLOCK) ON vr.CustID = 0 AND vr.[LevelID] = h.[LevelID]
		WHERE h.[SportType] = @SportType
	)
	BEGIN
		SELECT @ErrCode = 2
		SELECT @ErrMsg = 'This SportType is not supported'
		RETURN
	END

	IF @RoleID = 1
		SELECT @UplineCustID = @recommend
	ELSE IF @RoleID = 2
		SELECT @UplineCustID = @mrecommend
	ELSE IF @RoleID = 3
		SELECT @UplineCustID = @srecommend
	ELSE IF @RoleID = 4
		SELECT @UplineCustID = 0

	SELECT @UplineUsername = username
	FROM customer WITH(NOLOCK)
	WHERE CustID = @UplineCustID

	--1st Dataset: Cust/currency info
	SELECT @CustID CustID,@Username Username, @Currency Currency,@ActualRate ActualRate, @UplineCustID UplineCustID, @UplineUsername UplineUsername , @RoleID AS RoleID

	DECLARE @InitialBitMap VARBINARY(128) = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	DECLARE @InitialBitMap_0 VARBINARY(128) = 0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
	DECLARE @AutoSuspendLive    VARBINARY(128) = @InitialBitMap, 
			@AutoSuspendNonLive VARBINARY(128) = @InitialBitMap,
			@OverrideASLive		VARBINARY(128) = @InitialBitMap_0,
			@OverrideASNonLive	VARBINARY(128) = @InitialBitMap_0
	
	CREATE TABLE #tempVR(SportType SMALLINT, LeagueGroupID INT, LeagueGroup nvarchar(400), BettypeGroupID SMALLINT, BettypeGroup NVARCHAR(400),BetTypeID SMALLINT,LevelID INT,
					ValueIDLIVE TINYINT, ValueLIVE smallmoney, ValueIDNonLIVE TINYINT,ValueNonLIVE smallmoney,IsLiveAutoSuspend BIT,IsNonLiveAutoSuspend BIT,
					ParentLevelID INT,SortOrder INT,VRAutoSuspendThresholdNonLive INT,VRAutoSuspendThresholdLive INT,
					IsOverrideASLive BIT,IsOverrideASNonLive BIT)
					
	SELECT @AutoSuspendLive = AutoSuspendLive, 
		   @AutoSuspendNonLive = AutoSuspendNonLive,
		   @OverrideASLive = ISNULL(OverrideASLive, @OverrideASLive),
		   @OverrideASNonLive = ISNULL(OverrideASNonLive, @OverrideASNonLive)
	FROM dbo.CustSettingAutoSuspend WITH(NOLOCK)
	WHERE custid = @CustID AND SportType = @SportType

	--2nd Dataset: Virtual Rate
	INSERT INTO #tempVR(SportType,LeagueGroupID,LeagueGroup,BettypeGroupID,BettypeGroup,BetTypeID,LevelID,
					ValueIDLIVE,ValueLIVE,ValueIDNonLIVE,ValueNonLIVE,IsLiveAutoSuspend,IsNonLiveAutoSuspend,
					ParentLevelID,SortOrder,VRAutoSuspendThresholdNonLive,VRAutoSuspendThresholdLive,
					IsOverrideASLive,IsOverrideASNonLive)
	SELECT h.SportType
		,lg.GroupID LeagueGroupID, lg.GroupName LeagueGroup
		,bg.GroupID BettypeGroupID, bg.GroupName BettypeGroup
		,h.BetType BetTypeID
		,h.LevelID
		,ISNULL(ValueIDLIVE,0) ValueIDLIVE, vlive.Value ValueLIVE
		,ISNULL(ValueIDNonLIVE,0) ValueIDNonLIVE, vnonlive.Value ValueNonLIVE
		,Live.value as IsLiveAutoSuspend
		,NonLive.value IsNonLiveAutoSuspend
		,h.ParentLevelID
		,h.SortOrder
		,h.VRAutoSuspendThresholdNonLive
		,h.VRAutoSuspendThresholdLive
		,O_Live.value AS IsOverrideASLive
		,O_NonLive.value AS IsOverrideASNonLive	
	FROM VRSettingHierarchy h WITH(NOLOCK)
		LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
		LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
		LEFT JOIN VRCustSetting vr WITH(NOLOCK) 
			ON vr.CustID = @CustID
				AND vr.LevelID = h.LevelID
		LEFT JOIN VRValueMapping vlive WITH(NOLOCK) ON vr.ValueIDLIVE = vlive.ValueID
		LEFT JOIN VRValueMapping vnonlive WITH(NOLOCK) ON vr.ValueIDNonLIVE = vnonlive.ValueID
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (@AutoSuspendLive,h.BitmapOrderAutoSuspend) Live
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (@AutoSuspendNonLive,h.BitmapOrderAutoSuspend) NonLive
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (@OverrideASLive,h.BitmapOrderAutoSuspend) O_Live
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (@OverrideASNonLive,h.BitmapOrderAutoSuspend) O_NonLive
	WHERE h.SportType = @SportType

	CREATE CLUSTERED INDEX PK_tempVR_LevelID ON #tempVR(LevelID)
	
	SELECT h.SportType, 
		h.LeagueGroupID, 
		h.LeagueGroup, 
		h.BettypeGroupID, 
		h.BettypeGroup, 
		h.BetTypeID, 
		h.LevelID, 
		h.ValueIDLIVE, 
		h.ValueLIVE, 
		h.ValueIDNonLIVE, 
		h.ValueNonLIVE, 
		IsLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 AND h.sporttype <> 2 THEN NULL
								--WHEN h.IsOverrideASLive = 1 THEN 1 
								ELSE h.IsLiveAutoSuspend END, 
		IsNonLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 AND h.sporttype <> 2 THEN NULL
									--WHEN h.IsOverrideASNonLive = 1 THEN 1 
									ELSE h.IsNonLiveAutoSuspend END,
		IsDisableLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 AND h.sporttype <> 2 THEN NULL
										 WHEN COALESCE(h.ValueLIVE,pr1.ValueLIVE,pr2.ValueLIVE,pr3.ValueLIVE) >= h.VRAutoSuspendThresholdLive THEN 0 
									ELSE 1 END,
		IsDisableNonLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 AND h.sporttype <> 2 THEN NULL
											WHEN COALESCE(h.ValueNonLIVE,pr1.ValueNonLIVE,pr2.ValueNonLIVE,pr3.ValueNonLIVE) >= h.VRAutoSuspendThresholdNonLive THEN 0 
									ELSE 1 END,
		h.VRAutoSuspendThresholdLive,
		h.VRAutoSuspendThresholdNonLive,
		IsOverrideASLive = CASE WHEN h.BetTypeID = -1 AND h.sporttype <> 2 THEN NULL ELSE h.IsOverrideASLive END,
		IsOverrideASNonLive = CASE WHEN h.BetTypeID = -1 AND h.sporttype <> 2 THEN NULL ELSE h.IsOverrideASNonLive END
	FROM #tempVR h
		LEFT JOIN #tempVR pr1 WITH(NOLOCK)
			ON h.ParentLevelID = pr1.LevelID
		LEFT JOIN #tempVR pr2 WITH(NOLOCK)
			ON pr1.ParentLevelID = pr2.LevelID 
		LEFT JOIN #tempVR pr3 WITH(NOLOCK)
			ON pr2.ParentLevelID = pr3.LevelID 
	ORDER BY h.SortOrder

	DROP TABLE #tempVR
END