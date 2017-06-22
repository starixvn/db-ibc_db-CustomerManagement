ALTER PROCEDURE [dbo].[Acc_ExchangeRateUpdisDeleted]
	@refNo  bigint = null
AS
	SET NOCOUNT ON 
	IF exists (SELECT 1 FROM dbo.Acc_ExchangeRate_InvalidTransfer WHERE refno = @refNo )
	BEGIN 
		UPDATE dbo.Acc_ExchangeRate_InvalidTransfer SET isDeleted = 1 WHERE refno = @refNo
	END 

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateUpdisDeleted] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateUpdisDeleted] TO [vnteam]