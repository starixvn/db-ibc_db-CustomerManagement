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
		- 20200428@Malcolm : re-order products [Redmine : #132760]

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
	--LiveCasino including SA Gaming, Sexy Gaming and Allbet --dummy products

	CREATE TABLE #TmpProductSettingDetail
	(
		SettingType SMALLINT,
		SportType SMALLINT,
		BetType SMALLINT,
		IsLive BIT,
		ProductID TINYINT,
		MaxPT TINYINT,
		MaxDiscount DECIMAL (9, 8),
		IsSync BIT,
		IsHidden BIT,
		IsDisabled BIT,
		SettingLevel TINYINT,
		DisplayOrder TINYINT,
		SettingStatus TINYINT,
		IntervalValue DECIMAL (19, 8),
		bitmapOrder INT
	)

	INSERT INTO #TmpProductSettingDetail ([SettingType] ,[SportType],[BetType],[IsLive],[ProductID],[MaxPT],[MaxDiscount],[IsSync],[IsHidden],[IsDisabled],[SettingLevel],[DisplayOrder],[SettingStatus],[IntervalValue],[bitmapOrder]) VALUES(6,211,2401,0,21,NULL,NULL,NULL,NULL,NULL,2,4,0,NULL,6)
	INSERT INTO #TmpProductSettingDetail ([SettingType] ,[SportType],[BetType],[IsLive],[ProductID],[MaxPT],[MaxDiscount],[IsSync],[IsHidden],[IsDisabled],[SettingLevel],[DisplayOrder],[SettingStatus],[IntervalValue],[bitmapOrder]) VALUES(6,243,3101,0,45,NULL,NULL,NULL,NULL,NULL,2,4,0,NULL,22)
	INSERT INTO #TmpProductSettingDetail ([SettingType] ,[SportType],[BetType],[IsLive],[ProductID],[MaxPT],[MaxDiscount],[IsSync],[IsHidden],[IsDisabled],[SettingLevel],[DisplayOrder],[SettingStatus],[IntervalValue],[bitmapOrder]) VALUES(6,244,3001,0,39,NULL,NULL,NULL,NULL,NULL,2,4,0,NULL,20)

	INSERT INTO	@Products (BetType, SportType, ProductName, ProductID)
	SELECT DISTINCT T.BetType, T.SportType, p.ProductName, p.ProductID
	FROM	dbo.CustProductStatus		AS cps	WITH (NOLOCK)
	CROSS JOIN	dbo.ProductStatusProfile	AS psp	WITH (NOLOCK)
	INNER JOIN #TmpProductSettingDetail	AS t	WITH (NOLOCK) ON t.SportType = psp.Sporttype AND T.BetType = psp.Bettype
	INNER JOIN	dbo.Products AS p	WITH (NOLOCK)
			ON	p.ProductID =t.ProductID
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
	INNER JOIN	dbo.f_CustSetting_SportBetTypeSettingSelect(NULL, 6) AS sbss
			ON	sbss.SportType = psp.Sporttype
			AND	sbss.BetType = psp.Bettype
	INNER JOIN	dbo.Products				AS p	WITH (NOLOCK)
			ON	p.ProductID = sbss.ProductID
	CROSS APPLY	(
		SELECT	dbo.f_GetProductStatus(cps.bitmapHasSynced, psp.bitmapOrder)
			,	dbo.f_GetProductStatus(cps.bitmapIsHidden, psp.bitmapOrder)
	) ps(isSynced, isHidden)
	WHERE	cps.CustID = @CustId
		AND	ps.isSynced = 1
		AND	ps.isHidden = 0
		AND psp.Sporttype NOT IN (211,244,243) --Prevent duplicate of SAGaming,Allbet, SexyGaming

	--DELETE	p
	--FROM		@Products AS p
	--INNER JOIN	dbo.f_CustSetting_SportBetTypeHiddenBySiteCurrency(@CustId, NULL) AS sbhsc
	--		ON	sbhsc.SportType = p.SportType
	--		AND	sbhsc.BetType = p.BetType
	--WHERE	sbhsc.IsHidden = 1

	SELECT p.BetType, 
	       p.SportType,
		   p.ProductName, 
		   p.ProductID,
		   ISNULL(d.OrderNo,0) AS OrderNo,
		   CASE WHEN d.CasinoType = 1 THEN 53
		        WHEN d.CasinoType = 2 THEN 41
				ELSE 0 END
	FROM @Products p
		INNER JOIN dbo.Products d WITH(NOLOCK) ON p.ProductID = d.ProductID
	ORDER BY d.OrderNo

	DROP TABLE #TmpProductSettingDetail
END
GO

