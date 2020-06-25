/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
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
	- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]
	- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
	- 20180125@Winnie: Hide inactive products, Keep 2 cols: Disable151_AU,SyncLiveCasino for report part [RedmineID: #86086] 
	- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
	- 20180830@Elodie: Add new bettype of Poker Games Product - [Redmine: #97675]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20180919@Winnie: Add new bettype of Esports - [Redmine: #101526]
	- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
	- 20190909@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20191206@Eden: Add Virtual Games [Redmine: #122743]
	- 20200310@Percy: Get IsAllDayBalTransfer on CustMaster for master/agent/member level [RedmineID: #130091]
	- 20200318@Elodie: Add Saba.club [Redmine: #130636]
	- 20200303@Tiara: Add SA Gaming Product [Redmine: #128058]
	- 20200321@Tiara: Add Sexy Gaming Product [Redmine: #130678]
	- 20200406@Elodie: Add BBIN Product [Redmine: #131363]
	- 20200403@Elodie: Add Table Games Product [Redmine: #129440]
	- 20200421@Elodie: Add GTCasino Product [Redmine: #130689]
	- 20200428@Eden: HotFix_-_The_status_Virtual_game_show_grey_color [Redmine: #133328]
	- 20200504@Eden: ION Live casino [Redmine: #132323]
	- 20200506@Tiara: Add RNG War Product [Redmine: 132018]
	- 20200624@Winfred: Alpha - Enable/disable status for Saba Virtual Sport [Redmine: #136210]


Param's Explanation:
� @system: = NAP : internal login from NAP
			NAPEXT:internal login from NAP EXT
� @CustID: customer id.   
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
			,@srecommend INT = 0
			,@ClosedReason TINYINT
			,@IsDeposit BIT=0
	DECLARE @IsAllDayBalTransfer BIT
	
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
		
	END
	ELSE IF @roleid = 3 --master
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) ,
			@LimitPerIP =  isnull(LimitPerIP, 0),
			@SelectedBetting =  isnull(SelectedBetting, 0)
		FROM custMaster WITH (NOLOCK) WHERE custid = @custid

		SELECT
			@IsAllDayBalTransfer = ISNULL(IsAllDayBalTransfer, 0)
		FROM dbo.CustMaster WITH (NOLOCK)
		WHERE custid = @custid
	END
	ELSE IF @roleid = 2 --agent
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) ,
			@LimitPerIP =  isnull(LimitPerIP, 0),
			@SelectedBetting =  isnull(SelectedBetting, 0)
		FROM custAgent WITH (NOLOCK) WHERE custid = @custid

		SELECT 
			@IsAllDayBalTransfer=ISNULL(IsAllDayBalTransfer, 0)
	    FROM dbo.CustMaster WITH(NOLOCK)
		WHERE custid = (SELECT mrecommend FROM Customer WITH(NOLOCK) WHERE Custid= @custid)
			
			
	END
	ELSE IF @roleid = 1 --member
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) 
		FROM custAgent WITH (NOLOCK) WHERE custid = @agentid
		
			
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
			EXEC DBPOL.NAP_UserControl.dbo.Acc_Con_CheckPermission_All @custid=@AdminID,@funcname='[ViewIPVN]',@ErrCode=@ErrCode OUTPUT
		END
		ELSE IF @system = 'NAPEXT'
		BEGIN
			EXEC DBPOL.NAP_UserControl.dbo.EAS_UserCheckPermission_All @userid=@AdminID,@FuncKey='ViewVNIP',@ErrCode=@ErrCode OUTPUT
		END
		
		IF @ErrCode<> 0 SELECT @IsAdminCanViewVNIP = 0 ELSE SELECT @IsAdminCanViewVNIP = 1     
	END

	 -- For DCS Product
    DECLARE	@bitmapOrder_MuayThai		INT
		,	@bitmapOrder_Esports		INT
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_AllBetVIP		INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_FishingWorld	INT
		,	@bitmapOrder_VS				INT
		,	@bitmapOrder_VG				INT
		,	@bitmapOrder_SabaClub		INT
		,	@bitmapOrder_SAGaming		INT 
		,	@bitmapOrder_ION		INT 
		,	@bitmapOrder_SexyGaming		INT 
		,	@bitmapOrder_BBIN			INT 
		,	@bitmapOrder_TableGames		INT 
		,	@bitmapOrder_RNGWar			INT 
		,	@bitmapOrder_GTCasino		INT
		,	@bitmapOrder_SabaVirtualSport INT

    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)    
	SET @bitmapOrder_Esports = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 43 AND Bettype = 1)    
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1021)
	SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
	SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)
    SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 180 AND Bettype = 1201)
    SET	@bitmapOrder_AllBet =	(SELECT	psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE	psp.Sporttype = 211 AND	psp.Bettype = 2401)
    SET	@bitmapOrder_AllBetVIP = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 211 AND	psp.Bettype = 2402)
	SET @bitmapOrder_VG = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 245 AND Bettype = 4601)
	SET @bitmapOrder_SabaClub = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 200 AND Bettype = 1611)
	SET @bitmapOrder_SAGaming = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 244 AND Bettype = 3001)
	SET @bitmapOrder_SexyGaming = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 243 AND Bettype = 3101)
	SET @bitmapOrder_GTCasino = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 242 AND Bettype = 3201)
	SET @bitmapOrder_ION = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 225 AND Bettype = 5601)
	SET @bitmapOrder_BBIN = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 241 AND Bettype = 3300)
	SET @bitmapOrder_TableGames = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 222 AND Bettype = 4901)
	SET @bitmapOrder_RNGWar = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 224 AND Bettype = 5500)
	SET @bitmapOrder_SabaVirtualSport = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 98 AND Bettype = 1)

    DECLARE	@IsHidden_MuayThai		INT = 1
		,	@IsHidden_Esports		INT = 1
		,	@IsHidden_AllBet		INT = 1
		,	@IsHidden_VoidBridge	INT = 1
		,	@IsHidden_Lottery		INT = 1
		,	@IsHidden_NG2			INT = 1  
		,	@IsHidden_FishingWorld	INT = 1
		,	@IsHidden_VS			INT = 1
		,	@IsHidden_VG			INT = 1
		,	@IsHidden_SabaClub		INT = 1
		,	@IsHidden_SAGaming		INT = 1
		,	@IsHidden_ION		INT = 1
		,	@IsHidden_SexyGaming	INT = 1
		,	@IsHidden_BBIN			INT = 1
		,	@IsHidden_TableGames	INT = 1
		,	@IsHidden_RNGWar		INT = 1
		,	@IsHidden_GTCasino		INT = 1
		,	@IsHidden_SabaVirtualSport	INT = 1


	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_MuayThai OUTPUT	
	EXEC Acc_CheckShowProduct @ProductID = 41, @Sporttype = 211, @IsHide = @IsHidden_AllBet OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 22, @IsHide = @IsHidden_VoidBridge OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @Sporttype = 220, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 23, @IsHide = @IsHidden_NG2 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 24, @IsHide = @IsHidden_FishingWorld OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5,  @IsHide = @IsHidden_VS OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_Esports OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 38, @IsHide = @IsHidden_VG OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 42, @IsHide = @IsHidden_SabaClub OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @Sporttype = 244, @IsHide = @IsHidden_SAGaming OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @Sporttype = 243, @IsHide = @IsHidden_SexyGaming OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @Sporttype = 242, @IsHide = @IsHidden_GTCasino OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @Sporttype = 225, @IsHide = @IsHidden_ION OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @Sporttype = 222, @IsHide = @IsHidden_TableGames OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @Sporttype = 224, @IsHide = @IsHidden_RNGWar OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @Sporttype = 241, @IsHide = @IsHidden_BBIN OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 54, @Sporttype = 98, @IsHide = @IsHidden_SabaVirtualSport OUTPUT
	
	--Handle dummy product 41: LiveCasino (Allbet + SAGaming + SexyGaming + BBIN + ION)
	DECLARE	@DisableAllbet			BIT,
			@HideAllbet         	BIT,
			@SyncedAllbet       	BIT,
			@DisableSAGaming		BIT,
			@HideSAGaming       	BIT,
			@SyncedSAGaming     	BIT = 1, --always sync
			@DisableSexyGaming		BIT,
			@HideSexyGaming     	BIT,
			@SyncedSexyGaming		BIT = 1, --always sync
			@DisableGTCasino		BIT,
			@HideGTCasino     		BIT,
			@SyncedGTCasino			BIT = 1, --always sync
			@DisableION	BIT,
			@HideION    	BIT,
			@SyncedION 	BIT = 1, --always sync
			@DisableBBIN			BIT,
			@HideBBIN				BIT,
			@SyncedBBIN				BIT = 1 --always sync
	--Handle dummy product 44: RNG Lottery (Lottery + TableGame + RNGWar)
	DECLARE	@DisableLottery		BIT,
			@HideLottery        BIT,
			@SyncedLottery      BIT = 1, --always sync
			@DisableTableGames	BIT,
			@HideTableGames     BIT,
			@SyncedTableGames   BIT = 1, --always sync
			@DisableRNGWar	BIT,
			@HideRNGWar    BIT,
			@SyncedRNGWar   BIT = 1 --always sync
		
	SELECT 			
	-- For AllBet
		@DisableAllbet = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_AllBet), 1),
		@HideAllbet  = CAST(CASE WHEN @IsHidden_AllBet = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_AllBet), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@SyncedAllbet = ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_AllBet), 0),		
	-- For SA Gaming
		@DisableSAGaming = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_SAGaming), 1),	
		@HideSAGaming  = CAST(CASE WHEN @IsHidden_SAGaming = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_SAGaming), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For Sexy Gaming
		@DisableSexyGaming = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_SexyGaming), 1),	
		@HideSexyGaming  = CAST(CASE WHEN @IsHidden_SexyGaming = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_SexyGaming), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For GTCasino
		@DisableGTCasino = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_GTCasino), 1),	
		@HideGTCasino  = CAST(CASE WHEN @IsHidden_GTCasino = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_GTCasino), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For ION
		@DisableION = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_ION), 1),	
		@HideION  = CAST(CASE WHEN @IsHidden_ION = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_ION), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For BBIN
		@DisableBBIN = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_BBIN), 1),	
		@HideBBIN  = CAST(CASE WHEN @IsHidden_BBIN = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_BBIN), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For Lottery
		@DisableLottery = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_Lottery), 1),	
		@HideLottery  = CAST(CASE WHEN @IsHidden_Lottery = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Lottery), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For TableGames
		@DisableTableGames = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_TableGames), 1),	
		@HideTableGames  = CAST(CASE WHEN @IsHidden_TableGames = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_TableGames), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For RNGWar
		@DisableRNGWar = ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_RNGWar), 1),	
		@HideRNGWar  = CAST(CASE WHEN @IsHidden_RNGWar = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_RNGWar), 1) = 0 THEN 0 ELSE 1 END AS BIT)
	FROM custinfo AS ci WITH (nolock)
		LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
	WHERE ci.CustID = @CustID

	IF(@roleid=1)
	BEGIN
		 IF EXISTS (SELECT 1 FROM dbo.Customer c WITH(NOLOCK)
							    INNER JOIN dbo.Site s WITH(NOLOCK) ON c.site = s.site 
					    WHERE custid = @agentid
						      AND isLicensee =1)

			SET @IsDeposit = 1 
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
			ISNULL(closed,0) As Closed,
			ISNULL(autosuspend,0) As AutoSuspend,	
			ISNULL(cm.DisableAutoMPT ,0) As DisableAutoMPT,	
			ISNULL(SyncCasino,0) AS SyncCasino,
			ISNULL(DisableCasino,0) AS DisableCasino,
			ISNULL(DisableOutright,0) AS DisableOutright,
		
			ISNULL(DisableNumber,0) AS DisableNumber,	
			ISNULL(srecommend, 0) AS SRecommend,
			ISNULL(mrecommend, 0) AS MRecommend,
			ISNULL(recommend, 0) as ARecommend,
			ISNULL(@IsAdminCanViewVNIP,1) AS IsAdminCanViewVNIP,
			@LimitPerIP as LimitPerIP,
			@SelectedBetting as SelectedBetting,
			@IsInternal AS IsInternal,

			ISNULL(DoubleCommLosing,0) as DoubleCommLosing,

			ISNULL(ci.HideKeno,0) as HideKeno, 
			min(case when g.IBCBetTypeID in (1501,1503,1504,1505,1507,1508,1509,1511,1513) then cg.IsDisabled else 1 end) as DisableKeno,
			ISNULL(DisableGoldDeluxe,1) as DisableGoldDeluxe,
			ISNULL(HideGoldDeluxe,1) as HideGoldDeluxe,
			ISNULL(DisableColossusBet,1) as DisableColossusBet,
			ISNULL(HideColossusBet,1) as HideColossusBet,
			-- For MuayThai
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_MuayThai),1) AS DisableMuayThai,
			CAST(CASE WHEN @IsHidden_MuayThai = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_MuayThai),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideMuayThai,
			-- For Esports
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_Esports),1) AS DisableEsports,
			CAST(CASE WHEN @IsHidden_Esports = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Esports),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideEsports,
		
			-- For LiveCasino (AllBet+ SA Gaming + SexyGaming + ION )
			-- For LiveCasino (AllBet+ SA Gaming + SexyGaming + ION )
			CAST(CASE WHEN @DisableAllbet = 0 OR @DisableSAGaming= 0 OR @DisableSexyGaming = 0 OR @DisableBBIN = 0 OR @DisableGTCasino = 0 OR @DisableION = 0 THEN 0 ELSE 1 END AS BIT)AS DisableLiveCasino,		
			CAST(CASE WHEN @HideAllbet = 0 OR @HideSAGaming= 0 OR @HideSexyGaming = 0 OR @HideBBIN = 0 Or @HideGTCasino = 0 OR @HideION = 0 THEN 0 ELSE 1 END AS BIT) AS HideLiveCasino,	
			CAST( CASE WHEN @SyncedAllbet = 1 OR @SyncedSAGaming = 1 OR @SyncedSexyGaming = 1 OR @SyncedBBIN = 1 OR @SyncedGTCasino = 1 OR @SyncedION = 1 THEN 1 ELSE 0 END AS BIT) AS SyncedLiveCasino,
			-- For Allbet
			@DisableAllbet AS DisableAllbet,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_AllBetVIP), 1) AS DisableAllBetVIP,
			@HideAllbet AS HideAllbet,
			@SyncedAllbet AS SyncedAllbet,
			--For SA Gaming
			@DisableSAGaming AS DisableSAGaming,
			@HideSAGaming AS HideSAGaming,
			@SyncedSAGaming AS SyncedSAGaming,
			--For Sexy Gaming
			@DisableSexyGaming AS DisableSexyGaming,
			@HideSexyGaming AS HideSexyGaming,
			@SyncedSexyGaming AS SyncedSexyGaming,
			--For GT Casino
			@DisableGTCasino AS DisableGTCasino,
			@HideGTCasino AS HideGTCasino,
			@SyncedGTCasino AS SyncedGTCasino,
			--For ION
			@DisableION AS DisableION,
			@HideION AS HideION,
			@SyncedION AS SyncedION,
			--For BBIN
			@DisableBBIN AS DisableBBIN,
			@HideBBIN AS HideBBIN,
			@SyncedBBIN AS SyncedBBIN,

			-- For FishingWorld
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld), 1) AS DisableFishingWorld,		
			CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_FishingWorld), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_FishingWorld), 0) AS SyncedFishingWorld,

			ISNULL(DisableSuperLive,1) as DisableSuperLive,
			-- For VoidBridge
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge), 1) AS DisableVoidBridge,
			CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VoidBridge), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_VoidBridge), 0) AS SyncedVoidBridge,

			-- For RNGLottery (Lottery+ TableGames + RNGWar)
			CAST(CASE WHEN @DisableLottery = 0 OR @DisableTableGames= 0 OR @DisableRNGWar= 0 THEN 0 ELSE 1 END AS BIT)AS DisableRNGLottery,		
			CAST(CASE WHEN @HideLottery = 0 OR @HideTableGames = 0 OR @HideRNGWar = 0  THEN 0 ELSE 1 END AS BIT) AS HideRNGLottery,	
			CAST( CASE WHEN @SyncedLottery = 1 OR @SyncedTableGames = 1 OR @SyncedRNGWar = 1 THEN 1 ELSE 0 END AS BIT) AS SyncedRNGLottery,
		
			--For Lottery
			@DisableLottery AS DisableLottery,
			@HideLottery AS HideLottery,
			@SyncedLottery AS SyncedLottery,

			--For TableGames
			@DisableTableGames AS DisableTableGames,
			@HideTableGames AS HideTableGames,
			@SyncedTableGames AS SyncedTableGames,
			
			--For RNGWar
			@DisableRNGWar AS DisableRNGWar,
			@HideRNGWar AS HideRNGWar,
			@SyncedRNGWar AS SyncedRNGWar,

			-- For NG2
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_NG2),1) AS DisableNG2,
			CAST(CASE WHEN @IsHidden_NG2 = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_NG2),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_NG2), 0) AS SyncedNG2,

			CASE WHEN @IsDeposit=1 THEN 1 ELSE ISNULL(@ClosedReason,0) END AS ClosedReason,
			ISNULL(@IsAllDayBalTransfer, 0) IsAllDayBalTransfer,

			-- For VS
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VS), 1) AS DisableVirtualSports,		
			CAST(CASE WHEN @IsHidden_VS = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VS), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,

			-- For VG
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VG), 1) AS DisableVirtualGames,		
			CAST(CASE WHEN @IsHidden_VG = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VG), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualGames,
			-- For SabaClub
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_SabaClub), 1) AS DisableSabaClub,		
			CAST(CASE WHEN @IsHidden_SabaClub = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_SabaClub), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideSabaClub,
			-- For Saba Vitual Sports
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_SabaVirtualSport),1) AS DisableSabaVirtualSport,
			CAST(CASE WHEN @IsHidden_Esports = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_SabaVirtualSport),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideSabaVirtualSport
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
			ci.SyncCasino, 
			ci.DisableCasino, 
			ci.DisableOutright, 
		
			ci.DisableNumber, 
			ci.srecommend, 
			ci.mrecommend, 
			ci.recommend, 
			ci.DoubleCommLosing,
			ci.HideKeno,
			ci.DisableGoldDeluxe, 
			ci.HideGoldDeluxe,
			ci.DisableColossusBet,
			ci.HideColossusBet,
			cps.bitmapIsDisabled,
			cps.bitmapIsHidden,
			cps.bitmapHasSynced,
			ci.DisableSuperLive
END
GO