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
		- 20240314@Helios: Unify Live RNG Casino [Redmine: #198960]
		- 20251031@Dave: Adjust Live Casino PT & Commission [Redmine: #242260]
	Examples:
		EXEC [Acc_GetProductList] @Type = 1, @CustID = 28529050 , @SettingStatus = 3
		EXEC [Acc_GetProductList] @Type = 2, @CustID = 28529050 , @SettingStatus = 3
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #ProductsettingType (SettingType tinyint)
	CREATE TABLE #TempProduct (ProductID tinyint, GroupID TINYINT)
	CREATE TABLE #Product_NonOffer (ProductID tinyint)
	CREATE TABLE #SportOfferStatus (sporttype smallint, bettype smallint, IsHidden BIT)
	CREATE NONCLUSTERED INDEX IX_NonOfferSport ON #SportOfferStatus(sporttype,bettype)
	DECLARE @SiteID INT , @Currency INT, @site NVARCHAR(50)

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

	SELECT @Currency = ci.currency, @SiteID = s.siteid, @site = s.site
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
		SELECT ISNULL(st.RealProductId, d.RealProductId) AS RealProductId,d.GroupID,
			RN = ROW_NUMBER() OVER ( PARTITION BY ISNULL(st.RealProductId, d.RealProductId) ORDER by d.SportType ASC, d.BetType ASC)
		FROM dbo.f_CustSetting_ProductProfileSel (NULL,@SettingStatus,@SiteID,@Currency) d 
			INNER JOIN #ProductsettingType t ON d.SettingType = t.SettingType
			LEFT JOIN f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) AS st 
				ON st.SportType = d.SportType AND st.BetType = d.BetType
				AND st.isLicensee = 0 AND st.Site IN (@site, 'ALL') AND st.isDeleted = 0
			LEFT JOIN #SportOfferStatus non ON d.SportType = non.sporttype AND d.BetType = non.bettype AND non.IsHidden = 1
		WHERE non.sporttype IS NULL 
		)
	INSERT INTO #TempProduct(ProductID,GroupID)
	SELECT RealProductId,GroupID
	FROM Tmp t
	WHERE RN = 1
		AND NOT EXISTS ( SELECT 1 FROM #Product_NonOffer WHERE t.RealProductId = ProductID)
	--SB
	UNION SELECT 1,1

	SELECT t.ProductID,
		p.ProductName,
		p.EndOfSupportDate,
		ISNULL(p.OrderNo,0) AS OrderNo,
		--CASE WHEN p.CasinoType = 1 THEN 53  
		--	ELSE 0 END 
		0	AS [Type],
		t.GroupID
	FROM #TempProduct t
		INNER JOIN f_CustSetting_Product (@SettingStatus) AS p  ON t.ProductID = p.ProductID 
	WHERE p.Enabled = 1
	AND p.Environment<=@SettingStatus
	ORDER BY OrderNo ASC
				
	DROP TABLE #ProductsettingType
	DROP TABLE #Product_NonOffer
	DROP TABLE #SportOfferStatus
	DROP TABLE #TempProduct
END
GO