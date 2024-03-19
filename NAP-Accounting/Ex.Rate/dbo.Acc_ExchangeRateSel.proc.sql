/*<info serverAlias="DBCTG-bodb02" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeRateSel]
AS
/*
	Created by: Jamie
	Task: Show Min Max Rate 
	DB: DBTXN/bodb02
	
	Revisions:
		- 20100105@Jamie: Get currencyName from cache 
		- 20180808@Helen: Get Code from Production + DB05.DBPOLICY migration - - move to DBTRANS for exchangeRate [Redmine:99462]
		- 20230508@Danny: Get From Currency actualrate, To Currency actualrate [Redmine:187842]
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		e.FromExchangeID, e.ToExchangeID, -e.MinActualrate * 100 AS MinActualrate, e.MaxActualrate * 100 AS MaxActualrate, c.username as creator, e.LastUpdate,
		f.Currency as FromExchange, t.Currency as ToExchange, f.actualrate AS FromActualRate, t.actualrate AS ToActualRate
	FROM Acc_ExchangeRate e WITH(NOLOCK) 
		INNER JOIN CUSTDB.dbo.Exchange f WITH(NOLOCK) ON e.FromExchangeID = f.ExchangeID
		INNER JOIN CUSTDB.dbo.Exchange t WITH(NOLOCK) ON e.ToExchangeID = t.ExchangeID
		INNER JOIN CUSTDB.dbo.customer c WITH(NOLOCK) ON e.creator = c.custid
	ORDER BY f.Currency, t.Currency

END