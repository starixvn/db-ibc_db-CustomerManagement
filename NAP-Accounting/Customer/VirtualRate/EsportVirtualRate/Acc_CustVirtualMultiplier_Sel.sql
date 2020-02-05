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

	DECLARE @InitialBitMap VARBINARY(20) = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	DECLARE @AutoSuspendLive    VARBINARY(20) = @InitialBitMap, 
			@AutoSuspendNonLive VARBINARY(20) = @InitialBitMap
			
	SELECT @AutoSuspendLive = AutoSuspendLive, 
		   @AutoSuspendNonLive = AutoSuspendNonLive
	FROM dbo.CustSettingAutoSuspend WITH(NOLOCK)
	WHERE custid = @CustID

	--2nd Dataset: Virtual Rate
	SELECT h.SportType
		,lg.GroupID LeagueGroupID, lg.GroupName LeagueGroup
		,bg.GroupID BettypeGroupID, bg.GroupName BettypeGroup
		,h.BetType BetTypeID
		,h.LevelID
		,ISNULL(ValueIDLIVE,0) ValueIDLIVE, vlive.Value ValueLIVE
		,ISNULL(ValueIDNonLIVE,0) ValueIDNonLIVE, vnonlive.Value ValueNonLIVE
		,dbo.f_GetProductStatus(@AutoSuspendLive,h.BitmapOrderAutoSuspend) as IsLiveAutoSuspend
		,dbo.f_GetProductStatus(@AutoSuspendNonLive,h.BitmapOrderAutoSuspend) as IsNonLiveAutoSuspend
		,h.ParentLevelID
		,h.SortOrder
		,h.VRAutoSuspendThreshold
	INTO #tempVR
	FROM VRSettingHierarchy h WITH(NOLOCK)
		LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
		LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
		LEFT JOIN VRCustSetting vr WITH(NOLOCK) 
			ON vr.CustID = @CustID
				AND vr.LevelID = h.LevelID
		LEFT JOIN VRValueMapping vlive WITH(NOLOCK) ON vr.ValueIDLIVE = vlive.ValueID
		LEFT JOIN VRValueMapping vnonlive WITH(NOLOCK) ON vr.ValueIDNonLIVE = vnonlive.ValueID
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
		IsLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 THEN NULL ELSE h.IsLiveAutoSuspend END, 
		IsNonLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 THEN NULL ELSE h.IsNonLiveAutoSuspend END,
		IsDisableLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 THEN NULL
										 WHEN COALESCE(h.ValueLIVE,pr1.ValueLIVE,pr2.ValueLIVE,pr3.ValueLIVE) >= h.VRAutoSuspendThreshold THEN 0 
									ELSE 1 END,
		IsDisableNonLiveAutoSuspend = CASE WHEN h.BetTypeID = -1 THEN NULL
											WHEN COALESCE(h.ValueNonLIVE,pr1.ValueNonLIVE,pr2.ValueNonLIVE,pr3.ValueNonLIVE) >= h.VRAutoSuspendThreshold THEN 0 
									ELSE 1 END,
		h.VRAutoSuspendThreshold
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