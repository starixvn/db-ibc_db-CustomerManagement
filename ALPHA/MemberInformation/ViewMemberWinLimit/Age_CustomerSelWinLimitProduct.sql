/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb02
GO 

ALTER PROCEDURE dbo.Age_CustomerSelWinLimitProduct @CustId INT
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

	Param's Explanation: 
*/  
BEGIN
	DECLARE @Products TABLE(BetType SMALLINT, SportType SMALLINT, ProductName VARCHAR(50), ProductID TINYINT)
	--gold deluxe
	IF EXISTS (SELECT 1	FROM dbo.custInfo WITH(NOLOCK)	WHERE CustId = @CustId AND HideGoldDeluxe = 0)
	BEGIN
		INSERT INTO @Products(BetType, SportType, ProductName, ProductID)
		SELECT 1701, 255, ProductName, ProductID
		FROM dbo.Products WITH(NOLOCK) WHERE ProductID = 12
		--VALUES(1701, 255, 'Gold Deluxe')
	END

	--RnG Casino
	IF EXISTS (SELECT 1	FROM dbo.custInfo WITH(NOLOCK)	WHERE CustId = @CustId AND SyncCasino = 1)
	BEGIN
		INSERT INTO @Products(BetType, SportType, ProductName, ProductID)
		SELECT 2101, 208, ProductName, ProductID
		FROM dbo.Products WITH(NOLOCK) WHERE ProductID = 6
	END
	INSERT INTO #TmpProductSettingDetail ([SettingType] ,[SportType],[BetType],[IsLive],[ProductID],[MaxPT],[MaxDiscount],[IsSync],[IsHidden],[IsDisabled],[SettingLevel],[DisplayOrder],[SettingStatus],[IntervalValue],[bitmapOrder]) VALUES(6,241,3300,0,47,NULL,NULL,NULL,NULL,NULL,2,4,0,NULL,24)
	
	-- For DCS Product
	INSERT INTO	@Products (BetType, SportType, ProductName, ProductID)
	SELECT DISTINCT sbss.BetType, sbss.SportType, p.ProductName, p.ProductID
	FROM		dbo.CustProductStatus		AS cps	WITH (NOLOCK)
	CROSS JOIN	dbo.ProductStatusProfile	AS psp	WITH (NOLOCK)
	INNER JOIN	dbo.f_CustSetting_SportBetTypeSettingSelect(NULL, 6) AS sbss
			ON	sbss.SportType = psp.Sporttype
			AND	sbss.BetType = psp.Bettype
	INNER JOIN	dbo.Products				AS p	WITH (NOLOCK)
			ON	p.ProductID = sbss.RealProductId
	CROSS APPLY	(
		SELECT	dbo.f_GetProductStatus(cps.bitmapHasSynced, psp.bitmapOrder)
			,	dbo.f_GetProductStatus(cps.bitmapIsHidden, psp.bitmapOrder)
	) ps(isSynced, isHidden)
	WHERE	cps.CustID = @CustId
		AND	ps.isSynced = 1
		AND	ps.isHidden = 0
		AND psp.Sporttype NOT IN (211,244,243,241) --Prevent duplicate of SAGaming,Allbet, SexyGaming

	--DELETE	p
	--FROM		@Products AS p
	--INNER JOIN	dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(@CustId, NULL) AS sbhsc
	--		ON	sbhsc.SportType = p.SportType
	--		AND	sbhsc.BetType = p.BetType
	--WHERE	sbhsc.IsHidden = 1

	SELECT BetType, SportType, ProductName, ProductID
	FROM @Products
END
GO

