/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_ExchangeSelByID]
	@ExchangeID [int]
AS
/*
Created: 
Task : Select currency by Id
DB: DBCUST/CustDB
Original:

Revisions:
	- 20100128@Khoa: select columns GPBRate, AUDRate, ZARRate, EURORATE, USDRATE
	- 20110605@Johnson: get description, multipliedBy, code
	- 20161219@Percy: Remove AUDRate and ZARRate columns [RedmineID: #68649]
	- 20200802@Elodie: Get IsActive, OfferSite column [RedmineID: #136023]
	- 20221107@Evan: Support Crypto Currency [RedmineID: #177844]

Param's Explanation:
	• @ExchangeID: specIFy exchange-rate of the currency

*/

SET NOCOUNT ON
BEGIN
	SELECT exchangeid, currency, actualrate, creator, minbet, minbetlive, GBPRate, EURORate, US$Rate , Description, MultipliedBy, Code, OfferSite, CurrencyType, stakerate AS CoinMarketCapID, IsActive
	FROM exchange WITH(NOLOCK)
	WHERE exchangeid = @ExchangeID
END
GO