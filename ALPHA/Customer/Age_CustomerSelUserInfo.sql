/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelUserInfo]
	@custid int
	, @SettingStatus TINYINT = 0
AS
BEGIN
/*
Created: 20090211@nqminh
Updated: 20090227@Shifu
	-- get more customer information from custinfo
Task : Select customer information
DB: DBCUST/CustDB
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision]    
	- 20090603@[Lee]: Add given credit info   
	- 20100901@[Henry]: Add SyncBingo
	- 20120202@Johnson: Add live casino
	- 20120726@Johnson: add bingo
	- 20140520@Logan:   1.Retrieve remark for SAg, MAg, Ag from CustSuper, CustMaster & CustAgent
						2.Code aligning
	- 20150420@Elodie: Add Gold Deluxe Product
	- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20151028@Helen: Member Information to support Muay Thai  [Redmine: #45496]
	- 20151209@Helen: Member information for Cockfighting [Redmine: #48133]
	- 20160114@Helen: Cricket - [Redmine: #50027]
	- 20160127@Billy: Member information for AllBet - [Redmine: #51698]
	- 20160421@Elodie: Modidy code to get info for deposit account - [Redmine: #56438]
	- 20160413@Winnie: VoidBridge - [Redmine: #55531]
	- 20160801@Elodie: NG2 Product - [Redmine: #60809]
	- 20161031@Winnie: FishingWorld - [Redmine: #65474]
	- 20160801@Elodie: Implementing NewProductStatus Plugin - [Redmine #70722]	
	- 20170417@Winnie: Change to call the sp Acc_CheckShowProduct - [Redmine #72336]	
	- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
	- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
	- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]
	- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20180510@Elodie: Enhance performance [RedmineID: #95012]
	- 20180118@Johnson: remove Downline casino status for new direction [Redmine:#87328]
	- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
	- 20180919@Winnie: Esports Product - [Redmine: #101526]
	- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20191206@Eden: Add Virtual Games [Redmine: #122743]
	- 20200318@Elodie: Add Saba.club [Redmine: #130636]
	- 20200303@Tiara: Add SA Gaming Product [Redmine: #128058]
	- 20200321@Tiara: Add Sexy Gaming Product [Redmine: #130678]
	- 20200406@Elodie: Add BBIN Product [Redmine: #131363]
	- 20200403@Elodie: Add Table Games Product [Redmine: #129440]
	- 20200421@Elodie: Add GTCasino Product [Redmine: #130689]
	- 20200428@Eden: HotFix_-_The_status_Virtual_game_show_grey_color [Redmine: #133328]	
	- 20200504@Eden: ION Live casino [Redmine: #132323]
	- 20200506@Tiara: Add RNG War Product [Redmine: 132018]
	- 20201026@Eden: Adjust new pt for 789y [Redmine: #143764]
	- 20201130@Tina: Add GDG (Gold Diamond Gaming) Live casino [Redmine: #144105]
	- 20201012@Tina: Add new parameter @SettingStatus [Redmine: #143077]
	- 20201204@Tina: add BG (Big Gaming) [RedmineID: #142458]
	- 20210229@Winfred: add Sports Lottery [RedmineID: #147361]
	- 20210315@Tina: add PP Live Casino [RedmineID: #134041]
	- 20210426@Tina: Add VGaming [Redmine: #153938]
	- 20210510@Tina: Lock account & indirect close account [redmine: #148600]
	- 20210728@Tina: NAP - Cannot setting Casino for Licensee account [Redmine: #159140]
	- 20210809@Winfred: add Bitcoin Betting [RedmineID: #159039]

Param's Explanation:
	@custid: custid that need to be viewed.   
	- @SettingStatus: 0: Pro, 1: UAT
*/

	SET NOCOUNT ON

	declare @roleid tinyint
	declare @remark nvarchar(300) = ''
	DECLARE @Site VARCHAR(10),@HasDownline INT=0,@IsDisabledDownline BIT=0, @TotalDownlines INT
	CREATE TABLE #ciDownline (CustID INT, bitmapHasSynced BINARY (32))

	SELECT @roleid = roleid
	FROM Customer with(nolock)
	WHERE custid = @custid
	 
	if @roleid = 1
	begin
		select @remark = remark
		from customer with(nolock)
		where custid = @custid
	end
	if @roleid = 2
	begin
		select @remark = creationRemark
		from CustAgent with(nolock)
		where custid = @custid
		
		--Use nest loop and parallesim (will use parallesim if big line) to enhance performance
		INSERT INTO #ciDownline (CustID, bitmapHasSynced) 
		SELECT ci.custid, cs.bitmapHasSynced
		FROM (	SELECT TOP (100000) custid 
				FROM dbo.custInfo WITH (NOLOCK) WHERE recommend = @custid) ci
			CROSS APPLY (SELECT TOP (1) bitmapHasSynced FROM dbo.CustProductStatus cs WITH (NOLOCK) WHERE cs.CustID = ci.custid) cs		
	end
	if @roleid = 3
	begin
		select @remark = creationRemark
		from CustMaster with(nolock)
		where custid = @custid

		SELECT @TotalDownlines = COUNT(1)
		FROM Custinfo WITH (NOLOCK)
		WHERE mrecommend = @custid

		--Use nest loop and parallesim (will use parallesim if big line) to enhance performance
		IF @TotalDownlines <= 100000
			INSERT INTO #ciDownline (CustID, bitmapHasSynced) 
			SELECT ci.custid, cs.bitmapHasSynced
			FROM (	SELECT TOP (100000) custid 
					FROM dbo.custInfo WITH (NOLOCK) WHERE mrecommend = @custid) ci
				CROSS APPLY (SELECT TOP (1) bitmapHasSynced FROM dbo.CustProductStatus cs WITH (NOLOCK) WHERE cs.CustID = ci.custid) cs		
		ELSE -- Use hash match if line > 100k
			INSERT INTO #ciDownline (CustID, bitmapHasSynced) 
			SELECT ci.custid, cs.bitmapHasSynced
			FROM dbo.custInfo ci WITH (NOLOCK) 
				INNER JOIN dbo.CustProductStatus cs WITH (NOLOCK) ON cs.CustID = ci.custid 
			WHERE ci.mrecommend = @custid
	end
	if @roleid = 4
	begin
		select @remark = creationRemark
		from CustSuper with(nolock)
		where custid = @custid
		
		SELECT @TotalDownlines = COUNT(1)
		FROM Custinfo WITH (NOLOCK)
		WHERE srecommend = @custid

		--Use nest loop and parallesim (will use parallesim if big line) to enhance performance
		IF @TotalDownlines <= 100000
			INSERT INTO #ciDownline (CustID, bitmapHasSynced) 
			SELECT ci.custid, cs.bitmapHasSynced
			FROM (SELECT TOP (100000) custid 
					FROM dbo.custInfo WITH (NOLOCK) WHERE srecommend = @custid) ci
				CROSS APPLY (SELECT TOP (1) bitmapHasSynced FROM dbo.CustProductStatus cs WITH (NOLOCK) WHERE cs.CustID = ci.custid) cs		
		ELSE -- Use hash match if line > 100k
			INSERT INTO #ciDownline (CustID, bitmapHasSynced) 
			SELECT ci.custid, cs.bitmapHasSynced
			FROM dbo.custInfo ci WITH (NOLOCK) 
				INNER JOIN dbo.CustProductStatus cs WITH (NOLOCK) ON cs.CustID = ci.custid 
			WHERE ci.srecommend = @custid
	end
	
	-- For DCS
	 
    DECLARE	@bitmapOrder_MuayThai		INT		
		,	@bitmapOrder_Esports		INT		
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_FishingWorld	INT	
		,	@bitmapOrder_VS				INT
		,	@bitmapOrder_VG				INT
		,	@bitmapOrder_SabaClub		INT
		,	@bitmapOrder_SAGaming		INT 
		,	@bitmapOrder_ION			INT 
		,	@bitmapOrder_SexyGaming		INT 
		,	@bitmapOrder_BBIN			INT 
		,	@bitmapOrder_TableGames		INT 
		,	@bitmapOrder_GTCasino		INT
		,	@bitmapOrder_RNGWar			INT 
		--GDG
		,	@bitmapOrder_GDG			INT
		--BG
		,	@bitmapOrder_BG				INT 
		,	@bitmapOrder_SportsLottery	INT 
		--PPLive
		,	@bitmapOrder_PPLive			INT
		--VGaming
		,	@bitmapOrder_VGaming		INT
		--Bitcoin
		,	@bitmapOrder_Bitcoin		INT 
		 
    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)
	SET @bitmapOrder_Esports = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 43 AND Bettype = 1)
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1021)
	SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
	SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)
	SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 180 AND Bettype = 1201)
	SET @bitmapOrder_VG = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 245 AND Bettype = 4601)
	SET @bitmapOrder_SabaClub = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 200 AND Bettype = 1611)
	SET @bitmapOrder_SAGaming = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 244 AND Bettype = 3001)
	SET @bitmapOrder_ION = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 225 AND Bettype = 5601)
	SET @bitmapOrder_SexyGaming = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 243 AND Bettype = 3101)
	SET @bitmapOrder_BBIN = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 241 AND Bettype = 3300)
	SET @bitmapOrder_TableGames = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 222 AND Bettype = 4901)
	SET @bitmapOrder_GTCasino = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 242 AND Bettype = 3201)
	SET @bitmapOrder_RNGWar = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 224 AND Bettype = 5500)
	SET @bitmapOrder_GDG = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 236 AND Bettype = 5701)
	SET @bitmapOrder_BG = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 239 AND Bettype = 3501)
	SET @bitmapOrder_SportsLottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 169 AND Bettype = 3611)	
	SET @bitmapOrder_PPLive = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 170 AND Bettype = 3701)
	SET @bitmapOrder_VGaming = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 171 AND Bettype = 3801)
	SET @bitmapOrder_Bitcoin = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 175 AND Bettype = 7901)

	SELECT	@bitmapOrder_AllBet =	(SELECT	psp.bitmapOrder FROM dbo.ProductStatusProfile AS psp WITH(NOLOCK) WHERE	psp.Sporttype = 211 AND	psp.Bettype = 2401)
    
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
		,	@IsHidden_ION			INT = 1
		,	@IsHidden_SexyGaming	INT = 1
		,	@IsHidden_BBIN			INT = 1
		,	@IsHidden_TableGames	INT = 1
		,	@IsHidden_GTCasino		INT = 1
		,	@IsHidden_RNGWar		INT = 1
		,	@IsHidden_GDG			INT = 1--GDG
		,	@IsHidden_BG			INT = 1
		,	@IsHidden_SportsLottery	INT = 1
		,	@IsHidden_PPLive		INT = 1
		,	@IsHidden_VGaming		INT = 1
		,	@IsHidden_Bitcoin		INT = 1

	EXEC Acc_CheckShowProduct @ProductID = 16, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_MuayThai OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 211, @IsHide = @IsHidden_AllBet OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 22, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_VoidBridge OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 220, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 23, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_NG2 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 24, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_FishingWorld OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5, @SettingStatus = @SettingStatus,  @IsHide = @IsHidden_VS OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 16, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_Esports OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 38, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_VG OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 42, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_SabaClub OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 244, @IsHide = @IsHidden_SAGaming OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 225, @IsHide = @IsHidden_ION OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 243, @IsHide = @IsHidden_SexyGaming OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 242, @IsHide = @IsHidden_GTCasino OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 241, @IsHide = @IsHidden_BBIN OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 222, @IsHide = @IsHidden_TableGames OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 224, @IsHide = @IsHidden_RNGWar OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 236, @IsHide = @IsHidden_GDG OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 239, @IsHide = @IsHidden_BG OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 44, @SettingStatus = @SettingStatus, @Sporttype = 169, @IsHide = @IsHidden_SportsLottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 41, @SettingStatus = @SettingStatus, @Sporttype = 170, @IsHide = @IsHidden_PPLive OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 66, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_VGaming OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 69, @SettingStatus = @SettingStatus, @IsHide = @IsHidden_Bitcoin OUTPUT

	SELECT Customer.custid,
		   Customer.userpwd,
		   ci.username,
		   customer.firstname, 
		   customer.lastname, 
		   isnull(customer.phone,'') as phone, 
		   isnull(customer.mobilephone,'') as mobilephone, 
		   isnull(customer.fax,'') as fax, 
		   customer.email,
		   customer.username2,
		   ci.currency,  
		   ISNULL(cps.closed, ci.closed) closed, 
		   ISNULL(cps.reject, ci.reject) as suspend,
		   ci.srecommend as superid,
		   ci.mrecommend as masterid,
		   ci.recommend as agentid, 
		   Customer.roleid as roleid,
		   ci.synccasino,
	
		   ci.disablecasino,		
			
		  
		   ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		   ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		   
		   	-- For MuayThai
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_MuayThai)),1) AS DisableMuayThai,
			CAST(CASE WHEN @IsHidden_MuayThai = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_MuayThai)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideMuayThai,
			-- For Esports
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Esports)),1) AS DisableEsports,
			CAST(CASE WHEN @IsHidden_Esports = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Esports)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideEsports,

			-- For AllBet
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_AllBet)), 1) AS DisableAllBet,
			CAST(	CASE	WHEN	@IsHidden_AllBet = 0 
								--AND	sbhsc.IsHidden = 0
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_AllBet)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideAllBet,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_AllBet)), 0) AS SyncedAllBet,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_AllBet)), 0) AS SyncedAllBetUpline,
			CASE	WHEN Customer.roleid = 1 THEN 1
					WHEN EXISTS	(	SELECT 1
									FROM #ciDownline AS ciDownline
										CROSS APPLY dbo.f_CustSetting_ProductStatusSel(ciDownline.bitmapHasSynced, @bitmapOrder_AllBet) s
									WHERE s.value = 0)
						THEN 0
					ELSE 1
			END AS SyncedAllBetDownline,

			-- For SA Gaming
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SAGaming)), 1) AS DisableSAGaming,
			CAST(	CASE	WHEN	@IsHidden_SAGaming = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SAGaming)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideSAGaming,
			-- For Sexy Gaming
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SexyGaming)), 1) AS DisableSexyGaming,
			CAST(	CASE	WHEN	@IsHidden_SexyGaming = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SexyGaming)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideSexyGaming,
			-- For GTCasino
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_GTCasino)) AS DisableGTCasino,
			CAST(	CASE	WHEN	@IsHidden_GTCasino = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_GTCasino)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideGTCasino,
			-- For ION
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_ION)), 1) AS DisableION,
			CAST(	CASE	WHEN	@IsHidden_ION = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_ION)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideION,

			-- For BBIN
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_BBIN)) AS DisableBBIN,
			CAST(	CASE	WHEN	@IsHidden_BBIN = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_BBIN)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideBBIN,
			-- VoidBridge
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge)),1) AS DisableVoidBridge,
			CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VoidBridge)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_VoidBridge)), 0) AS SyncedVoidBridge,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_VoidBridge)), 0) AS SyncedVoidBridgeUpline,
			CASE	WHEN Customer.roleid = 1 THEN 1
					WHEN EXISTS	(	SELECT 1
									FROM #ciDownline AS ciDownline
										CROSS APPLY dbo.f_CustSetting_ProductStatusSel(ciDownline.bitmapHasSynced, @bitmapOrder_VoidBridge) s
									WHERE s.value = 0)
						THEN 0
					ELSE 1
			END AS SyncedVoidBridgeDownline,
			--Lottery
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lottery)),1) AS DisableLottery,
			CAST(CASE WHEN @IsHidden_Lottery = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Lottery)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLottery,
			
			-- NG2
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_NG2)),1) AS DisableNG2,
			CAST(CASE WHEN @IsHidden_NG2 = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_NG2)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_NG2)), 0) AS SyncedNG2,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_NG2)), 0) AS SyncedNG2Upline,

			--VS
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VS)),1) AS DisableVirtualSports,
			CAST(CASE WHEN @IsHidden_VS = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VS)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,		
			-- For VG
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VG)), 1) AS DisableVirtualGames,		
			CAST(CASE WHEN @IsHidden_VG = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VG)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualGames,
			-- For SabaClub
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SabaClub)), 1) AS DisableSabaClub,		
			CAST(CASE WHEN @IsHidden_SabaClub = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SabaClub)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideSabaClub,
			-- For Table Games
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_TableGames)) AS DisableTableGames,			
			CAST(CASE WHEN @IsHidden_TableGames = 0 AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_TableGames)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideTableGames,
			-- For RNG War
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_RNGWar)) AS DisableRNGWar,			
			CAST(CASE WHEN @IsHidden_RNGWar = 0 AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_RNGWar)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideRNGWar,
			--FishingWorld
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld)),1) AS DisableFishingWorld,
			CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_FishingWorld)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
			--For BG
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_BG)),1) AS DisableBG,
			CAST(CASE WHEN @IsHidden_BG = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_BG)),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBG,
			--For FishingWorld
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced, @bitmapOrder_FishingWorld)), 0) AS SyncedFishingWorld,
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cpsUpline.bitmapHasSynced, @bitmapOrder_FishingWorld)), 0) AS SyncedFishingWorldUpline,
			CASE	WHEN Customer.roleid = 1 THEN 1
					WHEN EXISTS	(	SELECT 1
									FROM #ciDownline AS ciDownline
										CROSS APPLY dbo.f_CustSetting_ProductStatusSel(ciDownline.bitmapHasSynced, @bitmapOrder_FishingWorld) s
									WHERE s.value = 0)
						THEN 0
					ELSE 1
			END AS SyncedFishingWorldDownline,
			-- For GDG (Gold Diamond Gaming)
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_GDG)), 1) AS DisableGDGGaming,
			CAST(	CASE	WHEN	@IsHidden_GDG = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_GDG)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideGDG,		
			--end GDG
			-- For Sports Lottery
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_SportsLottery)) AS DisableSportsLottery,			
			CAST(CASE WHEN @IsHidden_SportsLottery = 0 AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_SportsLottery)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideSportsLottery,
			-- For PPLive
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_PPLive)), 1) AS DisablePPLive,
			CAST(	CASE	WHEN	@IsHidden_PPLive = 0 
								AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_PPLive)), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HidePPLive,		
			--end PPLive
			-- For VGaming
			ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_VGaming)), 1) AS DisableVGaming,		
			CAST(CASE WHEN @IsHidden_VGaming = 0 AND ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_VGaming)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVGaming,
			--end VGaming
			-- For Bitcoin
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Bitcoin)) AS DisableBitcoin,			
			CAST(CASE WHEN @IsHidden_Bitcoin = 0 AND	ISNULL((SELECT [value] FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsHidden, @bitmapOrder_Bitcoin)), 1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideBitcoin,	
		   ci.credit,
		   e.currency as currencyname,
		   @remark as remark,
		   ISNULL(NULLIF(Customer.site,''), ag.site) AS Site
	  FROM Customer WITH(nolock) 
		 INNER JOIN CustInfo as ci with(NOLOCK)
				 on Customer.CustID = ci.CustID --Shifu
		 INNER JOIN Exchange as e with (NOLOCK)
				 ON Customer.currency = e.exchangeid
		OUTER APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, bitmapHasSynced
										, bitmapIsDisabled
										, bitmapIsHidden
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
										AND ci.srecommend NOT IN (SELECT CustID FROM Dep_CustSuper WITH (NOLOCK))
								) AS cps
		-- Upline Status
		LEFT JOIN	dbo.CustProductStatus AS cpsUpline WITH (NOLOCK)
				ON	cpsUpline.CustID =	CASE	WHEN Customer.roleid = 1 THEN Customer.recommend
												WHEN Customer.roleid = 2 THEN Customer.mrecommend
												ELSE Customer.srecommend
										END
		LEFT JOIN dbo.Customer ag WITH (NOLOCK) ON Customer.recommend = ag.custid
		    
		 
	 WHERE Customer.custid = @custid

	 DROP TABLE #ciDownline
END
GO
