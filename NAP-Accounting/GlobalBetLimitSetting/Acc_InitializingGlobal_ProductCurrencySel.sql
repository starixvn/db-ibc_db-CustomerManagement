/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_ProductCurrencySel] 
	-- Add the parameters for the stored procedure here
	 @pMutilProductID	VARCHAR(MAX) = ''
	,@pMutilCurrency	VARCHAR(MAX) = ''
	,@SettingStatus		TINYINT
AS
/*
		Task : NAP -  Flexible Initializing Bet Limit
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220708@Tacy: Create SP [Redmine: #174509]
			- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
			- 20230918@Tacy: NAP - Global betlimit - Support to initial setting on UAT [Redmine: #192557]
		
		Param's Explanation:
			@pMutilProductID 0 : All, <> 0 : ProductID
			@pMutilCurrency	 0 : All, <> 0 : Currency Credit

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #Sports (SportType SMALLINT PRIMARY KEY, SportName NVARCHAR(50))
	CREATE TABLE #Products (ProductID TINYINT PRIMARY KEY, ProductName VARCHAR(50))

	CREATE TABLE #ProductCurrency (
			ProductName		VARCHAR(50),
			SportType		SMALLINT,
			SportName		NVARCHAR(50),
			CurrencyCredit	NVARCHAR(50),
			CurrencyDeposit	NVARCHAR(50),
			RowNumber		TINYINT
	)

	CREATE TABLE #Credit_ProductCurrency (
			ProductID		TINYINT,
			ProductName		VARCHAR(50),
			SportType		SMALLINT,
			SportName		NVARCHAR(50),
			CurrencyCredit	NVARCHAR(50)
	)

	CREATE TABLE #Dep_ProductCurrency (
			ProductID		TINYINT,
			ProductName		VARCHAR(50),
			SportType		SMALLINT,
			SportName		NVARCHAR(50),
			CurrencyDeposit	NVARCHAR(50)
	)
	INSERT INTO #Products  (ProductID,ProductName)	
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)

	INSERT INTO #Sports (SportType, SportName)	
	EXEC Acc_SporttypeSel @Mode=1

	CREATE TABLE #ProductSettingDetail(
		[SettingType] [smallint],
		[SportType] [smallint],
		[BetType] [smallint],
		[IsLive] [bit] ,
		[ProductID] [tinyint],
	PRIMARY KEY([SettingType] ASC,[SportType] ASC,[BetType] ASC,[IsLive] ASC)
	)

	INSERT INTO #ProductSettingDetail(SportType,BetType,SettingType,IsLive,ProductID)
	SELECT SportType,BetType,SettingType,IsLive,ProductID
	FROM dbo.f_CustSetting_ProductSettingDetailSel(@SettingStatus)

	--CREDIT
	INSERT INTO #Credit_ProductCurrency (ProductID, ProductName, SportType, SportName, CurrencyCredit)
	SELECT DISTINCT
		p.ProductID, p.ProductName, s.SportType, SportName, eC.Currency AS CurrencyCredit
	FROM #ProductSettingDetail psd WITH(NOLOCK)
		INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=psd.ProductID
		INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
		INNER JOIN ProductBetSetting pbs WITH(NOLOCK) ON pbs.Sporttype=psd.SportType AND pbs.Bettype=psd.BetType
		INNER JOIN Exchange eC WITH(NOLOCK) ON eC.ExchangeId=pbs.Currency
	WHERE psd.SettingType IN (2,9,16,20) AND p.ProductID NOT IN (1,3,8)
		AND (@pMutilProductID='0' OR p.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
		AND (@pMutilCurrency='0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
	UNION
	SELECT DISTINCT
		p.ProductID, p.ProductName, s.SportType, SportName, eC.Currency AS CurrencyCredit
	FROM #ProductSettingDetail psd WITH(NOLOCK)
		INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=psd.ProductID
		INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
		INNER JOIN StakeLevel sl WITH(NOLOCK) ON sl.GameTypeID=psd.BetType
		INNER JOIN Exchange eC WITH(NOLOCK) ON eC.ExchangeId=sl.ExchangeId
	WHERE psd.SettingType IN (7,8,17)
		AND (@pMutilProductID='0' OR p.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
		AND (@pMutilCurrency='0' OR sl.ExchangeId IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))

	--DEPOSIT
	INSERT INTO #Dep_ProductCurrency (ProductID, ProductName, SportType, SportName, CurrencyDeposit)
	SELECT DISTINCT
		p.ProductID, p.ProductName, s.SportType, SportName, eD.Currency AS CurrencyDeposit
	FROM Dep_ProductSetting ps WITH(NOLOCK)
	INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
		INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=ps.ProductID
		INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
		INNER JOIN Dep_ProductBetSetting pbs WITH(NOLOCK) ON pbs.Sporttype=psd.SportType AND pbs.Bettype=psd.BetType
		INNER JOIN Exchange eD WITH(NOLOCK) ON eD.ExchangeId=pbs.Currency
	WHERE ps.SettingType IN (2,10,11,12)
		AND (@pMutilProductID='0' OR p.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
		AND (@pMutilCurrency='0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
		AND psd.SettingStatus<>2
	UNION
	SELECT DISTINCT
		p.ProductID, p.ProductName, s.SportType, SportName, eD.Currency AS CurrencyDeposit
	FROM Dep_ProductSetting ps WITH(NOLOCK)
	INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
		INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=ps.ProductID
		INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
		INNER JOIN Dep_StakeLevel sl WITH(NOLOCK) ON sl.GameTypeID=psd.BetType
		INNER JOIN Exchange eD WITH(NOLOCK) ON eD.ExchangeId=sl.ExchangeID
	WHERE ps.SettingType IN (7,8)
		AND (@pMutilProductID='0' OR p.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
		AND (@pMutilCurrency='0' OR sl.ExchangeID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
		AND psd.SettingStatus<>2
	
	--ProductCurrency
	;WITH ProductCurrency_credit AS (
		SELECT ProductID, ProductName, SportType, SportName, CurrencyCredit,
			ROW_NUMBER() OVER (PARTITION BY ProductID, SportType ORDER BY CurrencyCredit ASC) AS N
		FROM #Credit_ProductCurrency
	),
	ProductCurrency_dep AS (
		SELECT ProductID, ProductName, SportType, SportName, CurrencyDeposit,
			ROW_NUMBER() OVER (PARTITION BY ProductID, SportType ORDER BY CurrencyDeposit ASC) AS N
		FROM #Dep_ProductCurrency
	), 
	ProductCurrency AS (
		SELECT DISTINCT
			cre.ProductID, cre.ProductName, cre.SportType, cre.SportName, cre.CurrencyCredit, dep.CurrencyDeposit, cre.N
		FROM ProductCurrency_credit cre
			INNER JOIN ProductCurrency_dep dep ON dep.ProductID=cre.ProductID AND cre.SportType=dep.SportType AND cre.N=dep.N
	)
	INSERT INTO #ProductCurrency (ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit, RowNumber)
	SELECT ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit, N
	FROM ProductCurrency
	UNION
	SELECT ProductName, SportType, SportName, CurrencyCredit, NULL AS CurrencyDeposit, NULL
	FROM ProductCurrency_credit cre
	WHERE NOT EXISTS (SELECT 1 FROM ProductCurrency pc WHERE pc.ProductID=cre.ProductID AND pc.SportType=cre.SportType AND cre.N=pc.N)
	UNION
	SELECT ProductName, SportType, SportName, NULL AS CurrencyCredit,  CurrencyDeposit, NULL
	FROM ProductCurrency_dep dep
	WHERE NOT EXISTS (SELECT 1 FROM ProductCurrency pc WHERE pc.ProductID=dep.ProductID AND pc.SportType=dep.SportType AND dep.N=pc.N)


	--ExportData
	SELECT ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit
	FROM #ProductCurrency t
	ORDER BY ProductName, SportType, CurrencyCredit, CurrencyDeposit
	
	DROP TABLE #Sports
	DROP TABLE #Products
	DROP TABLE #Credit_ProductCurrency
	DROP TABLE #Dep_ProductCurrency
	DROP TABLE #ProductCurrency
	DROP TABLE #ProductSettingDetail
END
GO