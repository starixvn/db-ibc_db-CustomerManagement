/*<info serverAlias="DBAGE-bodb02" executers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Rpt_ExchangeDailyOanda_USD_Sel]
	@FromDate SMALLDATETIME = NULL,
	@ToDate SMALLDATETIME = NULL 
AS
/*
	Created: 20240916@Lewis 
	Task : Get ExchangeDailyOanda by Date (to USD only)
	DB: DBAGE.bodb2
	Revisions:
		- 20240916@Lewis : Initialize SP [RedmineID: #210673]
	
	EXEC [Acc_Rpt_ExchangeDailyOanda_USD_Sel]
	@fromdate ='20240808'
	,@todate='20240908'
*/
BEGIN  
	SET NOCOUNT ON 

	IF ISNULL (@Fromdate,'')=''
		SELECT @Fromdate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	IF ISNULL(@Todate,'')=''
		SELECT @ToDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	-- =========================
	-- 1.Get standard code
	-- =========================
	DROP TABLE IF EXISTS #tmpExchange
	CREATE TABLE #tmpExchange (
		ExchangeId INT
		, Code VARCHAR(12)
		, MultipliedBy DECIMAL(19,8)
	)
	INSERT INTO #tmpExchange (
		ExchangeId
		, Code
		, MultipliedBy
	)
	SELECT DISTINCT
		ExchangeId
		, Code
		, MultipliedBy
	FROM Exchange WITH (NOLOCK)  
	WHERE ISNULL(Code,'') <> ''   -- UUS
	AND Code NOT IN ('C', 'H','YNG','SBC','DIA','BTS','UUS')  
	AND CurrencyType = 0
	AND IsActive = 1

	-- =========================
	-- 2.Get oanda rate for step1 
	-- =========================
	DROP TABLE IF EXISTS #tmpOandaRate
	CREATE TABLE #tmpOandaRate (
		ExchangeDate SMALLDATETIME
		, Code VARCHAR(12)
		, USD DECIMAL(19,8)
	)
	INSERT INTO #tmpOandaRate (
		ExchangeDate
		, Code
		, USD
	)
	SELECT 
		edo.ExchangeDate
		, edo.Code
		, CAST(edo.USD AS DECIMAL(19,8)) / ex.MultipliedBy
	FROM dbo.ExchangeDailyOanda edo WITH (NOLOCK)
	INNER JOIN #tmpExchange ex WITH(NOLOCK) 
		ON ex.ExchangeId = edo.ExchangeId
	WHERE 
		edo.ExchangeDate >= @fromdate AND edo.ExchangeDate <= @todate 

	-- =========================
	-- 3.Result 
	-- =========================
	SELECT DISTINCT
			edo.ExchangeDate,
			edo.Code,
			edo.USD
	FROM #tmpOandaRate edo 
    ORDER BY edo.ExchangeDate,edo.Code ASC

END
GO

