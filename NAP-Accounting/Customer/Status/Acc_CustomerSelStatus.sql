/*<info serverAlias="DBCUST-CustDB,DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelStatus]
	@CustID		INT,
	@AdminID		INT			= 0,
	@system		VARCHAR(30)		='NAP',
	@username		VARCHAR(50)		= '',
	@SettingStatus	TINYINT		= 0
AS 
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
		- 20200826@Eden: Keno - Hide un-used bettype (country) of Keno [Redmine: #138657]
		- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]
		- 20200828@Winfred: Add WM Live casino [Redmine: #131589]
		- 20201130@Tina: add GDG (Gold Giamond Gaming) [RedmineID: #144105]
		- 20201012@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20201204@Tina: add BG (Big Gaming) [RedmineID: #142458]
		- 20201209@winfred: get Disable Keno for customer list smartphone [redmine: #137130]
		- 20210229@Winfred: add Sports Lottery [RedmineID: #147361]
		- 20210315@Tina: add PP Live Casino [RedmineID: #134041]
		- 20210426@Tina: Add VGaming [Redmine: #153938]
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210809@Winfred: add Bitcoin Betting [RedmineID: #159039]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20211203@Johnson: Add Cashout [redmine:#164902]
		- 20220225@Winfred: Migrate Sp DBCUST [redmine:#168849]
		- 20220315@Johnson: Add FGG [redmine:#165682]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220921@Winfred:  Macau Game Setting Page - Rename the setting page into RNG Slot and hide all bet limit setting [Redmine: #174513]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20221123@Tacy: Non-sports products - Remove GDG and Fishing World [RedmineID: #174511]
		- 20221207@Tacy: Remove columns and code used by Colossus Bets, GD product [RedmineID: #179132]
		- 20230519@Luke: YeeBet - Integrate new Live Casino product [Redmine: #186046]
		- 20230628@Tacy: NG2 - Remove Setting [Redmine: #189762]
		- 20230728@Eden: Simplify Live Casino Customer Setting [RedmineID: #189389]
		- 20231113@Johnson: Get Site.SpecialPlatfrom to remove text SABA for 777777 [redmine: #194591]
		- 20231019@Helios: Customer Setting - Migrate Sportsbook to DCS - Remove Unused column : DisableEsports, HideEsports, HideMuayThai, DisableMuayThai [RedmineID: #193083]
		- 20240417@Helios: ALPHA - IBC Indo: Saba virtual sport status checkbox is disappeared [RedmineID: #204040]
		- 20240216@Helios: Unify Live RNG Casino [Redmine: #198960]
		- 20240515@Helios: Unify RNG Games - Rollback Code RNG Casino And Enhance [Redmine: #204358] 
		- 20240725@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241022@Johnson: remove bitcoin/MyanmarOdds [redmine: #201396]
	Param's Explanation:
		- @system: = NAP : internal login from NAP
					NAPEXT:internal login from NAP EXT
		- @CustID: customer id.  
		- @SettingStatus: 0: Pro, 1: UAT
*/

