USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_ExchangeSelAccount]
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
	Param's Explanation:
*/
SET NOCOUNT ON
select 
	exchangeid, currency, stakerate, actualrate, commaxpayout, creator, minbet, minbetlive, 
	GBPRate, EURORate,  US$Rate, Description, MultipliedBy,
	case when exchangeid = 51 then currency else Code end as CurrencyCode --20120711@Elodie: hardcode to not show CurrencyCode of INH
from 
	exchange with (NOLOCK)
ORDER BY 
	CASE WHEN currency in ('M','C','H','TBS','S') Then 0 WHEN currency = 'UUS' THEN 2 ELSE 1 END,currency

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeSelAccount] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeSelAccount] TO [vnteam]