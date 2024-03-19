/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,wsv_nap" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeSelAccount]
@CurrencyType VARCHAR (3) = ''
AS

/*	Created by: [Khoa]
	Date: 20100127
	Task: Get all currencies
	DB: DBAGE.bodb02		
	Revisions:	
		- 20100127: @Khoa Add columns GPBRate, AUDRate, ZARRate, EURORate, USDRate
		- 20110605@Johnson: get Description, MultipliedBy, Code
		- 20120711@Elodie: hardcode to not show CurrencyCode of INH
						   change DB053 server instead of DB052 server.
		- 20161219@Percy: Remove AUDRate and ZARRate columns [RedmineID: #68649]
		- 20200802@Elodie: Get IsActive, OfferSite column [RedmineID: #136023]
		- 20221107@Evan: Support Crypto Currency [RedmineID: #177844]
*/
SET NOCOUNT ON
SELECT 
	exchangeid, currency, stakerate, actualrate, commaxpayout, creator, minbet, minbetlive, 
	GBPRate, EURORate,  US$Rate, Description, MultipliedBy,
	CASE WHEN exchangeid = 51 THEN currency ELSE Code END AS CurrencyCode, --20120711@Elodie: hardcode to not show CurrencyCode of INH
	OfferSite, CurrencyType, stakerate AS CoinMarketCapID, IsActive
FROM 
	exchange WITH (NOLOCK)
WHERE  
	@CurrencyType = '' OR CurrencyType = CONVERT(TINYINT, @CurrencyType)
ORDER BY 
	CASE WHEN currency in ('M','C','H','TBS','S') Then 0 WHEN currency = 'UUS' THEN 2 ELSE 1 END,currency
GO