/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_ProductCurrencySel] 
	-- Add the parameters for the stored procedure here
	 @pMutilProductID	VARCHAR(MAX) = ''
	,@pMutilCurrency	VARCHAR(MAX) = ''
	,@ExportData		INT	=	0
	,@PageSize			INT	=	50
	,@PageIndex			INT	=	0
	,@TotalRows 		INT	=	0 OUTPUT
AS
/*
		Task : NAP -  Flexible Initializing Bet Limit
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220708@Tacy: Create SP [Redmine: #174509]
		
		Param's Explanation:
			@ProductID		0 : All, <> 0 : ProductID
			@pMutilCurrency	0 : All, <> 0 : Currency Credit
			@ExportData		0 : Pages, <> 0 : All data

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @rowstart	INT,
			@rowend		INT

	SELECT	@RowStart = @PageSize * @PageIndex + 1, 
			@RowEnd = @RowStart + @PageSize - 1 	

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
		SELECT p.ProductID, p.ProductName, s.SportType, SportName, eC.Currency AS CurrencyCredit
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=psd.ProductID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
			INNER JOIN ProductBetSetting pbs WITH(NOLOCK) ON pbs.Sporttype=psd.SportType AND pbs.Bettype=psd.BetType
			INNER JOIN Exchange eC WITH(NOLOCK) ON eC.ExchangeId=pbs.Currency
		WHERE psd.SettingType IN (2,7,8,9,16,17,20) AND psd.ProductID NOT IN (1,3,8)
			AND (@pMutilProductID='0' OR psd.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
			AND (@pMutilCurrency='0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
	),
	ProductCurrency_dep AS (
		SELECT p.ProductID, p.ProductName, s.SportType, SportName, eD.Currency AS CurrencyDeposit
		FROM Dep_ProductSetting ps WITH(NOLOCK)
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Products p WITH(NOLOCK) ON p.ProductID=ps.ProductID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType	
			INNER JOIN Dep_ProductBetSetting pbs WITH(NOLOCK) ON pbs.Sporttype=psd.SportType AND pbs.Bettype=psd.BetType
			INNER JOIN Exchange eD WITH(NOLOCK) ON eD.ExchangeId=eD.Currency
		WHERE ps.SettingType IN (2,7,8,10,11,12)
			AND (@pMutilProductID='0' OR ps.ProductID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilProductID, ',')))
			AND (@pMutilCurrency='0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrency, ',')))
	)
	INSERT INTO #ProductCurrency (ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit)
	SELECT DISTINCT
		cre.ProductName, cre.SportType, cre.SportName, cre.CurrencyCredit, dep.CurrencyDeposit
	FROM ProductCurrency_credit cre
		LEFT JOIN ProductCurrency_dep dep ON dep.ProductID=cre.ProductID

	--ExportData
	IF @ExportData = 1
	BEGIN
		SELECT ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit
		FROM #ProductCurrency t
		ORDER by ProductName, SportType	
	END
	ELSE
	BEGIN
		SELECT @TotalRows = COUNT(1)
		FROM #ProductCurrency

		SELECT ProductName, SportType, SportName, CurrencyCredit, CurrencyDeposit
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER by ProductName, SportType) rn, *
			FROM #ProductCurrency
		   )t
		WHERE rn BETWEEN @RowStart AND @RowEnd
	END	


	DROP TABLE #Sports
	DROP TABLE #Products
	DROP TABLE #ProductCurrency
END
GO