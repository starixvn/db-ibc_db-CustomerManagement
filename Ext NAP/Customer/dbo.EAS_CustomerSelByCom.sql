/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelByCom]  
    @GroupName	VARCHAR(50) = 'ACCTHAI',
    @Custid		int = null,
    @Enabled	bit = null,
    @Closed		bit = null,
    @Suspended	bit = NULL,
	@UserID		INT = NULL,
	@IsDataLimited	BIT	= 0
AS  
/*  
Created by: Scott  
Date: 2012-12-17  
Task : Customer list by company
DB: DBCUST/CustDB
Original SP: Acc_CustomerSelBySAg
Revisions:  
	- 20130121@Dan: Move sp from DB053/bodb02 to DBEAS/bodb_EAS, call to bodb_AGE for Acc_CustGroup
	- 20130517@Lukas: 
			fix bug - wrong comm rate 
			add filter to reduce workload
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
	- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
	- 20170606@Winnie: Apply color for closed account  - [Redmine #74494]	
	- 20170629@Winnie: Offer Enable/Disable GoldDeluxe [RedmineID: #72957]
	- 20170828@Elodie: EXT - Support Security Code on Customer List - [Redmine: #81091]
	- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]
	- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
	- 20180830@Elodie: Add new bettype of Poker Games Product - [Redmine: #97675]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20180907@Winnie: EXT-Function to control data range for SMA - [Redmine: #100067]
	- 20180731@Razor: Splitting Super Profile [#86934]
	- 20180919@Winnie: Add new bettype of Esports Product - [Redmine: #101526]
	- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
	- 20190806@Eden: add bettype 1525,1526 for Keno gametype - [Redmine: #116466]
	- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	
exec EAS_CustomerSelByCom @GroupName='ACCDDD',@Custid=default,@Enabled=default,@Closed=default,@Suspended=default    
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @tmpSuperList TABLE( custID INT, username VARCHAR(30))

	DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)
	 
	 BEGIN TRY		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK)
	 END TRY
	 BEGIN CATCH		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
	 END CATCH
	 
	 DECLARE  @IsInternalAdmin BIT = 0, @HasSecurityCode BIT = 0
	 
    INSERT INTO @tmpSuperList(CustID, username)
    SELECT custID, username 
      FROM dbo.custinfo WITH(NOLOCK)
     WHERE custid in (SELECT custid
                        from dbo.Acc_CustGroup WITH(nolock)
                       WHERE GroupName = @GroupName
                     )
       AND (@Custid IS NULL OR custid = @Custid)
       AND roleid = 4
       AND enabled = CASE
                       WHEN COALESCE(@Closed, @Suspended) IS NOT NULL THEN 1
                       ELSE COALESCE(@enabled, enabled)
                     END
       AND ISNULL(closed, 0) = CASE
                                 WHEN @suspended = 1 then 0
                                 ELSE COALESCE(@closed, ISNULL(closed, 0))
                               END
       AND ISNULL(reject, 0) = CASE
                                 WHEN @Closed = 0 then 0
                                 ELSE COALESCE(@suspended, ISNULL(reject, 0))
                               END

	EXEC dbo.Acc_CustomerIsInternalAdmin @Custid = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT

	IF EXISTS (SELECT TOP 1 1 FROM dbo.CustLoginInfo cl WITH(NOLOCK) WHERE cl.Custid = @Custid AND cl.SecurityCode IS NOT NULL)
		SELECT @HasSecurityCode = 1

    --------output
    -- For DCS
    DECLARE	@bitmapOrder_MuayThai		INT 
		,	@bitmapOrder_Esports		INT
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_AllBetVIP		INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_FishingWorld	INT
		,	@bitmapOrder_VS				INT

    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)
	SET @bitmapOrder_Esports= (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 43 AND Bettype = 1)
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1021)
    SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
    SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)
	SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 180 AND Bettype = 1201)

	SELECT	@bitmapOrder_AllBet =	(SELECT	psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE	psp.Sporttype = 211 AND	psp.Bettype = 2401)
    SELECT	@bitmapOrder_AllBetVIP = (SELECT psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE psp.Sporttype = 211 AND	psp.Bettype = 2402)
    
    DECLARE	@IsHidden_MuayThai			INT = 1
		,	@IsHidden_Esports			INT = 1
		,	@IsHidden_AllBet			INT = 1
		,	@IsHidden_VoidBridge		INT = 1
		,	@IsHidden_Lottery			INT = 1
		,	@IsHidden_NG2				INT = 1  
		,	@IsHidden_FishingWorld		INT = 1	
		,	@IsHidden_VS				INT = 1
		,	@SyncDownlinesGoldDeluxe	BIT
		

   	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_MuayThai OUTPUT	
	EXEC Acc_CheckShowProduct @ProductID = 21, @IsHide = @IsHidden_AllBet OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 22, @IsHide = @IsHidden_VoidBridge OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 28, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 23, @IsHide = @IsHidden_NG2 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 24, @IsHide = @IsHidden_FishingWorld OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5, @IsHide = @IsHidden_VS OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_Esports OUTPUT	
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
           ISNULL(ci.reject, 0) as suspended,
           cu.roleid,
           ISNULL(cp.firstname, '') as firstname,
           ISNULL(cp.lastname, '') as lastname,
	       
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupa else 0 end) as groupa,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupb else 0 end) as groupb,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupc else 0 end) as groupc,
		   MAX(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupd else 0 end) as groupd,

	       MAX(case
	             WHEN cs.bettype = 5 and cs.sporttype = 1 then cs.sdiscount
	             ELSE 0
	           end) as discount1x2,
	       MAX(case
	             WHEN cs.bettype = 4 and cs.sporttype = 1 then cs.sdiscount
	             ELSE 0
	           end) as discountcs,
           cu.creatdate as createdate,
           ISNULL(cu.iplogin, '') as lastloginip,
	       ci.DoubleCommLosing,
	       ISNULL(ci.DisableOutright, 0) as DisableOutright,
	    
	       -- For casino
	       ci.synccasino,
	       ci.disablecasino,	   
	       ci.DisableNumber,	  
	    
	       -- For Esports
	       --ci.DisableEsports,
	       -- For Keno
	       ci.HideKeno,
	       MIN(CASE WHEN g.IBCBetTypeID in (1501,1503,1504,1505,1508,1511,1513,1514,1515,1516,1517,1519,1520,1521,1522,1524,1525,1526) THEN cg.IsDisabled ELSE 1 END) as DisableKeno, 
	       ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		   ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		   
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
								--AND	MAX(sbhsc.IsHidden) = 0
								AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_AllBet)) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideAllBet,
			1 AS HideAllBetUpline,
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_AllBet)) AS SyncedAllBet,
			1 AS SyncedAllBetUpline,
			CASE	WHEN EXISTS	(	SELECT	1
									FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
									INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
											ON	ciDownline.custid = cpsDownline.CustID
									WHERE	ciDownline.srecommend = cu.custid
										AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_AllBet)) = 0)
						THEN 0
					ELSE 1
			END AS SyncedAllBetDownline,

		   -- For VoidBridge
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge)) AS DisableVoidBridge,
			1 AS DisableVoidBridgeUpline,
			CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VoidBridge)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
			1 AS HideVoidBridgeUpline,
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_VoidBridge)) AS SyncedVoidBridge,
		   1 AS SyncedVoidBridgeUpline,
			CASE	WHEN EXISTS	(	SELECT	1
									FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
									INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
											ON	ciDownline.custid = cpsDownline.CustID
									WHERE	ciDownline.srecommend = cu.custid
										AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_VoidBridge)) = 0)
						THEN 0
					ELSE 1
			END AS SyncedVoidBridgeDownline,
			-- GD
			CASE	WHEN EXISTS	(	SELECT	1
									FROM		dbo.custInfo AS ciDownline WITH (NOLOCK, INDEX = IX_srecommend)											
									WHERE	ciDownline.srecommend = cu.custid
											AND ISNULL(HideGoldDeluxe,1)=1)
						THEN 0
					ELSE 1
			END AS SyncedGoldDeluxeDownline,
			-- For Lottery
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lottery)) AS DisableLottery,
			1 AS DisableLotteryUpline,
			CAST(CASE WHEN @IsHidden_Lottery = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lottery)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLottery,
			1 AS HideLotteryUpline,
			-- For NG2
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_NG2)) AS DisableNG2,
			1 AS HideNG2Upline,
			1 AS DisableNG2Upline,
			CAST(CASE WHEN @IsHidden_NG2 = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_NG2)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_NG2)) AS SyncedNG2,
			1 AS SyncedNG2Upline,

			-- For FishingWorld
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld)) AS DisableFishingWorld,
			1 AS DisableFishingWorldUpline,
			CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_FishingWorld)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
			1 AS HideFishingWorldUpline,
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_FishingWorld)) AS SyncedFishingWorld,
		   1 AS SyncedFishingWorldUpline,
			CASE	WHEN EXISTS	(	SELECT	1
									FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
									INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
											ON	ciDownline.custid = cpsDownline.CustID
									WHERE	ciDownline.srecommend = cu.custid
										AND	(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cpsDownline.bitmapHasSynced, @bitmapOrder_FishingWorld)) = 0)
						THEN 0
					ELSE 1
			END AS SyncedFishingWorldDownline,
			ISNULL(cl.ClosedReason,0) AS ClosedReason,
			-- For VS
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VS)) AS DisableVirtualSports,
			1 AS DisableVirtualSportsUpline,
			CAST(CASE WHEN @IsHidden_VS = 0 AND (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VS)) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,
			1 AS HideVirtualSportsUpline,

			1 AS UplineHasSecurityCode,
			@HasSecurityCode AS HasSecurityCode,
			l.LimitDays,
			l.MinDate,			
	       ROW_NUMBER() OVER(ORDER BY ci.enabled desc, ci.closed,
	                                  ISNULL(ci.reject,0), cu.username) as RowNumber
      FROM dbo.customer cu with(nolock)
		INNER JOIN @tmpSuperList sl on sl.custid = cu.custid
		INNER JOIN CustSuper CSuper WITH (NOLOCK) ON CSuper.Custid = sl.Custid
		INNER JOIN dbo.custinfo ci with(nolock) on ci.custid = cu.custid
		INNER JOIN dbo.CustSuperProfile cp WITH(NOLOCK) ON cp.CustId = cu.CustId
		 LEFT JOIN dbo.CustSetting as cs with(NOLOCK) on cu.custid = cs.custid
		 LEFT JOIN dbo.custsetting3rd cs3 with(nolock) on cu.custid = cs3.custid
		 LEFT JOIN dbo.CustGameType cg WITH(NOLOCK) ON cu.custid = cg.CustID
		 LEFT JOIN @tmp_GameType g ON g.GameTypeID = cg.GameTypeID
													 AND g.IBCBetTypeID IN (1501,1503,1504,1505,1508,1511,1513,1514,1515,1516,1517,1519,1520,1521,1522,1524,1525,1526)																			
		LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid 
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON cu.custid=cl.CustID
		-- Check isHidden AllBet
		--OUTER APPLY	dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(cu.custid, @AllBet) AS sbhsc
		LEFT JOIN dbo.Age_CustDateLimit l WITH(NOLOCK) ON cu.CustID=l.CustId   
		
     WHERE ((cs.sporttype IN (1) AND cs.bettype IN (1,5,4) AND cs3.sporttype IN (161) AND cs3.bettype IN (81))
				OR (cs.sporttype IS NULL AND cs.bettype IS NULL AND cs3.sporttype IS NULL AND cs3.bettype IS NULL))
			AND (@IsInternalAdmin = 0 OR cu.site NOT IN (SELECT site FROM @tmp ))
			AND (@IsDataLimited=0 OR (@IsDataLimited=1 AND (l.LimitDays IS NOT NULL OR l.MinDate IS NOT NULL)))
	  GROUP BY cu.custid, cu.username, ci.enabled, ci.closed, ci.reject, cu.roleid,
			   cp.firstname, cp.lastname, cu.creatdate, cu.iplogin,	ci.DisableOutright,			 
			   ci.synccasino, ci.disablecasino, ci.DisableNumber,			
			   ci.DoubleCommLosing,  ci.HideKeno, --ci.DisableEsports,
			   ci.DisableGoldDeluxe, ci.HideGoldDeluxe,
			   cps.bitmapIsDisabled,cps.bitmapIsHidden, cps.bitmapHasSynced,cu.[site],cl.ClosedReason
			   ,l.LimitDays, l.MinDate
	ORDER BY RowNumber
			   
END
GO