ALTER PROCEDURE [dbo].[Acc_ExchangeRateCheckValid] 
	@FromExchangeID	int,
	@ToExchangeID	int,
	@ExchangeRate	float,
	@UserID			int = 0,
	@FromCust		int = 0,
	@ToCust			int = 0,
	@Amount			money = 0,
	@transDate		datetime,
	@refNo			bigint = 0
AS

SET NOCOUNT ON
DECLARE @rowcount tinyint 
DECLARE	@xMin smallmoney, @xMax smallmoney
DECLARE @MinExchangeRate money, @MaxExchangeRate money
DECLARE @FromActualRate float, @ToActualRate float, @ActualRate float

SELECT @FromActualRate = actualrate FROM exchange with (nolock) where exchangeid = @FromExchangeID
SELECT @ToActualRate = actualrate FROM exchange with (nolock) where exchangeid = @ToExchangeID
	   
/*--	@Actualrate = x/y  (A->B)  --*/
SET	@ActualRate = @FromActualRate/@ToActualRate  

SELECT	@xMin = MinActualRate,
		@xMax = MaxActualRate
FROM Acc_ExchangeRate with(nolock) 
WHERE FromExchangeID = @FromExchangeID and ToExchangeID = @ToExchangeID

SET	@rowcount = @@rowcount 
IF @rowcount = 0 
BEGIN 
	SELECT	@xMin = MinActualRate,
			@xMax = MaxActualRate
	FROM Acc_ExchangeRate with(nolock) 
	WHERE FromExchangeID = @ToExchangeID and ToExchangeID = @FromExchangeID	
	IF @@rowcount = 0 RETURN
END 

/*	x1 = x/y*(1-xmin)
	x2 = x/y*(1+xmax)
*/
SET @MinExchangeRate = @Actualrate *(1 - @xMin)
SET @MaxExchangeRate = @Actualrate *(1 + @xMax)

IF @ExchangeRate < @MinExchangeRate OR  @ExchangeRate > @MaxExchangeRate
BEGIN
	--Write Log
	INSERT INTO Acc_ExchangeRate_InvalidTransfer(TransDate,UserID,FromCust,ToCust,FromExchangeID,ToExchangeID,
												 Rate,MinExRate,MaxExRate,ExRate,Amount,refNo,isDeleted)
	VALUES (@transDate,@UserID, @FromCust, @ToCust, @FromExchangeID, @ToExchangeID,
			@Actualrate, @MinExchangeRate, @MaxExchangeRate,@ExchangeRate, @Amount, @refNo,0)
END	
 
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateCheckValid] TO [bodbAdminNet]