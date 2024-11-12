/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_Rpt_ExchangeDailyOanda_Sel]
	@FromDate SMALLDATETIME = NULL,
	@ToDate SMALLDATETIME = NULL 
AS 
/*
	Created: 20170411@Sophia 
	Task : Get ExchangeDailyOanda by Date
	DB: DBACC.bodb2
	Original: Lrf_GET_ExchangeRateOANDA 
	Revisions:
		- 20171124@Harper: Add 2 more base currencies TWD and PHP into OANDA service [RedmineID: #87042]
		- 20210223@Sol: Add 2 more base currencies BDT and INR into OANDA service - [RedmineID: #150479]
		- 20221107@Evan: Support Crypto Currency [RedmineID: #177844]
		- 20240123@Lewis: Add 2 more base currencies NPR & TRY [RedmineID: #200163]
		- 20240507@Kelvin: LAP - Support based currency JPY, MXN, NGN [RedmineID: #200904]
		- 20241111@Kelvin: LAP - Support BRL base currency [RedmineID: #208662]
*/	
BEGIN  
	SET NOCOUNT ON 

	IF ISNULL (@Fromdate,'')=''
		SELECT @Fromdate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	IF ISNULL(@Todate,'')=''
		SELECT @ToDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	SELECT
		ExchangeDate, CurrencyCode,
		EUR,
		USD,
		MYR,
		CNY,
		IDR,
		AUD,
		CHF,
		GBP,
		SGD,
		THB,
		INH,
		KRW,
		JPY,
		HKD,
		TWD,
		PHP,
		BDT,
		INR,
		NPR,
		TRY,
		MXN,
		NGN,
		BRL
	FROM (
		SELECT 
			edo.ExchangeDate,
			CASE 
				WHEN edo.Code = 'VND' THEN 'INH' 
				WHEN edo.Code = 'MMK' THEN 'MKK' 
				ELSE edo.Code
			END CurrencyCode,
			edo.EUR,
			edo.USD,
			edo.MYR,
			edo.CNY,
			edo.IDR / 1000 AS IDR,
			edo.AUD,
			edo.CHF,
			edo.GBP,
			edo.SGD,
			edo.THB,
			edo.VND / 1000 AS INH,
			edo.KRW,
			edo.JPY,
			edo.HKD,
			edo.TWD,
			edo.PHP,
			edo.BDT,
			edo.INR,
			edo.NPR,
			edo.TRY,
			edo.MXN,
			edo.NGN,
			edo.BRL,
			ROW_NUMBER() OVER(
				PARTITION BY edo.ExchangeDate, CASE WHEN edo.Code = 'VND' THEN 'INH' WHEN edo.Code = 'MMK' THEN 'MKK' ELSE edo.Code END
				ORDER BY edo.ActualRate ASC
			) AS RowNum
		FROM dbo.ExchangeDailyOanda edo WITH (NOLOCK)
			INNER JOIN Exchange ex WITH(NOLOCK) ON ex.ExchangeId = edo.ExchangeId
		WHERE 
			edo.ExchangeDate >= @fromdate AND edo.ExchangeDate <= @todate 
			AND ex.CurrencyType = 0
			AND edo.exchangeid <> 20
			AND edo.Code <> 'YNG'
	) AS A
	WHERE A.RowNum = 1
	ORDER BY ExchangeDate, CurrencyCode
END
GO