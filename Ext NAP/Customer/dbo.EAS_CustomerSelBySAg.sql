/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelBySAg]  
    @SRecommend		int,  
    @Custid			int = null,  
    @Enabled		bit = null,  
    @Closed			bit = null,  
    @Suspended		bit = NULL, 
	@UserID			INT = NULL,
	@IsDataLimited	BIT	= 0
AS  
/*  
Created by: Scott  
Date: 2012-12-17  
Task : Customer list by super
DB: DBCUST/CustDB
Original SP: Acc_CustomerSelBySAg
Revisions:  
	- 20130121@Dan: Move sp from DB053/bodb02 to DBEAS/bodb_EAS
	- 20130517@Lukas: add filter to reduce workload
	- 20131023@Elodie: Get more field HideVirtualSports, DisableCasinoBonus, DisableHRFixedOdds
	- 20140120@Elodie: Hot fix to get information of disabled customer
	- 20140626@Logan:   1.Add Keno status [Redmine: #18268]
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
	- 20170606@Winnie: Apply color for closed account  - [Redmine #74494]	
	- 20170629@Winnie: Offer Enable/Disable GoldDeluxe [RedmineID: #72957]
	- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
	- 20170828@Elodie: EXT - Support Security Code on Customer List - [Redmine: #81091]
	- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]
	- 20171027@Johnson: fix the unsynchronized setting, add SyncGDUpline [Redmine: #72973]
	- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
	- 20180830@Elodie: Add new bettype of Poker Games Product - [Redmine: #97675]
	- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
	- 20180907@Winnie: EXT-Function to control data range for SMA - [Redmine: #100067]
	
exec EAS_CustomerSelBySAg @SRecommend=4792246,@Custid=default,@Enabled=default,@Closed=default,@Suspended=default
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
 
    SELECT @TransferOption = case
                               when TransferOption = 0 then 0
                               else 1
                             end,
           @IsMyanmarOdds = IsMyanmarOdds                  
     FROM dbo.custsuper WITH(NOLOCK)
     WHERE custid = @SRecommend
	 
	 EXEC dbo.Acc_CustomerIsInternalAdmin @Custid = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT

	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @SRecommend AND cl.SecurityCode IS NOT NULL)
		SELECT @UplineHasSecurityCode = 1
	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @Custid AND cl.SecurityCode IS NOT NULL)
		SELECT @HasSecurityCode = 1

	-- For DCS
    DECLARE	@bitmapOrder_MuayThai		INT 
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

	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @SRecommend AND [Site] = 'IMBC')
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
           isnull(ci.reject, 0) as suspended,
           cu.roleid,
           isnull(cu.firstname, '') as firstname,
           isnull(cu.lastname, '') as lastname,
	       
	       MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupa else 0 end) as groupa,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupb else 0 end) as groupb,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupc else 0 end) as groupc,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupd else 0 end) as groupd,
	       
	       max(case
	             when cs.bettype = 5 and cs.sporttype = 1 then cs.adiscount
	             else 0
	           end) as discount1x2,
	       max(case
	             when cs.bettype = 4 and cs.sporttype = 1 then cs.adiscount
	             else 0
	           end) as discountcs,   
	       max(case
	             when cs3.bettype = 81 and cs3.sporttype = 161 then cs3.adiscount
	             else 0
	           end) as discountnumber,
           cu.creatdate as createdate,
           isnull(cu.iplogin, '') as lastloginip,
	       ci.DoubleCommLosing,
	       isnull(ci.DisableOutright, 0) as DisableOutright,
	       isnull(cm.DisableAutoMPT, 0) as DisableAutoMPT,
	     
	       -- For casino
	       ci.synccasino,
	       ci.disablecasino,
	     
	       ci.DisableNumber,
	    
	       ci.DoubleCommLosing,
	       --ci.HideVirtualSports,
	       -- For Esports
	       ci.DisableEsports,
      
	       ci.DisableCasinoBonus,
	    
	       -- For Keno
	       ci.HideKeno,
	       MIN(case when g.IBCBetTypeID in (1501,1503,1504,1505,1508,1511,1513,1514,1515,1516) then cg.IsDisabled else 1 end) as DisableKeno,
	       ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		   ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		   ISNULL(ci.SyncGoldDeluxeUpline,1) AS SyncGoldDeluxeUpline,
		   
		   ISNULL(ci.DisableColossusBet,1) AS DisableColossusBet,
		   ISNULL(ci.HideColossusBet,1) AS HideColossusBet,
		   
		   ISNULL(ci.DisableMuayThai,1) AS DisableMuayThai,
		   ISNULL(ci.HideMuayThai,1) AS HideMuayThai,
		

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
		   ISNULL(ci.HideVoidBridgeUpline,1) AS HideVoidBridgeUpline,		  
		   ISNULL(ci.HideVoidBridge,1) AS HideVoidBridge,
		   ISNULL(ci.SyncedVoidBridge,1) AS SyncedVoidBridge,
		   ISNULL(ci.SyncedVoidBridgeUpline,1) AS SyncedVoidBridgeUpline,
		   ISNULL(ci.SyncedVoidBridgeDownline,1) AS SyncedVoidBridgeDownline,
		   
		   ISNULL(ci.DisableLottery,1) AS DisableLottery,
		   ISNULL(ci.HideLottery,1) AS HideLottery,
		   ISNULL(ci.HideLotteryUpline,1) AS HideLotteryUpline,

		   ISNULL(ci.DisableNG2,1) AS DisableNG2,
		   ISNULL(ci.HideNG2Upline,1) AS HideNG2Upline,		  
		   ISNULL(ci.HideNG2,1) AS HideNG2,
		   ISNULL(ci.SyncedNG2,1) AS SyncedNG2,
		   ISNULL(ci.SyncedNG2Upline,1) AS SyncedNG2Upline,

		   ISNULL(ci.DisableLucky3,1) AS DisableLucky3,
		   ISNULL(ci.HideLucky3,1) AS HideLucky3,
		   ISNULL(ci.HideLucky3Upline,1) AS HideLucky3Upline,

		   ISNULL(ci.DisableFishingWorld,1) AS DisableFishingWorld,
		   ISNULL(ci.HideFishingWorldUpline,1) AS HideFishingWorldUpline,		  
		   ISNULL(ci.HideFishingWorld,1) AS HideFishingWorld,
		   ISNULL(ci.SyncedFishingWorld,1) AS SyncedFishingWorld,
		   ISNULL(ci.SyncedFishingWorldUpline,1) AS SyncedFishingWorldUpline,
		   ISNULL(ci.SyncedFishingWorldDownline,1) AS SyncedFishingWorldDownline,
		   ISNULL(ci.SyncedGoldDeluxeDownline,0) AS SyncedGoldDeluxeDownline,
		   ISNULL(ci.DisableVirtualSports,1) AS DisableVirtualSports,
		   ISNULL(ci.HideVirtualSports,1) AS HideVirtualSports,
		   ISNULL(ci.HideVirtualSportsUpline,1) AS HideVirtualSportsUpline,
		   ISNULL(ci.DisableBullFighting,1) AS DisableBullFighting,
		   ISNULL(ci.HideBullFighting,1) AS HideBullFighting,
		   ISNULL(ci.HideBullFightingUpline,1) AS HideBullFightingUpline,

		   -- For Myanmar Odds
		   CASE WHEN ac.CustId IS NOT NULL THEN 1 ELSE 0 END AS IsMyanmarOdds,
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
	       ROW_NUMBER() OVER(ORDER BY ci.enabled desc, ci.closed,
	                                  isnull(ci.reject, 0), cu.username) as RowNumber
				                                  
	FROM dbo.customer AS cu with(NOLOCK)
		INNER JOIN (SELECT c.custid, c.currency, roleid, autosuspend, reject,
						closed, MatchLimit, VirtualMultiplier, Enabled, 
						DisableCasino, SyncCasino, DisableOutright, 
						DisableNumber, 
						DoubleCommLosing, DisableCasinoBonus,  HideKeno, DisableEsports, DisableGoldDeluxe, HideGoldDeluxe,DisableColossusBet,HideColossusBet,
						(SELECT CASE WHEN HideGoldDeluxe = 0 THEN 1 ELSE 0 END 
						FROM dbo.Custinfo WITH(NOLOCK) WHERE custid = @srecommend) as SyncGoldDeluxeUpline,
						-- For MuayThai						
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_MuayThai)) AS DisableMuayThai,
						CAST(CASE WHEN @IsHidden_MuayThai = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_MuayThai)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideMuayThai,
						
						-- For VoidBridge
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge)) AS DisableVoidBridge,
						CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VoidBridge)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
						CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_VoidBridge)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridgeUpline,						
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_VoidBridge)) AS SyncedVoidBridge,
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_VoidBridge)) AS SyncedVoidBridgeUpline,
							CASE	WHEN EXISTS	(	SELECT	1
													FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
													INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
															ON	ciDownline.custid = cpsDownline.CustID
													WHERE	ciDownline.mrecommend = c.custid
														AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_VoidBridge))=0)
										THEN 0
									ELSE 1
							END AS SyncedVoidBridgeDownline,

						-- For Lucky3
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lucky3)) AS DisableLucky3,						
						CAST(CASE WHEN @IsHidden_Lucky3 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lucky3)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLucky3,
						CAST(CASE WHEN @IsHidden_Lucky3 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_Lucky3)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLucky3Upline,												

						-- For FishingWorld
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld)) AS DisableFishingWorld,
						
						CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_FishingWorld)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
						CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_FishingWorld)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorldUpline,						
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_FishingWorld)) AS SyncedFishingWorld,
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_FishingWorld)) AS SyncedFishingWorldUpline,
							CASE	WHEN EXISTS	(	SELECT	1
													FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
													INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
															ON	ciDownline.custid = cpsDownline.CustID
													WHERE	ciDownline.mrecommend = c.custid
														AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_FishingWorld))=0)
										THEN 0
									ELSE 1
							END AS SyncedFishingWorldDownline,
						
						-- For Lottery
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lottery)) AS DisableLottery,
						CAST(CASE WHEN @IsHidden_Lottery = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lottery)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLottery,
						CAST(CASE WHEN @IsHidden_Lottery = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_Lottery)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLotteryUpline,						
						
						-- For NG2
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_NG2)) AS DisableNG2,
						CAST(CASE WHEN @IsHidden_NG2 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_NG2)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
						CAST(CASE WHEN @IsHidden_NG2 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_NG2)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2Upline,
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_NG2)) AS SyncedNG2,
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_NG2)) AS SyncedNG2Upline,

						-- For VS
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VS)) AS DisableVirtualSports,						
						CAST(CASE WHEN @IsHidden_VS = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VS)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,
						CAST(CASE WHEN @IsHidden_VS = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_VS)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSportsUpline,						

						-- For BullFighting
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_BullFighting)) AS DisableBullFighting,
						CAST(CASE WHEN @IsHidden_BullFighting = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_BullFighting)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBullFighting,
						CAST(CASE WHEN @IsHidden_BullFighting = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapIsHidden, @bitmapOrder_BullFighting)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBullFightingUpline,

						-- For AllBet
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_AllBet)) AS DisableAllBet,
							(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_AllBetVIP)) AS DisableAllBetVIP,
						CAST(	CASE	WHEN	@IsHidden_AllBet = 0 
											AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_AllBet)) = 0
											THEN 0
										ELSE 1 
								END AS BIT) AS HideAllBet,
						CAST(	CASE	WHEN	@IsHidden_AllBet = 0 
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
												WHERE	ciDownline.mrecommend = c.custid
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

						-- GD
						CASE	WHEN EXISTS	(	SELECT	1
												FROM		dbo.custInfo AS ciDownline WITH (NOLOCK)											
												WHERE	ciDownline.mrecommend = c.custid
														AND ISNULL(HideGoldDeluxe,1)=1)
									THEN 0
								ELSE 1
						END AS SyncedGoldDeluxeDownline,
						-- For Cricket
						(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Cricket)) AS DisableCricket,
						CAST( CASE WHEN @IsIMBC = 1 AND @IsHidden_Cricket = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Cricket)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCricket,					
						CAST(COALESCE(l.LimitDays, l.MinDate,'') AS varchar(20)) AS DataAvailable
  					  FROM dbo.custinfo c with(NOLOCK)
  						LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = c.custid  

						-- Check isHidden AllBet
						--OUTER APPLY	dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(c.custid, @AllBet) AS sbhsc
		
						-- Upline Status
						INNER JOIN	dbo.CustProductStatus AS cpsUpline WITH (NOLOCK)
								ON	cpsUpline.CustID =	CASE	WHEN c.roleid = 1 THEN c.recommend
																WHEN c.roleid = 2 THEN c.mrecommend
																ELSE c.srecommend
														END
		   
					 WHERE SRecommend = @SRecommend
					   AND roleid = 3
					   AND (@Custid is null or c.Custid = @Custid)
					   AND enabled = case
									   when coalesce(@Closed, @Suspended) is not null then 1
									   else coalesce(@enabled, enabled)
									 end
					   AND isnull(closed, 0) = case
												 when @suspended = 1 then 0
												 else coalesce(@closed, isnull(closed, 0))
											   end
					   AND isnull(reject, 0) = case
												 when @Closed = 0 then 0
												 else coalesce(@suspended, isnull(reject, 0))
											   end
				   ) ci on cu.custid = ci.custid
		 LEFT JOIN dbo.CustSetting as cs with(NOLOCK) on cu.custid = cs.custid
		 LEFT JOIN dbo.custsetting3rd cs3 with(nolock) on cu.custid = cs3.custid
		 LEFT JOIN dbo.CustGameType cg WITH(NOLOCK) ON cu.custid = cg.CustID
		 LEFT JOIN @tmp_GameType g ON g.GameTypeID = cg.GameTypeID
													 AND g.IBCBetTypeID IN (1501,1503,1504,1505,1508,1511,1513,1514,1515,1516)
		INNER JOIN dbo.CustMaster cm with(NOLOCK) on cu.custid = cm.custid
		LEFT JOIN AgentCommRate AC WITH (NOLOCK) ON AC.CustId = CI.custid AND AC.Sporttype = 1 AND AC.Bettype = 301 
		LEFT JOIN CustDiscount3rd_Agent cdm WITH (NOLOCK) ON cdm.CustID = ci.custid AND cdm.SportType = 50 AND cdm.BetType = 501 AND @IsIMBC = 1
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON cu.custid=cl.CustID
		LEFT JOIN DBAGE.bodb_Age.dbo.Age_CustDateLimit l WITH(NOLOCK) ON cu.CustID=l.CustId
	WHERE ((cs.sporttype IN (1) AND cs.bettype IN (1, 5, 4) AND cs3.sporttype IN (161) AND cs3.bettype IN (81))
				OR (cs.sporttype IS NULL AND cs.bettype IS NULL AND cs3.sporttype IS NULL AND cs3.bettype IS NULL))
			AND (@IsInternalAdmin = 0 OR cu.site NOT IN (SELECT site FROM @tmp ))
	GROUP BY cu.custid, cu.username, ci.enabled, ci.closed, ci.reject, cu.roleid,
			   cu.firstname, cu.lastname, cu.creatdate, cu.iplogin, ci.DoubleCommLosing,
			   ci.DisableOutright, cm.DisableAutoMPT,			  
			   ci.synccasino, ci.disablecasino,  
			   ci.DisableNumber,
			   ci.DoubleCommLosing, ci.DisableCasinoBonus,  ci.HideKeno, ci.DisableEsports,
			   ci.DisableGoldDeluxe, ci.HideGoldDeluxe, ci.SyncGoldDeluxeUpline, ci.DisableColossusBet,ci.HideColossusBet,AC.CommRate,ac.CustId,ci.DisableMuayThai,ci.HideMuayThai,
			   ci.DisableAllBet,ci.DisableAllBetVIP,ci.HideAllBetUpline, ci.HideAllBet, ci.SyncedAllBet, ci.SyncedAllBetUpline, ci.SyncedAllBetDownline,
			   ci.DisableCricket, ci.HideCricket, cdm.Discount,
			   ci.DisableVoidBridge,ci.HideVoidBridgeUpline,ci.HideAllBetUpline, ci.HideVoidBridge,ci.SyncedVoidBridge,ci.SyncedVoidBridgeUpline, ci.SyncedVoidBridgeDownline,
			   ci.DisableNG2,ci.HideNG2Upline, ci.HideNG2,ci.SyncedNG2,ci.SyncedNG2Upline,
			   ci.DisableFishingWorld,ci.HideFishingWorldUpline,ci.HideFishingWorld,ci.SyncedFishingWorld,ci.SyncedFishingWorldUpline, ci.SyncedFishingWorldDownline,cl.ClosedReason,ci.SyncedGoldDeluxeDownline,
			   ci.DisableVirtualSports,ci.HideVirtualSportsUpline,ci.HideVirtualSports,
			   ci.DisableLottery,ci.HideLottery,ci.HideLotteryUpline,
			   ci.DisableLucky3,ci.HideLucky3Upline,ci.HideLucky3,
			   ci.DisableBullFighting,ci.HideBullFighting,ci.HideBullFightingUpline,
			   ci.DisablePokerGames1401,ci.DisablePokerGames1402, ci.DisablePokerGames1403, ci.DisablePokerGames1404, ci.DisablePokerGames1405, ci.HidePokerGames, ci.HidePokerGamesUpline
	ORDER BY RowNumber
END

GO