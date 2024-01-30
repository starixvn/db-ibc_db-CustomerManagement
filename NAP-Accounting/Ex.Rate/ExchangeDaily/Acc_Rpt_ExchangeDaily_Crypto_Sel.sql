/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Rpt_ExchangeDaily_Crypto_Sel]
	@FromDate SMALLDATETIME = NULL,
	@ToDate SMALLDATETIME = NULL 
AS 
/*
	Created: 20221107@Evan 
	Task : Display exchange rate of crypto currency only 
	DB: DBACC.bodb2
	Revisions:
		- 20221107@Evan: Initial SP [RedmineID: #177844]
		- 20230807@Evan: Support rate for EUR [RedmineID: #192375]
		- 20240130@Lewis: Support rate for USD [RedmineID: #200376]
*/	
BEGIN  
	SET NOCOUNT ON 

	IF ISNULL (@Fromdate,'')=''
		SELECT @Fromdate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
	IF ISNULL(@Todate,'')=''
		SELECT @ToDate = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	SELECT 
		edo.ExchangeDate,
		edo.Code AS CurrencyCode,
		edo.MYR,
		edo.CNY,
		edo.EUR,
		edo.USD,
		ex.USDT
	FROM dbo.ExchangeDailyOanda edo WITH (NOLOCK)
		INNER JOIN ExchangeDaily_Crypto ex WITH(NOLOCK) ON ex.ExchangeId = edo.ExchangeId AND ex.ExchangeDate = edo.ExchangeDate
	WHERE 
		edo.ExchangeDate >= @fromdate AND edo.ExchangeDate <= @todate 
	ORDER BY edo.ExchangeDate, CurrencyCode

END
GO