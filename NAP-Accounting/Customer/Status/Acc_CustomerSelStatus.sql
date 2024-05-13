/*<info serverAlias="DBCUST-CustDB,DBACC-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelStatus]
	@CustID		INT,
	@AdminID	INT			= 0,
	@system		VARCHAR(30)	='NAP',
	@username	VARCHAR(50)	= '',
	@SettingStatus TINYINT = 0
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
	Param's Explanation:
		- @system: = NAP : internal login from NAP
					NAPEXT:internal login from NAP EXT
		- @CustID: customer id.  
		- @SettingStatus: 0: Pro, 1: UAT
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @agentid INT, @roleid TINYINT, @IsInternal BIT, @IsAdminCanViewVNIP BIT,  @LimitPerIP tinyint, @SelectedBetting bit
			,@IsMyanmarOdds BIT = 0
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
		-- Myanmar Odds
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@custid)		
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
		-- Myanmar Odds
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend)
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
		-- Myanmar Odds
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend)	
			
	END
	ELSE IF @roleid = 1 --member
	BEGIN
		SELECT 
			@IsInternal = isnull(IsInternal, 0) 
		FROM custAgent WITH (NOLOCK) WHERE custid = @agentid
		-- Myanmar Odds
		SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend)		
			
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
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_VS				INT
		,	@bitmapOrder_TableGames		INT 
		,	@bitmapOrder_SabaVirtualSport INT
		,	@bitmapOrder_SportsLottery	INT
		,	@bitmapOrder_Bitcoin		INT  
		,	@bitmapOrder_CashOut		INT  
		,   @bitmapOrder_Keno			INT 
		,   @bitmapOrder_NG				INT 
		

    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)    
	SET @bitmapOrder_Esports = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 43 AND Bettype = 1)    
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1024)
      SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9908 AND Bettype = 1201)
      SET @bitmapOrder_TableGames = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 222 AND Bettype = 4901)
	SET @bitmapOrder_SportsLottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 169 AND Bettype = 3611)		
	SET @bitmapOrder_SabaVirtualSport = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 98 AND Bettype = 1)
	SET @bitmapOrder_Bitcoin = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 175 AND Bettype = 7901)
	SET @bitmapOrder_CashOut = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 9903 AND Bettype = 1)
	SET @bitmapOrder_Keno = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 202 AND Bettype = 1501)
	SET @bitmapOrder_NG = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 161 AND Bettype = 81)
	

	DECLARE	@IsHidden_MuayThai		INT = 1
		--,	@IsHidden_Esports		INT = 1
		,	@IsHidden_Lottery		INT = 1
		,	@IsHidden_VS			INT = 1
		,	@IsHidden_TableGames	INT = 1
		,	@IsHidden_SabaVirtualSport	INT = 1
		,	@IsHidden_SportsLottery		INT = 1
		,	@IsHidden_Bitcoin		INT = 1
		,	@IsHidden_Cashout		INT = 1
		,	@IsHidden_Keno	INT = 1
		,	@IsHidden_NG	INT = 1

	DECLARE @SiteID INT , @Currency INT, @SpecialPlatform TINYINT

	SELECT @Currency = ci.currency, @SiteID = s.siteid, @SpecialPlatform = ISNULL(SpecialPlatfrom,0)
	FROM customer ci WITH(NOLOCK) 
		INNER JOIN Site s WITH(NOLOCK) ON ci.site = s.site
	WHERE ci.custid = @CustID
	
	EXEC Acc_CheckShowProduct @ProductID = 16, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_MuayThai OUTPUT	
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 220, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5, @SettingStatus = @SettingStatus,  @IsHide = @IsHidden_VS OUTPUT
	--EXEC Acc_CheckShowProduct @ProductID = 16, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_Esports OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 222, @IsHide = @IsHidden_TableGames OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 54, @SettingStatus = @SettingStatus, @Sporttype = 98, @IsHide = @IsHidden_SabaVirtualSport OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 169, @IsHide = @IsHidden_SportsLottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 69, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_Bitcoin OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 25, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_Cashout OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 202, @IsHide = @IsHidden_Keno OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 161, @IsHide = @IsHidden_NG OUTPUT
				
	--Handle dummy product 44: RNG Lottery (Lottery + TableGame + RNGWar)
	DECLARE	@DisableLottery			BIT,
			@HideLottery			BIT,
			@SyncedLottery			BIT = 1, --always sync
			@DisableTableGames		BIT,
			@HideTableGames			BIT,
			@SyncedTableGames		BIT = 1, --always sync
			@DisableSportsLottery	BIT,
			@HideSportsLottery    	BIT,
			@SyncedSportsLottery 	BIT = 1, --always sync,
			@DisableKeno			BIT,
			@HideKeno				BIT,
			@SyncKeno				BIT = 1,
			@DisableNG				BIT,
			@HideNG					BIT,
			@SyncNG					BIT = 1

	SELECT 			
	-- For Lottery
		@DisableLottery = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lottery)), 1),	
		@HideLottery  = CAST(CASE WHEN @IsHidden_Lottery = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lottery)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For TableGames
		@DisableTableGames = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_TableGames)), 1),	
		@HideTableGames  = CAST(CASE WHEN @IsHidden_TableGames = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_TableGames)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For Sports Lottery
		@DisableSportsLottery  = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SportsLottery)), 1),	
		@HideSportsLottery   = CAST(CASE WHEN @IsHidden_SportsLottery  = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SportsLottery)), 1) = 0 THEN 0 ELSE 1 END AS BIT),	
	-- For NG
		@DisableNG = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_NG)), 1),		
		@HideNG = CAST(CASE WHEN @IsHidden_NG = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_NG)), 1) = 0 THEN 0 ELSE 1 END AS BIT),
	-- For Keno
		@DisableKeno = ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Keno)), 1),		
		@HideKeno = CAST(CASE WHEN @IsHidden_Keno = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Keno)), 1) = 0 THEN 0 ELSE 1 END AS BIT)
		
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
	SELECT	ISNULL(cps.reject,0) AS Suspend,
			ISNULL(cps.closed,0) As Closed,
			ISNULL((SELECT suspendinfo FROM dbo.f_GetSuspendInfoStatus(@roleid,cps.CloseInfo)),0) as isDirectClosed,
			ISNULL(autosuspend,0) As AutoSuspend,	
			ISNULL(cm.DisableAutoMPT ,0) As DisableAutoMPT,	
			ISNULL(DisableOutright,0) AS DisableOutright,
			ISNULL(srecommend, 0) AS SRecommend,
			ISNULL(mrecommend, 0) AS MRecommend,
			ISNULL(recommend, 0) as ARecommend,
			ISNULL(@IsAdminCanViewVNIP,1) AS IsAdminCanViewVNIP,
			@LimitPerIP as LimitPerIP,
			@SelectedBetting as SelectedBetting,
			@IsInternal AS IsInternal,
			ISNULL(DoubleCommLosing,0) as DoubleCommLosing,		
			ISNULL(@IsMyanmarOdds,0) AS IsMyanmarOdds,
			ISNULL(DisableSuperLive,1) as DisableSuperLive,
			
			-- For RNGLottery (Lottery+ TableGames + RNGWar)
			CAST(CASE WHEN @DisableLottery = 0 OR @DisableTableGames= 0 THEN 0 ELSE 1 END AS BIT)AS DisableRNGLottery,		
			CAST(CASE WHEN @HideLottery = 0 OR @HideTableGames = 0 THEN 0 ELSE 1 END AS BIT) AS HideRNGLottery,	
			CAST( CASE WHEN @SyncedLottery = 1 OR @SyncedTableGames = 1 THEN 1 ELSE 0 END AS BIT) AS SyncedRNGLottery,
		
			--For Lottery
			@DisableLottery AS DisableLottery,
			@HideLottery AS HideLottery,
			@SyncedLottery AS SyncedLottery,

			--For TableGames
			@DisableTableGames AS DisableTableGames,
			@HideTableGames AS HideTableGames,
			@SyncedTableGames AS SyncedTableGames,
	
			CASE WHEN @IsDeposit=1 THEN 1 ELSE ISNULL(@ClosedReason,0) END AS ClosedReason,
			ISNULL(@IsAllDayBalTransfer, 0) IsAllDayBalTransfer,

			-- For VS
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VS)), 1) AS DisableVirtualSports,		
			CAST(CASE WHEN @IsHidden_VS = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VS)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,
			
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SabaVirtualSport)),1) AS DisableSabaVirtualSport,
			CAST(CASE WHEN ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SabaVirtualSport)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideSabaVirtualSport,
			--For RNGWar
			@DisableSportsLottery AS DisableSportsLottery,
			@HideSportsLottery AS HideSportsLottery,
			@SyncedSportsLottery AS SyncedSportsLottery,
			--For Bitcoin
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Bitcoin)), 1) AS DisableBitcoin,		
			CAST(CASE WHEN @IsHidden_Bitcoin = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Bitcoin)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBitcoin,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_Bitcoin)), 0) AS SyncedBitcoin,
			--For Cashout
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_CashOut)), 1) AS DisableCashout,		
			CAST(CASE WHEN @IsHidden_Cashout = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_CashOut)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCashout,
			cps.Locked,
			@DisableNG AS DisableNG,
			@HideNG AS HideNG,
			@SyncNG AS SyncedNG,
			@DisableKeno AS DisableKeno,
			@HideKeno AS HideKeno,
			@SyncKeno AS SyncedKeno,
			@SpecialPlatform SpecialPlatform
	FROM custinfo AS ci WITH (nolock)
		LEFT JOIN CustMaster AS cm WITH (NOLOCK) ON ci.CustID = cm.custid
		OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
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