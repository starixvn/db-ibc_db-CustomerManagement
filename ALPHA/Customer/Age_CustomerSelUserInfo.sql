/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
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
	- 20160801@Elodie: Implementing NewProductStatus Plugin - [Redmine #70722]	
	- 20170417@Winnie: Change to call the sp Acc_CheckShowProduct - [Redmine #72336]	
	- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
	- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
	- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]

Param's Explanation:
	@custid: custid that need to be viewed.   
*/

	SET NOCOUNT ON

	declare @roleid tinyint
	declare @remark nvarchar(300) = ''
	DECLARE @Site VARCHAR(10),@HasDownline INT=0,@IsDisabledDownline BIT=0
	
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
	-- casino
	IF @RoleID=2
		BEGIN		
			IF EXISTS(SELECT 1	FROM dbo.CustInfo WITH (NOLOCK)	WHERE recommend = @CustID AND roleid=1 AND SyncCasino=1)
					SELECT @HasDownline=1
			IF @HasDownline=1
			BEGIN
				IF EXISTS(SELECT 1 FROM  custInfo WITH(NOLOCK) WHERE recommend=@custid AND DisableCasino=1 AND SyncCasino=1)
					SELECT @IsDisabledDownline=1			
			END
		END		
		ELSE IF @RoleID=3
		BEGIN	
			
			IF EXISTS(SELECT 1	FROM dbo.CustInfo WITH (NOLOCK)	WHERE mrecommend = @CustID AND roleid=2 AND SyncCasino=1)
				SELECT @HasDownline=1
			IF @HasDownline=1
			BEGIN
				IF EXISTS(SELECT 1 FROM  custInfo WITH(NOLOCK) WHERE mrecommend=@custid AND DisableCasino=1 AND SyncCasino=1)
					SELECT @IsDisabledDownline=1
			
			END
		END
		ELSE IF @RoleID=4	
		BEGIN	
			
			IF EXISTS(SELECT 1	FROM dbo.CustInfo WITH (NOLOCK)	WHERE srecommend = @CustID AND roleid=3 AND SyncCasino=1)
				SELECT @HasDownline=1
			IF @HasDownline=1
			BEGIN				
				IF EXISTS(SELECT 1 FROM custInfo WITH(NOLOCK) WHERE srecommend=@custid AND DisableCasino=1 AND SyncCasino=1)
				BEGIN				
					SELECT @IsDisabledDownline=1						
				END
			
			END
		END	
	-- For DCS
	 
    DECLARE	@bitmapOrder_MuayThai		INT
		,	@bitmapOrder_CockFighting	INT
		,	@bitmapOrder_Cricket		INT
		,	@bitmapOrder_AllBet			INT
		,	@bitmapOrder_VoidBridge		INT
		,	@bitmapOrder_Lottery		INT
		,	@bitmapOrder_NG2			INT
		,	@bitmapOrder_Lucky3			INT
		,	@bitmapOrder_FishingWorld	INT	
		,	@bitmapOrder_VS				INT
    
    SET @bitmapOrder_MuayThai = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 44 AND Bettype = 3)
    SET @bitmapOrder_CockFighting = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 206 AND Bettype = 1003)
    SET @bitmapOrder_Cricket = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 50 AND Bettype = 501)
	SET @bitmapOrder_VoidBridge = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 212 AND Bettype = 4001)
	SET @bitmapOrder_Lottery = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 220 AND Bettype = 1021)
	SET @bitmapOrder_NG2 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 213 AND Bettype = 2501)
	SET @bitmapOrder_Lucky3 = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 160 AND Bettype = 1601)
	SET @bitmapOrder_FishingWorld = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 219 AND Bettype = 1011)
	SET @bitmapOrder_VS = (SELECT bitmapOrder FROM ProductStatusProfile WITH (NOLOCK) WHERE Sporttype = 180 AND Bettype = 1201)

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
		,	@IsHidden_Lottery		INT = 1
		,	@IsHidden_NG2			INT = 1
		,	@IsHidden_Lucky3		INT = 1    
		,	@IsHidden_FishingWorld	INT = 1	
		,	@IsHidden_VS			INT = 1
	EXEC Acc_CheckShowProduct @ProductID = 16, @IsHide = @IsHidden_MuayThai OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 19, @IsHide = @IsHidden_CockFighting OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 20, @IsHide = @IsHidden_Cricket OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 21, @IsHide = @IsHidden_AllBet OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 22, @IsHide = @IsHidden_VoidBridge OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 28, @IsHide = @IsHidden_Lottery OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 23, @IsHide = @IsHidden_NG2 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 26, @IsHide = @IsHidden_Lucky3 OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 24, @IsHide = @IsHidden_FishingWorld OUTPUT
	EXEC Acc_CheckShowProduct @ProductID = 5,  @IsHide = @IsHidden_VS OUTPUT

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
		   @HasDownline AS HasDownline,
		   @IsDisabledDownline AS DisableCasinoDownline,
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
			--Lottery
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_Lottery),1) AS DisableLottery,
			CAST(CASE WHEN @IsHidden_Lottery = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Lottery),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideLottery,
			
			-- NG2
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_NG2),1) AS DisableNG2,
			CAST(CASE WHEN @IsHidden_NG2 = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_NG2),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideNG2,
			ISNULL(dbo.f_GetProductStatus(cps.bitmapHasSynced, @bitmapOrder_NG2), 0) AS SyncedNG2,
			ISNULL(dbo.f_GetProductStatus(cpsUpline.bitmapHasSynced, @bitmapOrder_NG2), 0) AS SyncedNG2Upline,

			--VS
			ISNULL(dbo.f_GetProductStatus(cps.bitmapIsDisabled, @bitmapOrder_VS),1) AS DisableVirtualSports,
			CAST(CASE WHEN @IsHidden_VS = 0 AND ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_VS),1) = 0 THEN 0 ELSE 1 END AS BIT) AS HideVirtualSports,
		
			-- For Lucky3
			(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapIsDisabled, @bitmapOrder_Lucky3)) AS DisableLucky3,		
			CAST(	CASE	WHEN	@IsHidden_Lucky3 = 0 						
								AND	ISNULL(dbo.f_GetProductStatus(cps.bitmapIsHidden, @bitmapOrder_Lucky3), 1) = 0 
								THEN 0
							ELSE 1 
					END AS BIT) AS HideLucky3,			

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
GO
