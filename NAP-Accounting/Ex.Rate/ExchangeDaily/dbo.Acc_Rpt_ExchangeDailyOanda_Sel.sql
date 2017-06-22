/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

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
		HKD
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
			ROW_NUMBER() OVER(
				PARTITION BY edo.ExchangeDate, CASE WHEN edo.Code = 'VND' THEN 'INH' WHEN edo.Code = 'MMK' THEN 'MKK' ELSE edo.Code END
				ORDER BY edo.ActualRate ASC
			) AS RowNum
		FROM dbo.ExchangeDailyOanda edo WITH (NOLOCK)
		WHERE 
			edo.ExchangeDate >= @fromdate AND edo.ExchangeDate <= @todate 
			AND edo.exchangeid <> 20
			AND edo.Code <> 'YNG'
	) AS A
	WHERE A.RowNum = 1
	ORDER BY ExchangeDate, CurrencyCode
END
GO