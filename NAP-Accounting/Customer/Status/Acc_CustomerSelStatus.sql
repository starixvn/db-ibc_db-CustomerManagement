/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Acc_CustomerSelStatus]
	@CustID		INT,
	@AdminID	INT			= 0,
	@system		VARCHAR(30)	='NAP',
	@username	VARCHAR(50)	= ''
AS 
BEGIN
/*
Created: 20090125@nqminh
Task : Select customer's status
DB: DBACC.bodb02
Original: 

Revisions:
    - 20090411@PhuongDoan: Add casino status    
    - 20090731@nqminh: Add outright status    
	- 20090806@huynguyen: Add closed, autosuspend, isautopositiontaking
	- 20090829@[Shifu]: Add IsInternal
	- 20100223@[Ryan]: Add IsAdminCanViewVNIP
	- 20100227@Jamie: Change the way to check permission 
	- 20100402@Lee: Add mrecommend, arecommend 
	- 20100504@Huynguyen: Add DisableOpenTote
	- 20100828@SonPhan: Add DisableBingo, DisableNumber, SyncBingo
	- 20101015@Ethan: Get Limited Per IP value @LimitPerIP + SelectedBetting
	- 20110914@Tom: Add column DisableP2P
	- 20120131@Johnson: - Add Parameter @username support get by username
						- Add DisableLiveCasino, SyncLiveCasino
	- 20120808@Sophia: Add DisableVirtualSports, HideVirtualSports	
	- 20120927@Sophia: Get DoubleCommLosing	
	- 20130723@Jamie: Change Alias DB03 to DBPOLICY
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20140303@Kathy: Get HideKeno [Redmine:#12691]
	- 20140407@Elodie: Get DisableKeno [Redmine:#13156]
	- 20140825@Logan:   Get status of E-Sports [Redmine: #20531]
	- 20150210@Johnson: use param @system to check permission on ViewIPVN function from NAP or NAP EXT internal login [Redmine: #30860]
	- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	- 20150717@Kiwi: Move SP to DB06.bodb02 to solve the performance issue for temporary	
	- 20150707@Elodie: Add Super Live product [Redmine: #35776]
	- 20150721@Winnie: Add Microgaming product 
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20151028@Helen: Member Information to support Muay Thai  [Redmine: #45496]
	- 20151106@Patrick: Support RnG Game & rename field named DisableMicroGame to DisableMicroGameLC
	- 20151209@Helen: Member information for Cockfighting [Redmine: #48133]
	- 20160114@Helen: Cricket - [Redmine: #50027]
	- 20160127@Billy: Member information for AllBet - [Redmine: #51591]
	- 20160407@Winnie: VoidBridge - [Redmine: #55259 ]
	- 20160801@Elodie: NG2 product - [Redmine: #60809]
	- 20160815@Winnie: AllBet add more status for Bettype VIP Barcarat - [Redmine: #61733 ]
	- 20161028@Winnie: Fishing world [Redmine's Ids: #65474]
	- 20160801@Elodie: Implementing NewProductStatus Plugin - [Redmine #70722]	
	- 20170417@Winnie: Change to call the sp Acc_CheckShowProduct- [Redmine #72336]	
	- 20170517@Winnie: Apply color for closed accounts - [Redmine #74494]	
	- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
	- 20170612@Winnie: New agent cash balance - [Redmine:74291]
	- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]

Param's Explanation:
• @system: = NAP : internal login from NAP
			NAPEXT:internal login from NAP EXT
• @CustID: customer id.   
*/

	SET NOCOUNT ON

	----- 20150610@Kos -------------------
	--DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)	

	--BEGIN TRY
		--INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		--SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM dbo.GameType WITH (NOLOCK)
	--END TRY
	--BEGIN CATCH
	--	INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
	--	SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
	--END CATCH
	----- 20150610@Kos -------------------

	DECLARE @agentid INT, @roleid TINYINT, @IsInternal BIT, @IsAdminCanViewVNIP BIT,  @LimitPerIP tinyint, @SelectedBetting bit
			,@IsMyanmarOdds BIT = 0
			,@srecommend INT = 0
			,@ClosedReason TINYINT
			,@IsDeposit BIT=0
	DECLARE @IsIMBC BIT = 0,@IsAllDayBalTransfer BIT
	
	IF ISNULL(@username,'') <> ''
		SELECT @roleid = roleid, @agentid = recommend, @custid = custid,@srecommend = srecommend
		FROM custinfo WITH (NOLOCK)
		WHERE username = @username
	ELSE 
		SELECT @roleid = roleid, @agentid = recommend,@srecommend = srecommend
		FROM custinfo WITH (NOLOCK)
		WHERE custid = @CustID
		
	SET @LimitPerIP = 0
	SET @SelectedBetting = 0
	SET @IsInternal = 0
	
	IF @roleid = 4 --super
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) ,
			@LimitPerIP =  isnull(LimitPerIP, 0),
			@SelectedBetting =  isnull(SelectedBetting, 0),
			@IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
		FROM custSuper WITH (NOLOCK) WHERE custid = @custid

		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@custid)
		
		IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @CustID AND [Site] = 'IMBC')
			SET @IsIMBC = 1

	END
	ELSE IF @roleid = 3 --master
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) ,
			@LimitPerIP =  isnull(LimitPerIP, 0),
			@SelectedBetting =  isnull(SelectedBetting, 0)
		FROM custMaster WITH (NOLOCK) WHERE custid = @custid
		
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@custid)
		
		IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @CustID AND [Site] = 'IMBC')
			SET @IsIMBC = 1

		SELECT 
		@IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	    FROM custSuper WITH(NOLOCK)
		WHERE custid = (SELECT srecommend FROM Customer WITH(NOLOCK) WHERE Custid= @custid)

	END
	ELSE IF @roleid = 2 --agent
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) ,
			@LimitPerIP =  isnull(LimitPerIP, 0),
			@SelectedBetting =  isnull(SelectedBetting, 0)
		FROM custAgent WITH (NOLOCK) WHERE custid = @custid
		
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@custid)
		
		IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @CustID AND [Site] = 'IMBC')
			SET @IsIMBC = 1

		SELECT 
			@IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	    FROM custSuper WITH(NOLOCK)
		WHERE custid = (SELECT srecommend FROM Customer WITH(NOLOCK) WHERE Custid= @custid)
			
			
	END
	ELSE IF @roleid = 1 --member
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) 
		FROM custAgent WITH (NOLOCK) WHERE custid = @agentid
		
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@agentid)
		
		IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @agentid AND [Site] = 'IMBC')
			SET @IsIMBC = 1
			
	END
	
	--Get Internal status
	/*
	SELECT @IsInternal = CASE @roleid WHEN 4 THEN (SELECT isnull(IsInternal, 0) FROM custSuper WITH (NOLOCK) WHERE custid = @custid)
									  WHEN 3 THEN (SELECT isnull(IsInternal, 0) FROM custMaster WITH (NOLOCK) WHERE custid = @custid)
									  WHEN 2 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @custid)
									  WHEN 1 THEN (SELECT isnull(IsInternal, 0) FROM custAgent WITH (NOLOCK) WHERE custid = @agentid)
									  ELSE 0 END 
	*/								  

	SELECT @IsAdminCanViewVNIP = 1
	IF (@AdminID > 0) 
	BEGIN
		DECLARE @ErrCode INT
		IF @system = 'NAP'
		BEGIN
			EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission_All @custid=@AdminID,@funcname='[ViewIPVN]',@ErrCode=@ErrCode OUTPUT
		END
		ELSE IF @system = 'NAPEXT'
		BEGIN
			EXEC DBEAS.bodb_EAS.dbo.EAS_UserCheckPermission_All @userid=@AdminID,@FuncKey='ViewVNIP',@ErrCode=@ErrCode OUTPUT
		END
		
		IF @ErrCode<> 0 SELECT @IsAdminCanViewVNIP = 0 ELSE SELECT @IsAdminCanViewVNIP = 1     
	END

	 -- For DCS Product
    DECLARE	@bitmapOrder_MuayThai		INT
		,	@bitmapOrder_CockFighting	INT
		,	@bitmapOrder_Cricket		INT
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_AllBetVIP		INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_FishingWorld	INT
		,	@bitmapOrder_VS				INT

    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)
    SET @bitmapOrder_CockFighting = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 206 AND Bettype = 1003)
	SET	@bitmapOrder_AllBet =	(
									SELECT	psp.bitmapOrder
									FROM	dbo.ProductStatusProfile AS psp WITH(NOLOCK)
									WHERE	psp.Sporttype = 211
										AND	psp.Bettype = 2401
								)
	SET	@bitmapOrder_AllBetVIP =	(
									SELECT	psp.bitmapOrder
									FROM	dbo.ProductStatusProfile AS psp WITH(NOLOCK)
									WHERE	psp.Sporttype = 211
										AND	psp.Bettype = 2402
								)
    
    SET @bitmapOrder_Cricket = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 50 AND Bettype = 501)
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1021)
	SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
	SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)
    SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 180 AND Bettype = 1201)
    
    
    DECLARE	@IsHidden_MuayThai			INT = 1
		,	@IsHidden_CockFighting		INT = 1
		,	@IsHidden_Cricket			INT = 1
		,	@IsHidden_AllBet			INT = 1
		,	@IsHidden_VoidBridge		INT = 1
		,	@IsHidden_Lottery			INT = 1
		,	@IsHidden_NG2				INT = 1
		,	@IsHidden_FishingWorld		INT = 1
		,	@IsHidden_VS				INT = 1
   
	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_MuayThai OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 19, @IsHide = @IsHidden_CockFighting OUTPUT	
	EXEC Acc_CheckShowProduct @ProductID = 21, @IsHide = @IsHidden_AllBet OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 22, @IsHide = @IsHidden_VoidBridge OUTPUT
		EXEC Acc_CheckShowProduct @ProductID = 28, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 23, @IsHide = @IsHidden_NG2 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 24, @IsHide = @IsHidden_FishingWorld OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5,  @IsHide = @IsHidden_VS OUTPUT

	IF @IsIMBC=0
		SELECT @IsHidden_Cricket=1
	ELSE	
				EXEC Acc_CheckShowProduct @ProductID = 20, @IsHide = @IsHidden_Cricket OUTPUT	

	IF(@roleid=1)
	BEGIN
		 IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @agentid
						      AND isLicensee =1)

			SET @IsDeposit =1
			IF @IsDeposit<>1
				SELECT @ClosedReason=ClosedReason FROM CustLoginInfo_Member WITH(NOLOCK) WHERE Custid=@custid
	END
	ELSE
	BEGIN	
		 IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @custid
						      AND isLicensee =1)
			SET @IsDeposit =1
    		IF @IsDeposit<>1
				SELECT @ClosedReason=ClosedReason FROM CustLoginInfo WITH(NOLOCK) WHERE Custid=@custid	
	END
	SELECT	ISNULL(reject,0) AS Suspend,
			ISNULL (closed,0) As Closed,
			ISNULL (autosuspend,0) As AutoSuspend,	
			ISNULL (cm.DisableAutoMPT ,0) As DisableAutoMPT,	
			ISNULL(DisableHorseracing,0) AS DisableHorseracing,
			ISNULL(DisableOpenTote,0) AS DisableOpenTote,
			ISNULL(DisableFinancial,0) AS DisableFI,
			ISNULL(SyncCasino,0) AS SyncCasino,
			ISNULL(DisableCasino,0) AS DisableCasino,
			ISNULL(DisableOutright,0) AS DisableOutright,
			ISNULL(DisableBingo,0) AS DisableBingo,
			ISNULL(DisableNumber,0) AS DisableNumber,
			ISNULL(DisableP2P,0) AS DisableP2P,	   
			ISNULL(SyncBingo,0) AS SyncBingo,
			ISNULL(DisableLiveCasino,0) AS DisableLiveCasino,
			ISNULL(SyncLiveCasino,0) AS SyncLiveCasino,
			ISNULL(srecommend, 0) AS SRecommend,
			ISNULL(mrecommend, 0) AS MRecommend,
			ISNULL(recommend, 0) as ARecommend,
			ISNULL(@IsAdminCanViewVNIP,1) AS IsAdminCanViewVNIP,
			@LimitPerIP as LimitPerIP,
			@SelectedBetting as SelectedBetting,
			@IsInternal AS IsInternal,
			--ISNULL(DisableVirtualSports,0) as DisableVirtualSports,
			--ISNULL(HideVirtualSports,0) as HideVirtualSports,
			ISNULL(DoubleCommLosing,0) as DoubleCommLosing,
			ISNULL(DisableHRFixedOdds,0) AS DisableHRFixedOdds,
			ISNULL(ci.DisableEsports, 0) AS DisableEsports,

			ISNULL(ci.HideKeno,0) as HideKeno, 
			min(case when g.IBCBetTypeID in (1501,1503,1504,1505,1507,1508,1509,1511,1513) then cg.IsDisabled else 1 end) as DisableKeno,
			ISNULL(DisableGoldDeluxe,1) as DisableGoldDeluxe,
			ISNULL(HideGoldDeluxe,1) as HideGoldDeluxe,
			
			ISNULL(DisableColossusBet,1) as DisableColossusBet,
			ISNULL(HideColossusBet,1) as HideColossusBet,
			
			ISNULL(DisableMicrogameLC,1) as DisableMicrogameLC,
			-- For MuayThai
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_MuayThai),1) AS DisableMuayThai,
			CAST(CASE WHEN @IsHidden_MuayThai = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_MuayThai),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideMuayThai,
			-- For CockFighting
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_CockFighting),1) AS DisableCockFighting,
			CAST(CASE WHEN @IsHidden_CockFighting = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_CockFighting),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCockFighting,
			-- For AllBet
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_AllBet), 1) AS DisableAllBet,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_AllBetVIP), 1) AS DisableAllBetVIP,		
			CAST(CASE WHEN @IsHidden_AllBet = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_AllBet), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideAllBet,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_AllBet), 0) AS SyncedAllBet,
			-- For FishingWorld
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld), 1) AS DisableFishingWorld,		
			CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_FishingWorld), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_FishingWorld), 0) AS SyncedFishingWorld,

			ISNULL(DisableSuperLive,1) as DisableSuperLive,
			ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
			ISNULL(DisableMicrogameRNG,1) as DisableMicrogameRNG,
			-- For VoidBridge
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge), 1) AS DisableVoidBridge,
			CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VoidBridge), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_VoidBridge), 0) AS SyncedVoidBridge,

			-- Cricket
			@IsIMBC AS IsIMBC,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_Cricket),1) AS DisableCricket,
			CAST(CASE WHEN @IsIMBC = 1 AND @IsHidden_Cricket = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Cricket),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCricket,
			-- For Lottery
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_Lottery), 1) AS DisableLottery,		
			CAST(CASE WHEN @IsHidden_Lottery = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Lottery), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLottery,

			-- For NG2
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_NG2),1) AS DisableNG2,
			CAST(CASE WHEN @IsHidden_NG2 = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_NG2),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_NG2), 0) AS SyncedNG2,

			CASE WHEN @IsDeposit=1 THEN 1 ELSE ISNULL(@ClosedReason,0) END AS ClosedReason,
			ISNULL(@IsAllDayBalTransfer,0) IsAllDayBalTransfer,		

			-- For VS
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VS), 1) AS DisableVirtualSports,		
			CAST(CASE WHEN @IsHidden_VS = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VS), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports
	FROM custinfo AS ci WITH (nolock)
		LEFT JOIN CustMaster AS cm WITH (NOLOCK) ON ci.CustID = cm.custid
		LEFT JOIN CustGameType cg WITH(NOLOCK) ON ci.custid = cg.custid
		LEFT JOIN dbo.GameType g WITH(NOLOCK) ON cg.GameTypeID = g.GameTypeID and g.IBCBetTypeID IN (1501,1503,1504,1505,1507,1508,1509,1511,1513)		
		LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
		
	WHERE ci.CustID = @CustID
	GROUP BY
			ci.reject,
			ci.closed,
			ci.autosuspend,
			cm.DisableAutoMPT,
			ci.DisableHorseracing, 
			ci.DisableOpenTote, 
			ci.DisableFinancial, 
			ci.SyncCasino, 
			ci.DisableCasino, 
			ci.DisableOutright, 
			ci.DisableBingo, 
			ci.DisableNumber, 
			ci.DisableP2P, 
			ci.SyncBingo, 
			ci.DisableLiveCasino, 
			ci.SyncLiveCasino, 
			ci.srecommend, 
			ci.mrecommend, 
			ci.recommend, 
			--ci.DisableVirtualSports, 
			--ci.HideVirtualSports, 
			ci.DoubleCommLosing,
			ci.DisableHRFixedOdds,
			ci.DisableEsports,
			ci.HideKeno,
			ci.DisableGoldDeluxe, 
			ci.HideGoldDeluxe,
			ci.DisableColossusBet,
			ci.HideColossusBet,
			cps.bitmapIsDisabled,
			cps.bitmapIsHidden,
			cps.bitmapHasSynced,
			ci.DisableMicrogameLC,
			ci.DisableSuperLive,
			ci.DisableMicrogameRNG	
END
GO