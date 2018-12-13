/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="bodbExtAccNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelByMAg] 
    @MRecommend INT
  , @Custid     INT = NULL
  , @Enabled    BIT = NULL
  , @Closed     BIT = NULL
  , @Suspended  BIT = NULL
  , @UserID		INT = NULL
 
AS  
/*  
Created by: Scott  
Date: 2012-12-17  
Task : Customer list by MASTER
DB: DBCUST/CustDB
Original SP: Acc_CustomerSelByMAg
Revisions:  
	- 20130121@Dan: Move sp from DB053/bodb02 to DBEAS/bodb_EAS
	- 20130517@Lukas: 
			fix bug - wrong comm rate 
			add filter to reduce workload
	- 20131023@Elodie: Get more field HideVirtualSports, DisableCasinoBonus, DisableHRFixedOdds			
	- 20140120@Elodie: Hot fix to get information of disabled customer
	- 20140626@Logan: 1.Add Keno status [Redmine: #18268]
	                  2.Code aligning
    - 20140822@Logan:   Add Esports status [Redmine: #20666]
    - 20150514@Kathy: Add Gold Deluxe product [Redmine:#34486] 
    - 20150612@Kathy: Move sp from DBEAS.bodb_EAS to DBCUST.CustDB, use temp GameType [Redmine:#36216]
    - 20150825@Helen: Colossus Bet - [Redmine: #41264]
    - 20150904@Helen: commission setting for MO [Redmine #41470]
    - 20151019@Helen: Display wrong comm rate of Group A,B,C,D [Redmine: #45851]
    - 20151028@Helen: Member Information to support Muay Thai  [Redmine: #45496]
	- 20151209@Helen: Member information for Cockfighting [Redmine: #48133]
	- 20160114@Helen: Cricket - [Redmine: #50027]
	- 20160127@Billy: Member information for AllBet - [Redmine: #51713]
	- 20160411@Winnie: VoidBridge - [Redmine: #55546]
	- 20160606@Elodie: Hot fix to order list customer [Redmine: #58862]
	- 20160624@Winnie: Enhance Performance for Customer List SPs [Redmine: #59854]
	- 20160801@Elodie: NG2 Product - [Redmine: #60809]
	- 20160907@Elodie: Apply User Control permission of View/Access Special Site [Redmine: #63012]
	- 20160810@Winnie: #61733 Allbet VIP Barcarat
	- 20170120@Elodie: Don't offer Massac(1507), Malta(1509) anymore [#70693]
	- 20161031@Winnie: FishingWorld - [Redmine: #65474]
	- 20160801@Elodie: Implementing NewProductStatus Plugin - [Redmine #70722]	
	- 20170417@Winnie: Change to call the sp Acc_CheckShowProduct- [Redmine #72336]	
	- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
	- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
	- 20170606@Winnie: Apply color for closed account  - [Redmine #74494]	
	- 20170629@Winnie: Offer Enable/Disable GoldDeluxe [RedmineID: #72957]
	- 20170828@Elodie: EXT - Support Security Code on Customer List - [Redmine: #81091]
	- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]
	- 20171027@Johnson: fix the unsynchronized setting, add SyncGDUpline [Redmine: #72973]
	- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
	- 20180830@Elodie: Add new bettype of Poker Games Product - [Redmine: #97675]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20180919@Winnie: Add new bettype of Esports Product - [Redmine: #101526]
exec EAS_CustomerSelByMAg @MRecommend=4797617,@Custid=default,@Enabled=default,@Closed=default,@Suspended=default    
    
*/
BEGIN
    SET NOCOUNT ON  

    DECLARE @TransferOption BIT, @IsInternalAdmin BIT = 0, @UplineHasSecurityCode BIT = 0, @HasSecurityCode BIT = 0
	DECLARE @IsMyanmarOdds BIT = 0
	
	DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)
	 
	 BEGIN TRY		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK)
	 END TRY
	 BEGIN CATCH		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
	 END CATCH
	 
    SELECT @TransferOption = CASE
                               WHEN TransferOption = 0 THEN 0
                               ELSE 1
                             END
    FROM dbo.custmaster WITH(NOLOCK)
    WHERE custid = @MRecommend

	EXEC dbo.Acc_CustomerIsInternalAdmin @Custid = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT

	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @MRecommend AND cl.SecurityCode IS NOT NULL)
		SELECT @UplineHasSecurityCode = 1
	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @Custid AND cl.SecurityCode IS NOT NULL)
		SELECT @HasSecurityCode = 1

	-- For DCS
    DECLARE	@bitmapOrder_MuayThai		INT 	
		,	@bitmapOrder_Esports		INT 	
		,	@bitmapOrder_Cricket		INT
		,	@IsIMBC						BIT = 0
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_AllBetVIP		INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_Lucky3			INT
		,	@bitmapOrder_FishingWorld	INT
		,	@bitmapOrder_VS				INT
		,	@bitmapOrder_BullFighting	INT
		,	@bitmapOrder_PokerGames1401	INT
		,	@bitmapOrder_PokerGames1402	INT
		,	@bitmapOrder_PokerGames1403	INT
		,	@bitmapOrder_PokerGames1404	INT
		,	@bitmapOrder_PokerGames1405	INT

    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)  
	SET @bitmapOrder_Esports = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 43 AND Bettype = 1)  
    SET @bitmapOrder_Cricket = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 50 AND Bettype = 501)
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1021)
    SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
	SET @bitmapOrder_Lucky3 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 160 AND Bettype = 1600)
    SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)
	SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 180 AND Bettype = 1201)
	SET @bitmapOrder_BullFighting = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 207 AND Bettype = 1004)

	SELECT	@bitmapOrder_AllBet =	(SELECT	psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE	psp.Sporttype = 211 AND	psp.Bettype = 2401)
    SELECT	@bitmapOrder_AllBetVIP = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 211 AND	psp.Bettype = 2402)
	SELECT	@bitmapOrder_PokerGames1401 = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 163 AND	psp.Bettype = 1401)
    SELECT	@bitmapOrder_PokerGames1402 = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 163 AND	psp.Bettype = 1402)
	SELECT	@bitmapOrder_PokerGames1403 = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 163 AND	psp.Bettype = 1403)
    SELECT	@bitmapOrder_PokerGames1404 = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 163 AND	psp.Bettype = 1404)
	SELECT	@bitmapOrder_PokerGames1405 = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 163 AND	psp.Bettype = 1405)
    
    DECLARE	@IsHidden_MuayThai		INT = 1	
		,	@IsHidden_Esports		INT = 1	
		,	@IsHidden_Cricket		INT = 1
		,	@IsHidden_AllBet		INT = 1
		,	@IsHidden_VoidBridge	INT = 1
		,	@IsHidden_Lottery		INT = 1
		,	@IsHidden_NG2			INT = 1
		,	@IsHidden_Lucky3		INT = 1    
		,	@IsHidden_FishingWorld	INT = 1
		,	@IsHidden_VS			INT = 1
		,	@IsHidden_BullFighting	INT = 1
		,	@IsHidden_PokerGames	INT = 1
		
   	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_MuayThai OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 20, @IsHide = @IsHidden_Cricket OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 21, @IsHide = @IsHidden_AllBet OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 22, @IsHide = @IsHidden_VoidBridge OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 28, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 23, @IsHide = @IsHidden_NG2 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 26, @IsHide = @IsHidden_Lucky3 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 24, @IsHide = @IsHidden_FishingWorld OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5, @IsHide = @IsHidden_VS OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 30, @IsHide = @IsHidden_BullFighting OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 33, @IsHide = @IsHidden_PokerGames OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_Esports OUTPUT

	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @MRecommend AND [Site] = 'IMBC')
		SET @IsIMBC = 1
			
	-- get data for filtered customers	
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)
	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
	
	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	SELECT siteid , site,SpecialGroup 
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser (@tmpUserid)

    SELECT cu.custid,
           cu.username,
           ci.enabled,
           ci.closed,
           ISNULL(ci.reject, 0) suspended,
           cu.roleid,
           ISNULL(cu.firstname, '') firstname,
           ISNULL(cu.lastname, '') lastname,
	       
	       MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupa else 0 end) as groupa,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupb else 0 end) as groupb,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupc else 0 end) as groupc,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupd else 0 end) as groupd,
	      
	       MAX(CASE
	             WHEN cs.bettype = 5 and cs.sporttype = 1 THEN cs.discount
	             ELSE 0
	           END) discount1x2,
	       MAX(CASE
	             WHEN cs.bettype = 4 and cs.sporttype = 1 THEN cs.discount
	             ELSE 0
	           END) discountcs,
	       MAX(CASE
	             WHEN cs3.bettype = 81 and cs3.sporttype = 161 THEN cs3.discount
	             ELSE 0
	           END) discountnumber,
	       cu.creatdate createdate,
	       ISNULL(cu.iplogin, '') lastloginip,
	       ci.DoubleCommLosing,
	       ISNULL(ci.DisableOutright, 0) DisableOutright,
	      
	       -- FOR casino
	       ci.synccasino,
	       ci.disablecasino,
	  
	       ci.DisableNumber,
	  
	       ci.DoubleCommLosing,
	      
	       -- FOR Esports
	       --ci.DisableEsports,

           ci.DisableCasinoBonus,
        
           -- FOR Keno
           ci.HideKeno,
           MIN(CASE WHEN g.IBCBetTypeID in (1501,1503,1504,1505,1508,1511,1513,1514,1515,1516) THEN cg.IsDisabled ELSE 1 END) DisableKeno,
	       ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		   ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		   ISNULL(ci.SyncGoldDeluxeUpline,1) AS SyncGoldDeluxeUpline,
		   
		   ISNULL(ci.DisableColossusBet,1) AS DisableColossusBet,
		   ISNULL(ci.HideColossusBet,1) AS HideColossusBet,
		   
		   ISNULL(ci.DisableMuayThai,1) AS DisableMuayThai,
		   ISNULL(ci.HideMuayThai,1) AS HideMuayThai,
		   ISNULL(ci.DisableEsports,1) AS DisableEsports,
		   ISNULL(ci.HideEsports,1) AS HideEsports,
		
		   ISNULL(ci.DisableAllBet,1) AS DisableAllBet,
		   ISNULL(ci.DisableAllBetVIP,1) AS DisableAllBetVIP,
		   ISNULL(ci.HideAllBet,1) AS HideAllBet,
		   ISNULL(ci.HideAllBetUpline,1) AS HideAllBetUpline,
		   ISNULL(ci.SyncedAllBet,1) AS SyncedAllBet,
		   ISNULL(ci.SyncedAllBetUpline,1) AS SyncedAllBetUpline,
		   ISNULL(ci.SyncedAllBetDownline,1) AS SyncedAllBetDownline,

		   ISNULL(ci.DisablePokerGames1401,1) AS DisablePokerGames1401,
		   ISNULL(ci.DisablePokerGames1402,1) AS DisablePokerGames1402,
		   ISNULL(ci.DisablePokerGames1403,1) AS DisablePokerGames1403,
		   ISNULL(ci.DisablePokerGames1404,1) AS DisablePokerGames1404,
		   ISNULL(ci.DisablePokerGames1405,1) AS DisablePokerGames1405,
		   ISNULL(ci.HidePokerGames,1) AS HidePokerGames,
		   ISNULL(ci.HidePokerGamesUpline,1) AS HidePokerGamesUpline,

		   ISNULL(ci.DisableVoidBridge,1) AS DisableVoidBridge,
		   ISNULL(ci.DisableVoidBridgeUpline,1) AS DisableVoidBridgeUpline,
		   ISNULL(ci.HideVoidBridge,1) AS HideVoidBridge,
		   ISNULL(ci.HideVoidBridgeUpline,1) AS HideVoidBridgeUpline,
		   ISNULL(ci.SyncedVoidBridge,1) AS SyncedVoidBridge,
		   ISNULL(ci.SyncedVoidBridgeUpline,1) AS SyncedVoidBridgeUpline,
		   ISNULL(ci.SyncedVoidBridgeDownline,1) AS SyncedVoidBridgeDownline,
		   
		   ISNULL(ci.DisableLottery,1) AS DisableLottery,
		   ISNULL(ci.DisableLotteryUpline,1) AS DisableLotteryUpline,
		   ISNULL(ci.HideLottery,1) AS HideLottery,
		   ISNULL(ci.HideLotteryUpline,1) AS HideLotteryUpline,

		   ISNULL(ci.DisableNG2,1) AS DisableNG2,
		   ISNULL(ci.DisableNG2Upline,1) AS DisableNG2Upline,
		   ISNULL(ci.HideNG2,1) AS HideNG2,
		   ISNULL(ci.HideNG2Upline,1) AS HideNG2Upline,
		   ISNULL(ci.SyncedNG2,1) AS SyncedNG2,
		   ISNULL(ci.SyncedNG2Upline,1) AS SyncedNG2Upline,

		   ISNULL(ci.DisableLucky3,1) AS DisableLucky3,
		   ISNULL(ci.DisableLucky3Upline,1) AS DisableLucky3Upline,
		   ISNULL(ci.HideLucky3,1) AS HideLucky3,
		   ISNULL(ci.HideLucky3Upline,1) AS HideLucky3Upline,

		   ISNULL(ci.DisableFishingWorld,1) AS DisableFishingWorld,
		   ISNULL(ci.DisableFishingWorldUpline,1) AS DisableFishingWorldUpline,
		   ISNULL(ci.HideFishingWorld,1) AS HideFishingWorld,
		   ISNULL(ci.HideFishingWorldUpline,1) AS HideFishingWorldUpline,
		   ISNULL(ci.SyncedFishingWorld,1) AS SyncedFishingWorld,
		   ISNULL(ci.SyncedFishingWorldUpline,1) AS SyncedFishingWorldUpline,
		   ISNULL(ci.SyncedFishingWorldDownline,1) AS SyncedFishingWorldDownline,		  		   
		   ISNULL(ci.SyncedGoldDeluxeDownline,0) AS SyncedGoldDeluxeDownline,
		   ISNULL(ci.DisableVirtualSports,1) AS DisableVirtualSports,
		   ISNULL(ci.DisableVirtualSportsUpline,1) AS DisableVirtualSportsUpline,
		   ISNULL(ci.HideVirtualSports,1) AS HideVirtualSports,
		   ISNULL(ci.HideVirtualSportsUpline,1) AS HideVirtualSportsUpline,
		   ISNULL(ci.DisableBullFighting,1) AS DisableBullFighting,
		   ISNULL(ci.DisableBullFightingUpline,1) AS DisableBullFightingUpline,
		   ISNULL(ci.HideBullFighting,1) AS HideBullFighting,
		   ISNULL(ci.HideBullFightingUpline,1) AS HideBullFightingUpline,
		   --For Myanmar Odds
		   CASE WHEN ac.CustId IS NOT NULL THEN 1 ELSE 0 END AS  IsMyanmarOdds,
		   ISNULL(AC.CommRate,0) AS discountMyanmarOdds,
	       --transfer condition
	       @TransferOption disableTransfer,
	       
			-- Cricket
			ISNULL(@IsIMBC,0) AS IsIMBC,
			ISNULL(ci.DisableCricket,1) AS DisableCricket,
			ISNULL(ci.HideCricket,1) AS HideCricket,
			ISNULL(cdm.Discount,0) AS discountCricket,
			ISNULL(cl.ClosedReason,0) AS ClosedReason,
			@UplineHasSecurityCode AS UplineHasSecurityCode,
			@HasSecurityCode AS HasSecurityCode,
			ROW_NUMBER() OVER(ORDER BY ci.enabled desc, ci.closed, ISNULL(ci.reject, 0), cu.username) RowNumber
      FROM dbo.customer cu WITH(NOLOCK)
		INNER JOIN (SELECT custinfo.custid, custInfo.currency, roleid, autosuspend, reject, closed,
							MatchLimit, VirtualMultiplier, Enabled, 
							DisableCasino, SyncCasino, DisableOutright,
							DisableNumber,		
						
							DoubleCommLosing, DisableCasinoBonus, 
							HideKeno, 
							--DisableEsports,
							DisableGoldDeluxe, HideGoldDeluxe, DisableColossusBet,HideColossusBet,
							(SELECT CASE WHEN HideGoldDeluxe = 0 THEN 1 ELSE 0 END 
							FROM dbo.Custinfo WITH(NOLOCK) WHERE custid = @mrecommend) as SyncGoldDeluxeUpline,
							-- For MuayThai
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_MuayThai)) AS DisableMuayThai,
							CAST(CASE WHEN @IsHidden_MuayThai = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_MuayThai)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideMuayThai,
							-- For Esports
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Esports)) AS DisableEsports,
							CAST(CASE WHEN @IsHidden_Esports = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Esports)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideEsports,
							-- For AllBet
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_AllBet)) AS DisableAllBet,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_AllBetVIP)) AS DisableAllBetVIP,
							CAST(	CASE	WHEN	@IsHidden_AllBet = 0 
												--AND	sbhsc.IsHidden = 0
												AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_AllBet)) = 0 
												THEN 0
											ELSE 1 
									END AS BIT) AS HideAllBet,
							CAST(	CASE	WHEN	@IsHidden_AllBet = 0 
											--AND	sbhsc.IsHidden = 0
											AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_AllBet)) = 0 
											THEN 0
										ELSE 1 
								END AS BIT) AS HideAllBetUpline,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_AllBet)) AS SyncedAllBet,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_AllBet)) AS SyncedAllBetUpline,
							CASE	WHEN EXISTS	(	SELECT	1
													FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
													INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
															ON	ciDownline.custid = cpsDownline.CustID
													WHERE	ciDownline.recommend = custInfo.custid
														AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_AllBet)) = 0)
										THEN 0
									ELSE 1

							END AS SyncedAllBetDownline,

							-- For Poker Games
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_PokerGames1401)) AS DisablePokerGames1401,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_PokerGames1402)) AS DisablePokerGames1402,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_PokerGames1403)) AS DisablePokerGames1403,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_PokerGames1404)) AS DisablePokerGames1404,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_PokerGames1405)) AS DisablePokerGames1405,
							CAST(CASE WHEN @IsHidden_PokerGames = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_PokerGames1401), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HidePokerGames,
							CAST(CASE WHEN @IsHidden_PokerGames = 0 AND ISNULL(dbo.f_GetProductStatus(cpsUpline.bitmapIsHidden, @bitmapOrder_PokerGames1401), 1)=0 THEN 0 ELSE 1 END AS BIT) AS HidePokerGamesUpline,

							-- For VoidBridge
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge)) AS DisableVoidBridge,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_VoidBridge)) AS DisableVoidBridgeUpline,
							CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VoidBridge)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
							CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_VoidBridge)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridgeUpline,						
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_VoidBridge)) AS SyncedVoidBridge,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_VoidBridge)) AS SyncedVoidBridgeUpline,
							CASE	WHEN EXISTS	(	SELECT	1
													FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
													INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
															ON	ciDownline.custid = cpsDownline.CustID
													WHERE	ciDownline.recommend = custInfo.custid
														AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_VoidBridge)) = 0)
										THEN 0
									ELSE 1
							END AS SyncedVoidBridgeDownline,
							-- For Lottery
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lottery)) AS DisableLottery,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_Lottery)) AS DisableLotteryUpline,
							CAST(CASE WHEN @IsHidden_Lottery = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lottery)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLottery,
							CAST(CASE WHEN @IsHidden_Lottery = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_Lottery)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLotteryUpline,						
							
							-- For NG2
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_NG2)) AS DisableNG2,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_NG2)) AS DisableNG2Upline,
							CAST(CASE WHEN @IsHidden_NG2 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_NG2)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
							CAST(CASE WHEN @IsHidden_NG2 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_NG2)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2Upline,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_NG2)) AS SyncedNG2,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_NG2)) AS SyncedNG2Upline,
							-- For Lucky3
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lucky3)) AS DisableLucky3,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_Lucky3)) AS DisableLucky3Upline,
							CAST(CASE WHEN @IsHidden_Lucky3 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lucky3)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLucky3,
							CAST(CASE WHEN @IsHidden_Lucky3 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_Lucky3)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLucky3Upline,						
							
							-- For FishingWorld
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld)) AS DisableFishingWorld,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_FishingWorld)) AS DisableFishingWorldUpline,
							CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_FishingWorld)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
							CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_FishingWorld)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorldUpline,						
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_FishingWorld)) AS SyncedFishingWorld,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_FishingWorld)) AS SyncedFishingWorldUpline,
							CASE	WHEN EXISTS	(	SELECT	1
													FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)

													INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
															ON	ciDownline.custid = cpsDownline.CustID
													WHERE	ciDownline.recommend = custInfo.custid
														AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_FishingWorld)) = 0)
										THEN 0
									ELSE 1
							END AS SyncedFishingWorldDownline,						
							-- GD
							CASE	WHEN EXISTS	(	SELECT	1
													FROM		dbo.custInfo AS ciDownline WITH (NOLOCK)											
													WHERE	ciDownline.recommend = custinfo.custid
															AND ISNULL(HideGoldDeluxe,1)=1)
										THEN 0
									ELSE 1
								END AS SyncedGoldDeluxeDownline,
							
							-- For VS
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VS)) AS DisableVirtualSports,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_VS)) AS DisableVirtualSportsUpline,
							CAST(CASE WHEN @IsHidden_VS = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VS)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,
							CAST(CASE WHEN @IsHidden_VS = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_VS)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSportsUpline,						
						
							-- For BullFighting
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_BullFighting)) AS DisableBullFighting,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsDisabled, @bitmapOrder_BullFighting)) AS DisableBullFightingUpline,
							CAST(CASE WHEN @IsHidden_BullFighting = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_BullFighting)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBullFighting,
							CAST(CASE WHEN @IsHidden_BullFighting = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_BullFighting)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBullFightingUpline,						
						
							-- For Cricket
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Cricket)) AS DisableCricket,
							CAST( CASE WHEN @IsIMBC = 1 AND @IsHidden_Cricket = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Cricket)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCricket
							
					  FROM dbo.custinfo WITH(NOLOCK) 						
					  LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = custinfo.custid  

						-- Check isHidden AllBet
						--OUTER APPLY	dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(custInfo.custid, @AllBet) AS sbhsc
		
						-- Upline Status
						INNER JOIN	dbo.CustProductStatus AS cpsUpline WITH (NOLOCK)
								ON	cpsUpline.CustID =	CASE	WHEN custInfo.roleid = 1 THEN custInfo.recommend
																WHEN custInfo.roleid = 2 THEN custInfo.mrecommend
																ELSE custInfo.srecommend
														END
		   
					 WHERE mRecommend = @MRecommend
					   AND roleid = 2
					   AND (@Custid IS NULL OR custinfo.Custid = @Custid)
					   AND enabled = CASE
									   WHEN COALESCE(@Closed, @Suspended) IS NOT NULL THEN 1
									   ELSE COALESCE(@enabled, enabled)
									 END
					   AND ISNULL(closed, 0) = CASE
												 WHEN @suspended = 1 THEN 0
												 ELSE COALESCE(@closed, ISNULL(closed, 0))
											   END
					   AND ISNULL(reject, 0) = CASE
												 WHEN @Closed = 0 THEN 0
												 ELSE COALESCE(@suspended, ISNULL(reject, 0))
											   END
				   ) ci ON cu.custid = ci.custid
		 LEFT JOIN dbo.CustSetting cs WITH(NOLOCK) ON cu.custid = cs.custid
		 LEFT JOIN dbo.custsetting3rd cs3 WITH(NOLOCK) ON cu.custid = cs3.custid
		 LEFT JOIN dbo.CustGameType cg WITH(NOLOCK) ON cu.custid = cg.CustID
		 LEFT JOIN @tmp_GameType g ON g.GameTypeID = cg.GameTypeID
													 AND g.IBCBetTypeID IN (1501,1503,1504,1505,1508,1511,1513,1514,1515,1516)
		INNER JOIN dbo.Custagent cm with(NOLOCK) ON cu.custid = cm.custid  
		LEFT JOIN AgentCommRate AC WITH (NOLOCK) ON AC.CustId = CI.custid AND AC.Sporttype = 1 AND AC.Bettype = 301 
		LEFT JOIN CustDiscount3rd_Agent cdm WITH (NOLOCK) ON cdm.CustID = ci.custid AND cdm.SportType = 50 AND cdm.BetType = 501 AND @IsIMBC = 1
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON cu.custid=cl.CustID
		
     WHERE ((cs.sporttype IN (1) AND cs.bettype IN (1, 5, 4) AND cs3.sporttype IN (161) AND cs3.bettype IN (81))
				OR (cs.sporttype IS NULL AND cs.bettype IS NULL AND cs3.sporttype IS NULL AND cs3.bettype IS NULL))
			AND (@IsInternalAdmin = 0 OR cu.site NOT IN (SELECT site FROM @tmp ))
	  GROUP BY cu.custid, cu.username, ci.enabled,ci.closed,ci.reject,cu.roleid,
			cu.firstname, cu.lastname,
			cu.creatdate ,cu.iplogin,ci.DoubleCommLosing,ci.DisableOutright,  	
			ci.synccasino,ci.disablecasino,  
			ci.DisableNumber,  
			ci.DoubleCommLosing, ci.DisableCasinoBonus, ci.HideKeno, 
			--ci.DisableEsports,
			ci.DisableGoldDeluxe, ci.HideGoldDeluxe, ci.SyncGoldDeluxeUpline, ci.DisableColossusBet, ci.HideColossusBet,AC.CommRate,ac.CustId,ci.DisableMuayThai,ci.HideMuayThai,
			ci.DisableAllBet,ci.DisableAllBetVIP, ci.HideAllBet,ci.HideAllBetUpline, ci.SyncedAllBet, ci.SyncedAllBetUpline, ci.SyncedAllBetDownline,
			ci.HideCricket,ci.DisableCricket,cdm.Discount,
			ci.DisableVoidBridge,ci.DisableVoidBridgeUpline, ci.HideVoidBridge, ci.HideVoidBridgeUpline, ci.SyncedVoidBridge, ci.SyncedVoidBridgeUpline, ci.SyncedVoidBridgeDownline,
			ci.DisableNG2,ci.DisableNG2Upline, ci.HideNG2, ci.HideNG2Upline, ci.SyncedNG2, ci.SyncedNG2Upline,
			ci.DisableFishingWorld,ci.DisableFishingWorldUpline, ci.HideFishingWorld, ci.HideFishingWorldUpline, ci.SyncedFishingWorld, ci.SyncedFishingWorldUpline, ci.SyncedFishingWorldDownline,cl.ClosedReason,
			ci.DisableLucky3,ci.DisableLucky3Upline, ci.HideLucky3, ci.HideLucky3Upline,
			ci.DisableVirtualSports,ci.HideVirtualSportsUpline,ci.HideVirtualSports, ci.DisableVirtualSportsUpline,
			ci.DisableLottery,ci.DisableLotteryUpline, ci.HideLottery, ci.HideLotteryUpline,
			ci.DisableBullFighting,ci.DisableBullFightingUpline, ci.HideBullFighting,ci.HideBullFightingUpline,
			ci.SyncedGoldDeluxeDownline,
			ci.DisablePokerGames1401,ci.DisablePokerGames1402, ci.DisablePokerGames1403, ci.DisablePokerGames1404, ci.DisablePokerGames1405, ci.HidePokerGames, ci.HidePokerGamesUpline
			,ci.DisableEsports,ci.HideEsports
	ORDER BY RowNumber
END
GO