ALTER PROCEDURE [dbo].[Acc_ExchangeRateSelHistory]
	@FromExchangeID int = null,
	@ToExchangeID int = null,
	@UserID int = null
AS
/*
	Created by: Peter
	Task: Show Min Max Rate History 
	DB: DBPOLICY/BODB02
	
	Revisions:
		- 20100105@Jamie: Get CurrencyName from cache 
*/
SET NOCOUNT ON
	select	a.Actiondate, 
			a.Actiontype, 
			c.Username as Username, 
			a.fromExchangeID,
			a.toExchangeID,
			-a.MinActualrate*100 AS MinActualrate, 
			a.MaxActualrate*100 AS MaxActualrate
	from 
		(
			select Actiondate, Actiontype, UserID, FromexchangeID, ToexchangeID, 
				MinActualrate, MaxActualrate
			from	Acc_ExchangeRate_History with(nolock)
			where	FromExchangeID = coalesce(@FromExchangeID,FromExchangeID) 
					and ToExchangeID = coalesce(@ToExchangeID, ToExchangeID)
					and UserID = coalesce(@UserID,UserID) 
		) a inner join Customer c with(nolock) on c.CustID = a.UserID
	order by a.Actiondate DESC
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateSelHistory] TO [bodbAdminNet]	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateSelHistory] TO [VNTeam]
GO