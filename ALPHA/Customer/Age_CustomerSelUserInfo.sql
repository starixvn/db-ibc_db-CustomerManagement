/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO 

ALTER PROCEDURE [dbo].[Age_CustomerSelUserInfo]
	@custid int
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

Param's Explanation:
• @custid: custid that need to be viewed.   
*/

	SET NOCOUNT ON

	declare @roleid tinyint
	declare @remark nvarchar(300) = ''
	DECLARE @Site VARCHAR(10)
	
	select @roleid = roleid
	  from Customer with(nolock)
	 where custid = @custid
	 
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
	end
	if @roleid = 3
	begin
		select @remark = creationRemark
		  from CustMaster with(nolock)
		 where custid = @custid
	end
	if @roleid = 4
	begin
		select @remark = creationRemark
		  from CustSuper with(nolock)
		 where custid = @custid
	end

	-- For DCS
	 
    DECLARE	@bitmapOrder_MuayThai		INT
		,	@bitmapOrder_CockFighting	INT
		,	@bitmapOrder_Cricket		INT
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_FishingWorld	INT
    
    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)
    SET @bitmapOrder_CockFighting = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 206 AND Bettype = 1003)
    SET @bitmapOrder_Cricket = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 50 AND Bettype = 501)
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
	SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)

	SELECT	@bitmapOrder_AllBet =	(
										SELECT	psp.bitmapOrder
										FROM	dbo.ProductStatusProfile AS psp WITH(NOLOCK)
										WHERE	psp.Sporttype = 211
											AND	psp.Bettype = 2401
									)
    
    DECLARE	@IsHidden_MuayThai		INT = 1
		,	@IsHidden_CockFighting	INT = 1
		,	@IsHidden_Cricket		INT = 1
		,	@IsHidden_AllBet		INT = 1	
		,	@IsHidden_VoidBridge	INT = 1	
		,	@IsHidden_NG2			INT = 1
		,	@IsHidden_FishingWorld	INT = 1	
    
    DECLARE	@SportBook2				INT = 16
		,	@CockFighting			INT = 19
		,	@Cricket				INT = 20
		,	@AllBet					INT = 21
		,	@VoidBridge				INT = 22
		,	@NG2					INT = 23
		,	@FishingWorld			INT = 24
    
	IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@SportBook2,4))
	BEGIN
		SET @IsHidden_MuayThai = 0
	END
	IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@CockFighting,4))
	BEGIN
		SET @IsHidden_CockFighting = 0
	END
	IF EXISTS (SELECT TOP(1) 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@AllBet, 4))
	BEGIN
	    SET	@IsHidden_AllBet = 0
	END
	
	IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@Cricket,4))
	BEGIN
		SET @IsHidden_Cricket = 0
	END

	IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@VoidBridge,4))
	BEGIN
		SET @IsHidden_VoidBridge = 0
	END
	 IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@NG2,11))
	BEGIN
		SET @IsHidden_NG2 = 0
	END
	IF EXISTS( SELECT 1 FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@FishingWorld,13))
	BEGIN
		SET @IsHidden_FishingWorld = 0
	END

	DECLARE @recommend INT, @IsIMBC BIT = 0
	
	IF @roleid = 1
	BEGIN
		SET @recommend = (SELECT recommend FROM custInfo WITH (NOLOCK) WHERE custid = @custid)
		IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @recommend AND [Site] = 'IMBC')
			SET @IsIMBC = 1
			
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @custid AND [Site] = 'IMBC')
			SET @IsIMBC = 1
	END

	SELECT Customer.custid,
		   Customer.userpwd,
		   ci.username,
		   firstname, 
		   lastname, 
		   isnull(phone,'') as phone, 
		   isnull(mobilephone,'') as mobilephone, 
		   isnull(fax,'') as fax, 
		   email,
		   username2,
		   ci.currency,  
		   ci.closed, 
		   ci.reject as suspend,
		   ci.srecommend as superid,
		   ci.mrecommend as masterid,
		   ci.recommend as agentid, 
		   Customer.roleid as roleid,
		   ci.synccasino,
		   ci.syncbingo,
		   ci.disablecasino,
		   ci.disablelivecasino,
		   ci.DisableBingo,
		   ci.synclivecasino,
		   ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		   ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		   
		   ISNULL(ci.DisableColossusBet,1) AS DisableColossusBet,
		   ISNULL(ci.HideColossusBet,1) AS HideColossusBet,
		   
		   	-- For MuayThai
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_MuayThai),1) AS DisableMuayThai,
			CAST(CASE WHEN @IsHidden_MuayThai = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_MuayThai),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideMuayThai,
			-- For CockFighting
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_CockFighting),1) AS DisableCockFighting,
			CAST(CASE WHEN @IsHidden_CockFighting = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_CockFighting),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCockFighting,
			-- For AllBet
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_AllBet), 1) AS DisableAllBet,
			CAST(	CASE	WHEN	@IsHidden_AllBet = 0 
								--AND	sbhsc.IsHidden = 0
								AND	ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_AllBet), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideAllBet,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_AllBet), 0) AS SyncedAllBet,
			ISNULL(dbo.f_GetProductStatus(cpsUpline.bitmapHasSynced, @bitmapOrder_AllBet), 0) AS SyncedAllBetUpline,
			CASE	WHEN Customer.roleid = 1 THEN 1
					WHEN EXISTS	(	SELECT	1
									FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
									INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
											ON	ciDownline.custid = cpsDownline.CustID
									WHERE	Customer.custid =	CASE	WHEN Customer.roleid = 2 THEN ciDownline.recommend
																		WHEN Customer.roleid = 3 THEN ciDownline.mrecommend
																		WHEN Customer.roleid = 4 THEN ciDownline.srecommend
																		ELSE -1
																END
										AND	dbo.f_GetProductStatus(cpsDownline.bitmapHasSynced, @bitmapOrder_AllBet) = 0)
						THEN 0
					ELSE 1
			END AS SyncedAllBetDownline,
			-- VoidBridge
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VoidBridge),1) AS DisableVoidBridge,
			CAST(CASE WHEN @IsHidden_VoidBridge = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VoidBridge),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVoidBridge,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_VoidBridge), 0) AS SyncedVoidBridge,
			ISNULL(dbo.f_GetProductStatus(cpsUpline.bitmapHasSynced, @bitmapOrder_VoidBridge), 0) AS SyncedVoidBridgeUpline,
			CASE	WHEN Customer.roleid = 1 THEN 1
					WHEN EXISTS	(	SELECT	1
									FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
									INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
											ON	ciDownline.custid = cpsDownline.CustID
									WHERE	Customer.custid =	CASE	WHEN Customer.roleid = 2 THEN ciDownline.recommend
																		WHEN Customer.roleid = 3 THEN ciDownline.mrecommend
																		WHEN Customer.roleid = 4 THEN ciDownline.srecommend
																		ELSE -1
																END
										AND	dbo.f_GetProductStatus(cpsDownline.bitmapHasSynced, @bitmapOrder_VoidBridge) = 0)
						THEN 0
					ELSE 1
			END AS SyncedVoidBridgeDownline,

			-- NG2
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_NG2),1) AS DisableNG2,
			CAST(CASE WHEN @IsHidden_NG2 = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_NG2),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_NG2), 0) AS SyncedNG2,
			ISNULL(dbo.f_GetProductStatus(cpsUpline.bitmapHasSynced, @bitmapOrder_NG2), 0) AS SyncedNG2Upline,
			--FishingWorld
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_FishingWorld),1) AS DisableFishingWorld,
			CAST(CASE WHEN @IsHidden_FishingWorld = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_FishingWorld),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideFishingWorld,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_FishingWorld), 0) AS SyncedFishingWorld,
			ISNULL(dbo.f_GetProductStatus(cpsUpline.bitmapHasSynced, @bitmapOrder_FishingWorld), 0) AS SyncedFishingWorldUpline,
			CASE	WHEN Customer.roleid = 1 THEN 1
					WHEN EXISTS	(	SELECT	1
									FROM		dbo.CustProductStatus AS cpsDownline WITH (NOLOCK)
									INNER JOIN	dbo.custInfo AS ciDownline WITH (NOLOCK)
											ON	ciDownline.custid = cpsDownline.CustID
									WHERE	Customer.custid =	CASE	WHEN Customer.roleid = 2 THEN ciDownline.recommend
																		WHEN Customer.roleid = 3 THEN ciDownline.mrecommend
																		WHEN Customer.roleid = 4 THEN ciDownline.srecommend
																		ELSE -1
																END
										AND	dbo.f_GetProductStatus(cpsDownline.bitmapHasSynced, @bitmapOrder_FishingWorld) = 0)
						THEN 0
					ELSE 1
			END AS SyncedFishingWorldDownline,
			-- Cricket
			@IsIMBC AS IsIMBC,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_Cricket),1) AS DisableCricket,
			CAST(CASE WHEN @IsIMBC = 1 AND @IsHidden_Cricket = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Cricket),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideCricket,
						
		   ci.credit,
		   e.currency as currencyname,
		   @remark as remark
	  FROM Customer WITH(nolock) 
		 INNER JOIN CustInfo as ci with(NOLOCK)
				 on Customer.CustID = ci.CustID --Shifu
		 INNER JOIN Exchange as e with (NOLOCK)
				 ON Customer.currency = e.exchangeid
		 LEFT JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid		

		-- Check isHidden AllBet
		--OUTER APPLY	dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(Customer.custid, @AllBet) AS sbhsc
		
		-- Upline Status
		LEFT JOIN	dbo.CustProductStatus AS cpsUpline WITH (NOLOCK)
				ON	cpsUpline.CustID =	CASE	WHEN Customer.roleid = 1 THEN Customer.recommend
												WHEN Customer.roleid = 2 THEN Customer.mrecommend
												ELSE Customer.srecommend
										END
		    
		 
	 WHERE Customer.custid = @custid

	
END