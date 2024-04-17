/*<info serverAlias="DBAGE-bodb02" executers="wsv_nap,wsv_alp,wsv_xnap,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GetProductList]
	@CustID INT,
	@SettingStatus TINYINT = 0,
	@Type TINYINT = NULL--  1: PT, 2: Comm
AS

/*  
	Created: 20230731@Eden  
	Task : Get products list - Member Information - PT/Comm
	DB: DBAGE/bodb02  
  
	Revisions:
		- 20230731@Eden: Simplify Live Casino Customer Setting - [Redmine: #189389]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]

	Examples:
		EXEC [Acc_GetProductList] @Type = 1, @CustID = 28529050 , @SettingStatus = 3
		EXEC [Acc_GetProductList] @Type = 2, @CustID = 28529050 , @SettingStatus = 3
*/

BEGIN
	SET NOCOUNT ON
	CREATE TABLE #ProductsettingType (SettingType tinyint)
	CREATE TABLE #TempProduct (ProductID tinyint)
	CREATE TABLE #Product_NonOffer (ProductID tinyint)
	CREATE TABLE #SportOfferStatus (sporttype smallint, bettype smallint, IsHidden BIT)
	CREATE NONCLUSTERED INDEX IX_NonOfferSport ON #SportOfferStatus(sporttype,bettype)
	DECLARE @SiteID INT , @Currency INT

	IF @Type = 1
	BEGIN
		INSERT INTO #ProductsettingType(SettingType)
		SELECT SettingType 
		FROM DBCUST.CUSTDB.dbo.ProductsettingType WITH(NOLOCK) 
		WHERE SettingName = 'Position Taking'
	END
	ELSE 
	BEGIN
		INSERT INTO #ProductsettingType(SettingType)
		SELECT SettingType 
		FROM DBCUST.CUSTDB.dbo.ProductsettingType WITH(NOLOCK) 
		WHERE SettingName = 'Commission'
	END

	SELECT @Currency = ci.currency, @SiteID = s.siteid
	FROM customer ci WITH(NOLOCK) 
		INNER JOIN Site s WITH(NOLOCK) ON ci.site = s.site
	WHERE ci.custid = @CustID

	INSERT INTO #SportOfferStatus(sporttype,bettype,IsHidden)
	SELECT SportType,bettype, 1
	FROM SportNonOfferedSiteCurrency WITH(NOLOCK) 
	WHERE SiteID IN(0, @SiteID)
		AND Currency IN (0,@Currency)
	UNION
	SELECT SportType,bettype,IsHidden
	FROM ProductStatusSiteCurrency WITH(NOLOCK) 
	WHERE SiteID IN(0, @SiteID)
		AND Currency IN (0,@Currency)

	INSERT INTO #Product_NonOffer(ProductID)
	SELECT t.RealProductId
	FROM dbo.f_CustSetting_ProductSettingDetailSel(@SettingStatus) t
		LEFT JOIN #SportOfferStatus offer ON t.SportType = offer.sporttype AND t.BetType = offer.bettype AND offer.IsHidden = 0
	WHERE t.SettingType IN(4,11,13,21)
		AND t.IsHidden = 1
		AND offer.sporttype IS NULL

	;WITH Tmp AS(
		SELECT ISNULL(st.RealProductId, d.RealProductId) AS RealProductId,
			RN = ROW_NUMBER() OVER ( PARTITION BY ISNULL(st.RealProductId, d.RealProductId) ORDER by d.SportType,d.BetType)
		FROM dbo.f_CustSetting_ProductProfileSel (NULL,@SettingStatus,@SiteID,@Currency) d 
			INNER JOIN #ProductsettingType t ON d.SettingType = t.SettingType
			LEFT JOIN SportBettypeSettingMatrix st WITH(NOLOCK) ON st.SportType = d.SportType AND st.BetType = d.BetType AND st.isLicensee = 0 AND st.Site = 'ALL' AND st.isDeleted = 0
			LEFT JOIN #SportOfferStatus non ON d.SportType = non.sporttype AND d.BetType = non.bettype AND non.IsHidden = 1
		WHERE non.sporttype IS NULL 
		)
	INSERT INTO #TempProduct(ProductID)
	SELECT RealProductId
	FROM Tmp t
	WHERE RN = 1
		AND NOT EXISTS ( SELECT 1 FROM #Product_NonOffer WHERE t.RealProductId = ProductID)
	--SB
	UNION SELECT 1

	SELECT t.ProductID,
		p.ProductName,
		p.EndOfSupportDate,
		ISNULL(p.OrderNo,0) AS OrderNo,
		CASE WHEN p.CasinoType = 1 THEN 53  
			ELSE 0 END AS [Type] 
	FROM #TempProduct t
		INNER JOIN dbo.Products p WITH (NOLOCK) 
			ON t.ProductID = p.ProductID
	WHERE p.Enabled = 1
	ORDER BY OrderNo
				
	DROP TABLE #ProductsettingType
END
GO