BEGIN
	SET NOCOUNT ON

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

	-- Get BitmapOrder Of Dummy Product:
      DECLARE	
	
	-- GroupID = 2
			@bitmapOrder_SportsLottery	INT
		,	@bitmapOrder_RNGGames		INT
		,	@bitmapOrder_VirtualSports	INT
		,     @bitmapOrder_NumberGame		INT 

	-- GroupID = 3
		,     @bitmapOrder_LiveCasino		INT 
		,	@bitmapOrder_RNGCasino		INT
		--,	@bitmapOrder_OtherRNGCasino	INT
		
	-- Don't Changed
		,	@bitmapOrder_SabaVirtualSport INT		
		,	@bitmapOrder_CashOut		INT  

	SET @bitmapOrder_SportsLottery	= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 169 AND Bettype = 3611)		
	SET @bitmapOrder_RNGGames		= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9919 AND Bettype = 1501)	
	SET @bitmapOrder_VirtualSports	= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9908 AND Bettype = 1201)
	SET @bitmapOrder_NumberGame		= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 161 AND Bettype = 81)

	SET @bitmapOrder_LiveCasino		= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9911 AND Bettype = 2400)
	SET @bitmapOrder_RNGCasino		= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9906 AND Bettype = 4001)
	
	SET @bitmapOrder_SabaVirtualSport   = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 98 AND Bettype = 1)
	SET @bitmapOrder_CashOut		= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9903 AND Bettype = 1)
	-- Check DummyProducts Is Show or Hidden in Profile Setting:
	DECLARE	
	
		-- GroupID = 2
		@IsHidden_VirtualSports		INT = 1
	,	@IsHidden_NumberGame		INT = 1
	,	@IsHidden_SportsLottery		INT = 1
	,	@IsHidden_RNGGames		INT = 1

		-- GroupID = 3
	,	@IsHidden_LiveCasino		INT = 1
	,	@IsHidden_RNGCasino		INT = 1

		-- Don't Change
	,	@IsHidden_SabaVirtualSport	INT = 1	
	,	@IsHidden_Cashout			INT = 1


	-- GroupID = 2
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 9908, @IsHide = @IsHidden_VirtualSports OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 161, @IsHide = @IsHidden_NumberGame OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 169, @IsHide = @IsHidden_SportsLottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 9919, @IsHide = @IsHidden_RNGGames OUTPUT

	-- GroupID = 3

	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus			   , @IsHide = @IsHidden_LiveCasino OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 53, @SettingStatus = @SettingStatus, @Sporttype = 9906, @IsHide = @IsHidden_RNGCasino OUTPUT

	-- Don't Change
	EXEC Acc_CheckShowProduct @ProductID = 54, @SettingStatus = @SettingStatus, @Sporttype = 98, @IsHide = @IsHidden_SabaVirtualSport OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 25, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_Cashout OUTPUT


	-- Get Dummy ProductStatus Of Customer: IsDisable , IsHidden , IsSync
	-- GroupID = 2: Handle dummy product 44: RNG Games
	DECLARE
		  @Disable_SportsLottery			BIT
		, @Hide_SportsLottery				BIT
		, @Sync_SportsLottery				BIT = 1

		, @Disable_VirtualSports			BIT
		, @Hide_VirtualSports				BIT
		, @Sync_VirtualSports				BIT = 1

		, @Disable_NumberGame				BIT
		, @Hide_NumberGame				BIT
		, @Sync_NumberGame				BIT = 1

		, @Disable_RNGGames				BIT
		, @Hide_RNGGames					BIT
		, @Sync_RNGGames					BIT = 1

	-- GroupID = 3: Handle dummy product 41: LiveCasino
	
		, @Disable_LiveCasino				BIT
		, @Hide_LiveCasino				BIT
		, @Sync_LiveCasino				BIT = 1

	-- GroupID = 3: Handle dummy product 53: RNG Casino & Other RNG Casino

		, @Disable_RNGCasino				BIT
		, @Hide_RNGCasino					BIT
		, @Sync_RNGCasino					BIT = 1
		
	-- Don't Changed
	
		, @Disable_SabaVirtualSport			BIT
		, @Hide_SabaVirtualSport			BIT
		, @Sync_SabaVirtualSport			BIT = 1
		
		, @Disable_Cashout				BIT
		, @Hide_Cashout					BIT
		, @Sync_Cashout					BIT = 1

	SELECT
		-- GroupID = 2
		@Disable_SportsLottery	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SportsLottery)), 1),
		@Hide_SportsLottery	 = CAST(CASE WHEN @IsHidden_SportsLottery = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SportsLottery)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@Sync_SportsLottery	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_SportsLottery)), 0),	

		@Disable_VirtualSports	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VirtualSports)), 1),
		@Hide_VirtualSports	 = CAST(CASE WHEN @IsHidden_VirtualSports = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VirtualSports)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@Sync_VirtualSports	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_VirtualSports)), 0),	

		@Disable_NumberGame	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_NumberGame)), 1),
		@Hide_NumberGame		 = CAST(CASE WHEN @IsHidden_NumberGame = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_NumberGame)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@Sync_NumberGame		 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_NumberGame)), 0),	

		@Disable_RNGGames		 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_RNGGames)), 1),
		@Hide_RNGGames		 = CAST(CASE WHEN @IsHidden_RNGGames = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_RNGGames)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@Sync_RNGGames		 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_RNGGames)), 0),	

		-- GroupID = 3
		@Disable_LiveCasino	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_LiveCasino)), 1),
		@Hide_LiveCasino		 = CAST(CASE WHEN @IsHidden_LiveCasino = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_LiveCasino)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@Sync_LiveCasino		 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_LiveCasino)), 0),	

		@Disable_RNGCasino	 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_RNGCasino)), 1),
		@Hide_RNGCasino		 = CAST(CASE WHEN @IsHidden_RNGCasino = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_RNGCasino)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
		@Sync_RNGCasino		 = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_RNGCasino)), 0)

	FROM custinfo AS ci WITH (NOLOCK)
		LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
	WHERE ci.CustID = @CustID


	-- Check RealSport in DummyProducts is Offer or Not

	-- Get Data
	DECLARE @SiteID INT , @Currency INT, @SpecialPlatform TINYINT

	SELECT @Currency = ci.currency, @SiteID = s.siteid, @SpecialPlatform = ISNULL(SpecialPlatfrom,0)
	FROM customer ci WITH(NOLOCK) 
		INNER JOIN Site s WITH(NOLOCK) ON ci.site = s.site
	WHERE ci.custid = @CustID
	
	-- RealSports of dummy product 41: LiveCasino
	DECLARE	
		@IsOffer_YeeBet				INT = 0
	,	@IsOffer_PPLive				INT = 0
	,	@IsOffer_ION				INT = 0
	,	@IsOffer_BBIN				INT = 0
	,	@IsOffer_FGG				INT = 0
	,	@IsOffer_IBCBetLiveCasino		INT = 0
	,	@IsOffer_AllBet				INT = 0	
	--,	@IsOffer_WeLiveCasino			INT = 0
	,	@IsOffer_WM					INT = 0
	,	@IsOffer_BG					INT = 0
	,	@IsOffer_SexyGaming			INT = 0
	,	@IsOffer_SAGaming				INT = 0
	--,	@IsOffer_SabaxD				INT = 0
	
	
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 159, @Bettype = 3151, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_YeeBet OUT--
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 170, @Bettype = 3701, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_PPLive OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 225, @Bettype = 5601, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_ION OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 241, @Bettype = 3300, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_BBIN OUT--
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 176, @Bettype = 8201, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_FGG OUT--
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 242, @Bettype = 3201, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_IBCBetLiveCasino OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 211, @Bettype = 2401, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_AllBet OUT--
	--EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 228, @Bettype = 10300, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_WeLiveCasino OUT--
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 233, @Bettype = 3401, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_WM OUT	--
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 239, @Bettype = 3501, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_BG OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 243, @Bettype = 3101, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_SexyGaming OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 244, @Bettype = 3001, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_SAGaming OUT--
	--EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 240, @Bettype = 10801, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_SabaxD OUT--
	

	-- RealSports of dummy product 53: RNG Casino
	DECLARE
		@IsOffer_SabaGames			INT = 0
	,	@IsOffer_SabaCasino			INT = 0
	,	@IsOffer_VirtualGames			INT = 0
	,	@IsOffer_Vgaming				INT = 0
	,	@IsOffer_FunkyGames			INT = 0

	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 200, @Bettype = 1611, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_SabaGames OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 208, @Bettype = 2101, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_SabaCasino OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 245, @Bettype = 4601, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_VirtualGames OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 171, @Bettype = 3801, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_Vgaming OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 224, @Bettype = 5500, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_FunkyGames OUT


	-- RealSports of dummy product 44: RNG Games
	DECLARE
		@IsOffer_SportsLottery			INT = 0
	,	@IsOffer_VirtualSport			INT = 0
	,	@IsOffer_NumberGame			INT = 0

	,	@IsOffer_TableGames			INT = 0
	,	@IsOffer_Lottery				INT = 0
	,	@IsOffer_RNGKeno				INT = 0

	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 169, @Bettype = 3611, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_SportsLottery OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 9908, @Bettype = 1201, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_VirtualSport OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 161, @Bettype = 81, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_NumberGame OUT

	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 222, @Bettype = 4901, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_TableGames OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 220, @Bettype = 1024, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_Lottery OUT
	EXEC [Acc_GetSportOfferStatusBySiteCurrency] @SiteID = @SiteID, @Currency = @Currency, @Sporttype = 202, @Bettype = 1501, @SettingStatus = @SettingStatus, @IsHidden = @IsOffer_RNGKeno OUT


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

	-- Data Result:
	SELECT	
		ISNULL(cps.reject,0) AS Suspend,
		ISNULL(cps.closed,0) AS Closed,
		ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,cps.CloseInfo)),0) as isDirectClosed,
		CASE WHEN @IsDeposit=1 THEN 1 ELSE ISNULL(@ClosedReason,0) END AS ClosedReason, 
		ISNULL(autosuspend,0) AS AutoSuspend,	
		ISNULL(cm.DisableAutoMPT ,0) As DisableAutoMPT,	
		ISNULL(DisableOutright,0) AS DisableOutright,
		ISNULL(srecommend, 0) AS SRecommend,
		ISNULL(mrecommend, 0) AS MRecommend,
		ISNULL(recommend, 0) AS ARecommend,
		ISNULL(@IsAdminCanViewVNIP,1) AS IsAdminCanViewVNIP,
		ISNULL(DoubleCommLosing,0) AS DoubleCommLosing,				
		ISNULL(DisableSuperLive,1) AS DisableSuperLive,
		ISNULL(@IsAllDayBalTransfer, 0) IsAllDayBalTransfer,
		@LimitPerIP AS LimitPerIP,
		@SelectedBetting AS SelectedBetting,
		@IsInternal AS IsInternal, 
		cps.Locked,
		@SpecialPlatform AS SpecialPlatform,

		-- GroupID = 2: Result data of dummy product 44: RNG Games

		-- SportsLottery
		@Disable_SportsLottery									AS DisableSportsLottery,		
		@Hide_SportsLottery									AS HideSportsLottery,	
		@Sync_SportsLottery									AS SyncedSportsLottery,

		-- Virtual Sports
		@Disable_VirtualSports									AS DisableVirtualSports,		
		@Hide_VirtualSports									AS HideVirtualSports,	
		--@Sync_VirtualSports									AS SyncedVirtualSports,

		-- Number Game
		@Disable_NumberGame									AS DisableNumberGame,		
		@Hide_NumberGame										AS HideNumberGame,	
		@Sync_NumberGame										AS SyncedNumberGame,

		-- RNG Keno , Lottery, Table Games: Is Follow RNGGames
		-- RNG Keno
		CAST(CASE WHEN @IsOffer_RNGKeno = 0 AND @IsHidden_RNGGames = 0 AND @Disable_RNGGames = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableRNGKeno,		
		CAST(CASE WHEN @IsOffer_RNGKeno = 0 AND @IsHidden_RNGGames = 0 AND @Hide_RNGGames = 0 THEN 0 ELSE 1 END AS BIT)					AS HideRNGKeno,	
		CAST(CASE WHEN @IsOffer_RNGKeno = 0 AND @IsHidden_RNGGames = 0 AND @Sync_RNGGames = 1 THEN 1 ELSE 0 END AS BIT)					AS SyncedRNGKeno,

		-- Lottery
		CAST(CASE WHEN @IsOffer_Lottery = 0 AND @IsHidden_RNGGames = 0 AND @Disable_RNGGames = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableLottery,		
		CAST(CASE WHEN @IsOffer_Lottery = 0 AND @IsHidden_RNGGames = 0 AND @Hide_RNGGames = 0 THEN 0 ELSE 1 END AS BIT)					AS HideLottery,	
		CAST(CASE WHEN @IsOffer_Lottery = 0 AND @IsHidden_RNGGames = 0 AND @Sync_RNGGames = 1 THEN 1 ELSE 0 END AS BIT)					AS SyncedLottery,

		-- Table Games 
		CAST(CASE WHEN @IsOffer_TableGames = 0 AND @IsHidden_RNGGames = 0 AND @Disable_RNGGames = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableTableGames,		
		CAST(CASE WHEN @IsOffer_TableGames = 0 AND @IsHidden_RNGGames = 0 AND @Hide_RNGGames = 0 THEN 0 ELSE 1 END AS BIT)				AS HideTableGames,	
		CAST(CASE WHEN @IsOffer_TableGames = 0 AND @IsHidden_RNGGames = 0 AND @Sync_RNGGames = 1 THEN 1 ELSE 0 END AS BIT)				AS SyncedTableGames,

		-- GroupID = 3: Result data of dummy product 41: Live Casino
		-- YeeBet				
		CAST(CASE WHEN @IsOffer_YeeBet = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableYeeBet,
		CAST(CASE WHEN @IsOffer_YeeBet = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HideYeeBet,	
		CAST(CASE WHEN @IsOffer_YeeBet = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)				AS SyncedYeeBet,

		-- PPLive	
		CAST(CASE WHEN @IsOffer_PPLive = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisablePPLive,
		CAST(CASE WHEN @IsOffer_PPLive = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HidePPLive,	
		CAST(CASE WHEN @IsOffer_PPLive = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)				AS SyncedPPLive,

		-- ION				
		CAST(CASE WHEN @IsOffer_ION = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableION,
		CAST(CASE WHEN @IsOffer_ION = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS HideION,	
		CAST(CASE WHEN @IsOffer_ION = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)					AS SyncedION,

		-- BBIN		
		CAST(CASE WHEN @IsOffer_BBIN = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableBBIN,
		CAST(CASE WHEN @IsOffer_BBIN = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS HideBBIN,	
		CAST(CASE WHEN @IsOffer_BBIN = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)					AS SyncedBBIN,

		-- FGG				
		CAST(CASE WHEN @IsOffer_FGG = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableFGG,
		CAST(CASE WHEN @IsOffer_FGG = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS HideFGG,	

		-- IBCBetLiveCasino		
		CAST(CASE WHEN @IsOffer_IBCBetLiveCasino = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)		AS DisableIBCBetLiveCasino,
		CAST(CASE WHEN @IsOffer_IBCBetLiveCasino = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)			AS HideIBCBetLiveCasino,	
		CAST(CASE WHEN @IsOffer_IBCBetLiveCasino = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)			AS SyncedIBCBetLiveCasino,

		-- AllBet					
		CAST(CASE WHEN @IsOffer_AllBet = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableAllbet,
		CAST(CASE WHEN @IsOffer_AllBet = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HideAllbet,	
		CAST(CASE WHEN @IsOffer_AllBet = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)				AS SyncedAllbet,

		-- WeLiveCasino			
		--CAST(CASE WHEN @IsOffer_WeLiveCasino = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)			AS DisableWeLiveCasino,
		--CAST(CASE WHEN @IsOffer_WeLiveCasino = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)			AS HideWeLiveCasino,	
		--CAST(CASE WHEN @IsOffer_WeLiveCasino = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)			AS SyncedWeLiveCasino,

		-- WM					
		CAST(CASE WHEN @IsOffer_WM = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS DisableWM,
		CAST(CASE WHEN @IsOffer_WM = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS HideWM,	
		CAST(CASE WHEN @IsOffer_WM = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)					AS SyncedWM,

		-- BG					
		CAST(CASE WHEN @IsOffer_BG = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS DisableBG,
		CAST(CASE WHEN @IsOffer_BG = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)					AS HideBG,	
		CAST(CASE WHEN @IsOffer_BG = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)					AS SyncedBG,

		-- SexyGaming			
		CAST(CASE WHEN @IsOffer_SexyGaming = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)			AS DisableSexyGaming,
		CAST(CASE WHEN @IsOffer_SexyGaming = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HideSexyGaming,	
		CAST(CASE WHEN @IsOffer_SexyGaming = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)				AS SyncedSexyGaming,

		-- SAGaming	
		CAST(CASE WHEN @IsOffer_SAGaming = 0 AND @IsHidden_LiveCasino = 0 AND @Disable_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableSAGaming,
		CAST(CASE WHEN @IsOffer_SAGaming = 0 AND @IsHidden_LiveCasino = 0 AND @Hide_LiveCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HideSAGaming,	
		CAST(CASE WHEN @IsOffer_SAGaming = 0 AND @IsHidden_LiveCasino = 0 AND @Sync_LiveCasino = 1 THEN 1 ELSE 0 END AS BIT)				AS SyncedSAGaming,	
		
		-- GroupID = 3: Result data of dummy product 53: RNG Casino 
		-- SabaxD		
		--CAST(CASE WHEN @IsOffer_SabaxD = 0 AND @IsHidden_RNGCasino = 0 AND @Disable_RNGCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableSabaxD,
		--CAST(CASE WHEN @IsOffer_SabaxD = 0 AND @IsHidden_RNGCasino = 0 AND @Hide_RNGCasino = 0    THEN 0 ELSE 1 END AS BIT)				AS HideSabaxD,
		--CAST(CASE WHEN @IsOffer_SabaxD = 0 AND @IsHidden_RNGCasino = 0 AND @Sync_RNGCasino = 1    THEN 1 ELSE 0 END AS BIT)				AS SyncedSabaxD,

		-- Funky Games
		CAST(CASE WHEN @IsOffer_FunkyGames = 0 AND @IsHidden_RNGCasino = 0 AND @Disable_RNGCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableFunkyGames,
		CAST(CASE WHEN @IsOffer_FunkyGames = 0 AND @IsHidden_RNGCasino = 0 AND @Hide_RNGCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HideFunkyGames,
		CAST(CASE WHEN @IsOffer_FunkyGames = 0 AND @IsHidden_RNGCasino = 0 AND @Sync_RNGCasino = 1    THEN 1 ELSE 0 END AS BIT)				AS SyncedFunkyGames,

		-- Saba Games
		CAST(CASE WHEN @IsOffer_SabaGames = 0 AND @IsHidden_RNGCasino = 0 AND @Disable_RNGCasino = 0  THEN 0 ELSE 1 END AS BIT)				AS DisableSabaGames,
		CAST(CASE WHEN @IsOffer_SabaGames = 0 AND @IsHidden_RNGCasino = 0 AND @Hide_RNGCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS HideSabaGames,

		-- Saba Casino
		CAST(CASE WHEN @IsOffer_SabaCasino = 0 AND @IsHidden_RNGCasino = 0 AND @Disable_RNGCasino = 0 THEN 0 ELSE 1 END AS BIT)				AS DisableSabaCasino,
		CAST(CASE WHEN @IsOffer_SabaCasino = 0 AND @IsHidden_RNGCasino = 0 AND @Hide_RNGCasino = 0    THEN 0 ELSE 1 END AS BIT)				AS HideSabaCasino,
		CAST(CASE WHEN @IsOffer_SabaCasino = 0 AND @IsHidden_RNGCasino = 0 AND @Sync_RNGCasino = 1    THEN 1 ELSE 0 END AS BIT)				AS SyncedSabaCasino,
		
		-- Virtual Games
		CAST(CASE WHEN @IsOffer_VirtualGames = 0 AND @IsHidden_RNGCasino = 0 AND @Disable_RNGCasino = 0 THEN 0 ELSE 1 END AS BIT)			AS DisableVirtualGames,
		CAST(CASE WHEN @IsOffer_VirtualGames = 0 AND @IsHidden_RNGCasino = 0 AND @Hide_RNGCasino = 0    THEN 0 ELSE 1 END AS BIT)			AS HideVirtualGames,

		-- Vgaming
		CAST(CASE WHEN @IsOffer_Vgaming = 0 AND @IsHidden_RNGCasino = 0 AND @Disable_RNGCasino = 0      THEN 0 ELSE 1 END AS BIT)			AS DisableVGaming,
		CAST(CASE WHEN @IsOffer_Vgaming = 0 AND @IsHidden_RNGCasino = 0 AND @Hide_RNGCasino = 0         THEN 0 ELSE 1 END AS BIT)			AS HideVGaming,
		

		-- Don't Changed
		-- SabaVirtualSport
		ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SabaVirtualSport)),1)				AS DisableSabaVirtualSport,
		CAST(CASE WHEN ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SabaVirtualSport)),1) = 0 
																				THEN 0 ELSE 1 END AS BIT)	AS HideSabaVirtualSport,
		
		-- Cashout
		ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_CashOut)), 1)					AS DisableCashout,		
		CAST(CASE WHEN @IsHidden_Cashout = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_CashOut)), 1) = 0 
																				THEN 0 ELSE 1 END AS BIT)	AS HideCashout
			
	FROM custinfo AS ci WITH (NOLOCK)
	LEFT JOIN CustMaster AS cm WITH (NOLOCK) ON ci.CustID = cm.custid
	OUTER APPLY  (SELECT 
				  CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
				, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
				, ISNULL(Locked,0) Locked
				, bitmapIsHidden
				, bitmapIsDisabled
				, bitmapHasSynced
				, CloseInfo
			FROM dbo.CustProductStatus  WITH(NOLOCK)
			WHERE CustID = ci.custid
						) AS cps
		
	WHERE ci.CustID = @CustID
	GROUP BY
			cps.reject,
			cps.closed,
			cps.Locked,
			cps.CloseInfo,
			ci.autosuspend,
			cm.DisableAutoMPT,	
			ci.DisableOutright, 
		
			ci.srecommend, 
			ci.mrecommend, 
			ci.recommend, 
			ci.DoubleCommLosing,
			
			cps.bitmapIsDisabled,
			cps.bitmapIsHidden,
			cps.bitmapHasSynced,
			ci.DisableSuperLive


END

GO