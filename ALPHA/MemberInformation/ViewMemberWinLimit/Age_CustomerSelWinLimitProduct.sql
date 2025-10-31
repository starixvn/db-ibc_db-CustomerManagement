/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Age_CustomerSelWinLimitProduct
	@CustId INT
	, @SettingStatus TINYINT = 0
AS
/*  
	Created: 20150714@Patrick
	Task : Get product list
	DB: DBAGE/bodb02
	Revisions: 
		- 20151223@Patrick:	Add Max/Loss limit for RnG Casino [Redmine: #49528]
		- 20160216@Billy:	Integrate to support DCS Products - [Redmine: #52268]
		- 20160413@Billy:	Remove Site Currency check - [Redmine: #54672]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20180814@Elodie: Return ProductID [RedmineID: #97675]
		- 20200316@Tiara: Return result for SA Gaming and Allbet [RedmineID: #128058]
		- 20200321@Tiara: Add Sexy Gaming Product [Redmine: #130678]
		- 20200406@Elodie: Add BBIN Product [Redmine: #131363]
		- 20200403@Elodie: Add Table Games Product [Redmine: #129440]
		- 20200428@Malcolm : re-order products [Redmine : #132760]
		- 20201009@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20210323@Johnson: hide setting GoldDeluxe [redmine:#151188]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230731@Eden: Simplify Live Casino Customer Setting - [Redmine: #189389]
		- 20230929@Tacy: Non-sports products - Remove GDG and Fishing World [RedmineID: #174511]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
		- 20231213@Tacy: Live Casino - Hide un-launched product from Member Win Loss Limit page [Redmine: #198317]
		- 20240314@Helios: Unify Live RNG Casino [Redmine: #198960]
		- 20240521@Helios: Unify RNG Games [Redmine: #204358]
		- 202511031@Dave: Adjust Live Casino PT & Commission [Redmine: #242260]

	Param's Explanation: 
		- @SettingStatus: 0: Pro, 1: UAT
*/  
BEGIN
	DECLARE @Products TABLE(BetType SMALLINT, SportType SMALLINT, ProductName VARCHAR(50), ProductID TINYINT)
	DECLARE @Currency INT, @SiteID INT, @site NVARCHAR(50);

	--Product Status
	SELECT	@SiteID = s.siteid,
			@Currency = c.currency,
			@site = s.site
	FROM customer c WITH (NOLOCK)
	    INNER JOIN Site s WITH (NOLOCK) ON c.site = s.site	
    WHERE c.custid = @custid
	
	-- For DCS Product
	INSERT INTO	@Products (BetType, SportType, ProductName, ProductID)
	SELECT DISTINCT sbss.BetType, sbss.SportType, p.ProductName, p.ProductID
	FROM		dbo.CustProductStatus		AS cps	WITH (NOLOCK)
	CROSS JOIN	dbo.ProductStatusProfile	AS psp	WITH (NOLOCK)
	INNER JOIN	dbo.f_CustSetting_ProductProfileSel(6,@SettingStatus,@siteid,@currency) AS sbss
			ON	sbss.SportType = psp.Sporttype
			AND	sbss.BetType = psp.Bettype
	INNER JOIN	dbo.f_CustSetting_Product 	(@SettingStatus) AS p
			ON	p.ProductID = sbss.RealProductId
	CROSS APPLY	(
		SELECT	dbo.f_GetProductStatus(cps.bitmapHasSynced, psp.bitmapOrder)
			,	dbo.f_GetProductStatus(cps.bitmapIsHidden, psp.bitmapOrder)
	) ps(isSynced, isHidden)
	WHERE	cps.CustID = @CustId
		AND	ps.isSynced = 1
		AND	ps.isHidden = 0
		
	-- For DCS Product
	INSERT INTO	@Products (BetType, SportType, ProductName, ProductID)
	SELECT DISTINCT sbss.BetType, sbss.SportType, p.ProductName, p.ProductID
	FROM		dbo.CustProductStatus		AS cps	WITH (NOLOCK)
	CROSS JOIN	dbo.ProductStatusProfile	AS psp	WITH (NOLOCK)
	INNER JOIN	dbo.f_CustSetting_ProductProfileSel(12,@SettingStatus,@siteid,@currency) AS sbss
			ON	sbss.SportType = psp.Sporttype
			AND	sbss.BetType = psp.Bettype
	INNER JOIN	dbo.f_CustSetting_Product 	(@SettingStatus) AS p
			ON	p.ProductID = sbss.RealProductId
	CROSS APPLY	(
		SELECT	dbo.f_GetProductStatus(cps.bitmapHasSynced, psp.bitmapOrder)
			,	dbo.f_GetProductStatus(cps.bitmapIsHidden, psp.bitmapOrder)
	) ps(isSynced, isHidden)
	WHERE	cps.CustID = @CustId
		AND	ps.isSynced = 1
		AND	ps.isHidden = 0

	--> Add for settingtype 22 
	CREATE TABLE #SportBetype(
		[SportType] [smallint],
		[BetType] [smallint],
		[RealProductId] [tinyint],
		[ProductId] [tinyint]
	)

	INSERT INTO #SportBetype(SportType,BetType,RealProductId,ProductId)
	SELECT st.SportType
		,st.BetType
		,st.RealProductId
		,s.productID
	FROM	dbo.f_CustSetting_ProductProfileSel(22, @SettingStatus,@siteid,@currency) AS s
		INNER JOIN f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) AS st
			ON st.SporttypeRefWinlossLimit = s.SportType 
			AND st.BettypeRefWinlossLimit = s.Bettype
			AND st.isLicensee = 0 AND st.Site IN( @site, 'ALL')
			AND st.isDeleted = 0

	INSERT INTO	@Products (BetType, SportType, ProductName, ProductID)
	SELECT DISTINCT sbss.BetType, sbss.SportType, p.ProductName, p.ProductID
	FROM		dbo.CustProductStatus		AS cps	WITH (NOLOCK)
	CROSS JOIN	dbo.ProductStatusProfile	AS psp	WITH (NOLOCK)
	INNER JOIN	#SportBetype AS sbss
			ON  CASE WHEN sbss.ProductId = 41 THEN 9911 
				   WHEN sbss.SportType IN (202,220,222) THEN 9919
				ELSE sbss.SportType END = psp.Sporttype
			AND	CASE WHEN sbss.ProductId = 41 THEN 2400
				     WHEN sbss.BetType IN (1501,1021,4901) THEN 1501
				ELSE sbss.BetType END = psp.Bettype
	INNER JOIN	dbo.f_CustSetting_Product 	(@SettingStatus) AS p
			ON	p.ProductID = sbss.RealProductId
	CROSS APPLY	(
		SELECT	dbo.f_GetProductStatus(cps.bitmapHasSynced, psp.bitmapOrder)
			,	dbo.f_GetProductStatus(cps.bitmapIsHidden, psp.bitmapOrder)
	) ps(isSynced, isHidden)
	CROSS APPLY	( SELECT dbo.f_CustSetting_GetSportOfferStatusBySiteCurrency(@SiteID,@Currency,sbss.Sporttype,sbss.Bettype,@SettingStatus)
				) dm (IsHidden)
	WHERE	cps.CustID = @CustId
		AND	ps.isSynced = 1
		AND	ps.isHidden = 0 --Dummy Product must offerred
		AND (dm.IsHidden = 0  OR sbss.ProductId <> 41)--real Product under live casino must offerred

	SELECT p.BetType, 
		   p.SportType, 
		   CASE WHEN p.SportType = 9918 THEN 'Other RNG Casino' ELSE p.ProductName END AS ProductName,
		   p.ProductID,
		   ISNULL(d.OrderNo,0) AS OrderNo,
		   CASE WHEN d.CasinoType = 1 THEN 53
		        WHEN d.CasinoType = 2 THEN 41
				ELSE 0 END AS [Type]
	FROM @Products p 
		INNER JOIN f_CustSetting_Product (@SettingStatus) AS d ON 
		p.ProductID = d.ProductID 
		AND d.Enabled = 1
		AND d.Environment<=@SettingStatus

	ORDER BY d.OrderNo ASC

	DROP TABLE #SportBetype
END
GO

