ALTER PROCEDURE [dbo].[Acc_ExchangeRateSel]
AS
/*
	Created by: Jamie
	Task: Show Min Max Rate 
	DB: DB03.BODB02 
	
	Revisions:
		- 20100105@Jamie: Get currencyName from cache 
*/
SET NOCOUNT ON
select	e.FromExchangeID, 
		e.ToExchangeID, 
		-e.MinActualrate * 100 AS MinActualrate, 
		e.MaxActualrate * 100 AS MaxActualrate, 
		c.username as creator, 
		e.LastUpdate
from	Acc_ExchangeRate e with(nolock) 
		inner join customer c with(nolock) on e.creator = c.custid
ORDER BY e.FromExchangeID, e.ToExchangeID

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateSel] TO [VNTeam]
GO