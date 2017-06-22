ALTER PROCEDURE [dbo].[Acc_ExchangeCurrencySel]
AS
/*
Created: HuyNguyen
Task : Get Currency Name by exchangeID
DB: DB05.BODB02 , DB06.BODB02
Original:Accounting site
Revisions:
*/		

-- test 2
	SET NOCOUNT ON

	SELECT exchangeid, currency from exchange with (nolock) where exchangeid <> 20


GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCurrencySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCurrencySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeCurrencySel] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeCurrencySel] TO [vnteam] AS [dbo]