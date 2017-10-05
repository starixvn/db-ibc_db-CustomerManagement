ALTER PROCEDURE [dbo].[Acc_ExchangeSel_byCurrencyName]
@CurrencyName	NVARCHAR(50)
AS
/*
Created: 20160823@Jamie
Task : Get currency information by Currency Name [RedmineID:#62306 ]
DB: DBCUST.CustDB
Original:

Revisions:

Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON 
	SELECT	ExchangeID, Currency, actualrate
	FROM	Exchange WITH (NOLOCK)
	WHERE	Currency =@CurrencyName
END

GO
GRANT  EXECUTE  ON [dbo].[Acc_ExchangeSel_byCurrencyName]  TO [bodbAdminNet]
GO

