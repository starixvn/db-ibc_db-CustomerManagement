/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeRateSelHistory]
	@FromExchangeID int = null,
	@ToExchangeID int = null,
	@UserID int = null
AS
/*
	Created by: Peter
	Task: Show Min Max Rate History 
	DB: DBTXN/BODB02
	
	Revisions:
		- 20100105@Jamie: Get CurrencyName from cache 
		- 20180808@Helen: DB05.DBPOLICY migration - - move to DBTRANS for exchangeRate [Redmine:99462]
*/
BEGIN
	SET NOCOUNT ON
	SELECT	a.Actiondate, 
			a.Actiontype, 
			c.Username as Username, 
			a.fromExchangeID,
			a.toExchangeID,
			-a.MinActualrate*100 AS MinActualrate, 
			a.MaxActualrate*100 AS MaxActualrate
	FROM 
		(
			SELECT Actiondate, Actiontype, UserID, FromexchangeID, ToexchangeID, 
				MinActualrate, MaxActualrate
			FROM	dbo.Acc_ExchangeRate_History WITH(NOLOCK)
			WHERE	FromExchangeID = COALESCE(@FromExchangeID,FromExchangeID) 
					and ToExchangeID = COALESCE(@ToExchangeID, ToExchangeID)
					and UserID = COALESCE(@UserID,UserID) 
		) a INNER JOIN CUSTDB.dbo.Customer c WITH(NOLOCK) ON c.CustID = a.UserID
	ORDER BY a.Actiondate DESC
END	
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateSelHistory] TO [bodbAdminNet]	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateSelHistory] TO [VNTeam]
GO