/*<info serverAlias="DBTXN-bodb02,DBSIG-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ChangeRate_Prepare_Upd] 
	@IsSiteDB BIT = 0,
	@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(2000) = '' OUTPUT
AS
/*
	Created: 20211229@Malcolm
	DB: DBTXN-bodb02
	Task: Update rates for all existed tickets once financial change rates

	Revisions:
		- 20211229@Malcolm: Initialize SP [RedmineID: #163417]
		- 20220801@Sophia: Scale out, call at SiteDB [RedmineID: #175253]

	Param's Explanation:
	
 */
BEGIN
	SET NOCOUNT ON 
	DECLARE @__winlostdate SMALLDATETIME
	SELECT @__winlostdate = CONVERT(VARCHAR, GETDATE(), 23) 
	
	--- Wait for CustDB.dbo.exchange replicated from DBCUST.CustDB to SiteDB.CustDB	
	WAITFOR DELAY '00:00:10'    
	
	--- outright movement
	BEGIN TRY
		EXEC dbo.Task_OutrightMovement 
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. update unsucessfully exchange rate for outright tickets.'
		RETURN
	END CATCH

	---- parlay movement
	BEGIN TRY
		EXEC dbo.Task_ParlayMovement @Winlostdate = @__winlostdate
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. update unsucessfully exchange rate for parlay tickets.'
		RETURN
	END CATCH
	
	-- update exchange rate oanda
	BEGIN TRY
		EXEC DBCUST.CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate = @__winlostdate
	END TRY
	BEGIN CATCH 
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. update unsucessfully OANDA exchange rate.'
		RETURN
	END CATCH
	 
END