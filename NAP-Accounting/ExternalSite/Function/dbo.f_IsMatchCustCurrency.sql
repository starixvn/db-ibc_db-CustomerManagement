ALTER FUNCTION [dbo].[f_IsMatchCustCurrency]
(
@CustID int,
@ExchangeID int
)
RETURNS BIT
/* Created:20100521@Henry
    Task: Check matched currency by inputing CustID and ExchangeID
    DB: DB05.BODB02

*/
AS
BEGIN
	DECLARE @ReturnVal as BIT
	DECLARE @currency as INT
	SELECT @currency = currency FROM CustInfo (nolock)
	WHERE custid = @CustID

	IF @ExchangeID = @currency
		SET @ReturnVal = 1
	ELSE
		SET @ReturnVal = 0

	RETURN @ReturnVal
END
GO
GRANT EXECUTE ON [dbo].[f_IsMatchCustCurrency] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[f_IsMatchCustCurrency] TO [vnteam]