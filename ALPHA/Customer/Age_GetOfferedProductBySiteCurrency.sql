/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Age_GetOfferedProductBySiteCurrency]
	@Site VARCHAR(50), 
	@Currency INT,
	@SettingStatus TINYINT=0
AS
/*
    Created: 20231031@Tacy  
	Task : Get all product which offered for Site/Currency
	DB: DBAGE/bodb02
  
	Revisions:
		- 20231031@Tacy: Create SP [Redmine: #196141] 
		- 20231206@Tacy: offer Saba Promotion, exclude 789y, 777 [Redmine: #194981]
		- 20240111@Johnson: exclude saba casino from dummy products [redmine: #194591]
	Examples:
	
*/
BEGIN
    SET NOCOUNT ON

	CREATE TABLE #SportBettypeDummy(RealProductId TINYINT, SportType SMALLINT,Bettype SMALLINT, IsHidden BIT DEFAULT(1), ProductId TINYINT)

	CREATE TABLE #OfferProduct (ProductID TINYINT PRIMARY KEY, IsHidden BIT)

	CREATE TABLE #Products (
		 ProductID TINYINT PRIMARY KEY
		,ProductName VARCHAR(50)
		,EndOfSupportDate DATE
		,OrderNo INT
		,[Type] TINYINT
		,SportType SMALLINT
		,BetType INT
	)

	INSERT INTO #Products (ProductID, ProductName, EndOfSupportDate, OrderNo, [Type])
	SELECT
		CAST(ISNULL(gp.GroupProductId, p.ProductID) AS INT) AS ProductID
	   ,p.ProductName
	   ,p.EndOfSupportDate
	   ,ISNULL(p.OrderNo,0) AS OrderNo
	   ,CASE WHEN p.CasinoType = 1 THEN 53
	         WHEN p.CasinoType = 2 THEN 41		
			 ELSE 0 END AS [Type]
	FROM dbo.Products p WITH (NOLOCK)
		LEFT JOIN dbo.f_GroupProduct() gp ON p.ProductID = gp.ProductId AND gp.ProductId <> gp.GroupProductId
	WHERE p.GroupType = 0 AND gp.ProductId IS NULL AND p.Enabled=1
		AND Environment <= @SettingStatus

	--Check: IMBC site???
	DECLARE @IsIMBC BIT = 0, @SiteID INT

	SELECT	@IsIMBC = CASE WHEN [Site] = 'IMBC' THEN 1 ELSE 0 END
		, @SiteID=S.siteid
	FROM Site s WITH (NOLOCK)
    WHERE s.[Site]=@Site
    
	CREATE TABLE #SportBettypeFilter (ProductID TINYINT, SportType SMALLINT,Bettype SMALLINT)

	CREATE TABLE #ProductSettingType(
		SettingType	tinyint,
		SettingName	varchar(30)
	)

	INSERT INTO #ProductSettingType(SettingType,SettingName)
	SELECT SettingType,SettingName 
	FROM DBCUST.CUSTDB.dbo.ProductSettingType WITH(NOLOCK) 
	WHERE SettingName IN('Product Status')

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype)
	SELECT p.RealProductId,p.SportType,p.Bettype
	FROM dbo.f_CustSetting_ProductSettingDetailSel(@SettingStatus) p
		INNER JOIN #ProductSettingType t ON p.SettingType = t.SettingType
	
	INSERT INTO #OfferProduct (ProductID, IsHidden)
	SELECT DISTINCT ft.ProductID, 
			CAST(CASE WHEN @IsIMBC = 0 AND ft.ProductID = 20 THEN 1 
				ELSE dbo.f_CustSetting_GetSportOfferStatusBySiteCurrency(@SiteID,@Currency,ft.Sporttype,ft.Bettype,@SettingStatus) END AS BIT) AS isHidden
	FROM #SportBettypeFilter ft 

	--Get RNG slot & live CS
	INSERT INTO #SportBettypeDummy (RealProductId, SportType, Bettype, ProductId, IsHidden)
	SELECT p.ProductID, s.SportType, s.BetType, s.DummyProductID
		,CASE WHEN dm.isHidden=0 THEN dbo.f_CustSetting_GetSportOfferStatusBySiteCurrency(@SiteID,@Currency,s.Sporttype,s.Bettype,@SettingStatus)
				WHEN dm.isHidden=1 THEN dm.isHidden END AS isHidden
	FROM Products p WITH (NOLOCK)
	OUTER APPLY (SELECT TOP 1 s.RealProductID, s.SportType, s.BetType,
						CASE WHEN p.CasinoType=1 THEN 18 ELSE 41 END AS DummyProductID
				 FROM SportNonOfferedSiteCurrency s WITH (NOLOCK)
				 WHERE s.RealProductID=p.ProductID) s
	LEFT JOIN #OfferProduct dm ON s.DummyProductID = dm.ProductID
	WHERE CasinoType IN (1,2) AND Enabled=1 AND GroupType=0
		AND p.ProductID NOT IN (6,11) -- AG Casino, offer for licensee only
		AND p.Environment <= @SettingStatus

	--Get data
	SELECT DISTINCT p.ProductID, p.ProductName, isnull(r.isHidden,0) isHidden, p.EndOfSupportDate, p.OrderNo, p.[Type]
	FROM (
		SELECT ProductID, isHidden FROM #OfferProduct
		UNION 
		SELECT 1, 0 --Sportbook always offer for all customer
		--RNG Slot & Live CS
		UNION
		SELECT dm.RealProductId, dm.IsHidden FROM #SportBettypeDummy dm
		) r
		INNER JOIN #Products p WITH (NOLOCK) ON p.ProductID = r.ProductID
	UNION
	SELECT p.ProductID, p.ProductName, 
			CASE WHEN dbo.f_Age_OfferedProductBySite(@Site)=1 THEN 0 ELSE 1 END isHidden, 
			p.EndOfSupportDate, p.OrderNo, p.[Type]
	FROM #Products p
	WHERE ProductID=37
	ORDER BY [Type], OrderNo

	DROP TABLE #OfferProduct
	DROP TABLE #ProductSettingType
	DROP TABLE #SportBettypeFilter
	DROP TABLE #SportBettypeDummy, #Products
END
GO