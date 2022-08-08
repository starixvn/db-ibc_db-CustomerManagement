/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_ProductCurrencySel] 
	-- Add the parameters for the stored procedure here
	 @pMutilProductID	VARCHAR(MAX) = ''
	,@pMutilCurrency	VARCHAR(MAX) = ''
AS
/*
		Task : NAP -  Flexible Initializing Bet Limit
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220708@Tacy: Create SP [Redmine: #174509]
		
		Param's Explanation:
			@pMutilProductID 0 : All, <> 0 : ProductID
			@pMutilCurrency	 0 : All, <> 0 : Currency Credit

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #Sports (SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))

	CREATE TABLE #Products (ProductID TINYINT PRIMARY KEY, ProductName VARCHAR(50))

	CREATE TABLE #ProductCurrency (
			ProductName		VARCHAR(50),
			SportType		TINYINT,
			SportName		NVARCHAR(50),
			CurrencyCredit	NVARCHAR(50),
			CurrencyDeposit	NVARCHAR(50),
	)

	INSERT INTO #Products  (ProductID,ProductName)	
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)

	INSERT INTO #Sports (SportType, SportName)	
	SELECT SportType,SportName 
	FROM dbo.Sports WITH(NOLOCK)

	;WITH ProductCurrency_credit AS (
		SELECT DISTINCT
			p.ProductID, p.ProductName, s.SportType, SportName, eC.Currency AS CurrencyCredit
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=psd.ProductID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
			INNER JOIN ProductBetSetting pbs WITH(NOLOCK) ON pbs.Sporttype=psd.SportType
			INNER JOIN Exchange eC WITH(NOLOCK) ON eC.ExchangeId=pbs.Currency
		WHERE psd.SettingType IN (2,7,8,9,16,17,20) AND p.ProductID NOT IN (1,3,8)
			AND (@pMutilProductID='0' OR p.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
			AND (@pMutilCurrency='0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
	),
	ProductCurrency_dep AS (
		SELECT DISTINCT
			p.ProductID, p.ProductName, s.SportType, SportName, eD.Currency AS CurrencyDeposit
		FROM Dep_ProductSetting ps WITH(NOLOCK)
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=ps.ProductID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
			INNER JOIN Dep_ProductBetSetting pbs WITH(NOLOCK) ON pbs.Sporttype=psd.SportType
			INNER JOIN Exchange eD WITH(NOLOCK) ON eD.ExchangeId=pbs.Currency
		WHERE ps.SettingType IN (2,7,8,10,11,12)
			AND (@pMutilProductID='0' OR p.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
			AND (@pMutilCurrency='0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
	), 
	ProductCurrency AS (
		SELECT DISTINCT
			cre.ProductID, cre.ProductName, cre.SportType, cre.SportName, cre.CurrencyCredit, dep.CurrencyDeposit
		FROM ProductCurrency_credit cre
			INNER JOIN ProductCurrency_dep dep ON dep.ProductID=cre.ProductID AND cre.SportType=dep.SportType
	)
	INSERT INTO #ProductCurrency (ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit)
	SELECT ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit
	FROM ProductCurrency
	UNION
	SELECT ProductName, SportType, SportName, CurrencyCredit, NULL AS CurrencyDeposit
	FROM ProductCurrency_credit cre
	WHERE NOT EXISTS (SELECT 1 FROM ProductCurrency pc WHERE pc.ProductID=cre.ProductID AND pc.SportType=cre.SportType)
	UNION
	SELECT ProductName, SportType, SportName, NULL AS CurrencyCredit,  CurrencyDeposit
	FROM ProductCurrency_dep dep
	WHERE NOT EXISTS (SELECT 1 FROM ProductCurrency pc WHERE pc.ProductID=dep.ProductID AND pc.SportType=dep.SportType)

	--ExportData
	SELECT ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit
	FROM #ProductCurrency t
	ORDER by ProductName, SportType	

	DROP TABLE #Sports
	DROP TABLE #Products
	DROP TABLE #ProductCurrency
END
GO