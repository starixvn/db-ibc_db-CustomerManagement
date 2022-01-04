CREATE PROCEDURE [dbo].[Acc_ChangeRate_Prepare_Upd] 
AS
/*
 	DB: DBTXN/bodb02
 	Task : Update rates for all existed tickets once financial change rates
 	
 	Revisions:			
	
 */
BEGIN
	SET NOCOUNT ON 
	DECLARE @__winlostdate SMALLDATETIME
	SELECT @__winlostdate = CONVERT(VARCHAR, GETDATE(), 23) 
		  
	--- outright movement
	EXEC dbo.Task_OutrightMovement

	---- parlay movement
	EXEC dbo.Task_ParlayMovement @Winlostdate = @__winlostdate
	
	-- update exchange rate oanda
	EXEC DBcust.CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate = @__winlostdate

END