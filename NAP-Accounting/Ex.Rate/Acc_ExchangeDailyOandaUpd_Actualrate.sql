/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Acc_ExchangeDailyOandaUpd_Actualrate]
	@ExchangeDate SMALLDATETIME
AS
/*
	Created: 20220914@Sophia
	DB: DBCUST-CUSTDB
	Task: Update actualrate of today and tommorow on ExchangeDailyOanda 

	Revisions:
		- 20220914@Sophia: Initialize SP [RedmineID: #175253] 

	Param's Explanation:
	SP Original: DBA_ExchangeDailyOandaUpd_Actualrate
	 
 */
BEGIN
	SET NOCOUNT ON 
	
	---- Update Actualrate of Today 
	UPDATE e
	SET e.actualrate = ex.actualrate
	FROM ExchangeDailyOanda e WITH (ROWLOCK, UPDLOCK)
		INNER JOIN exchange ex(NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate = @ExchangeDate
	WHERE e.actualrate <> ex.actualrate

	---- Update Actualrate of Tomorrow 
	UPDATE e
	SET e.actualrate = ex.actualrate
	FROM ExchangeDailyOanda e WITH (ROWLOCK, UPDLOCK)
		INNER JOIN exchange ex(NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate = DATEADD(dd, 1, @ExchangeDate)
	WHERE e.actualrate <> ex.actualrate

END