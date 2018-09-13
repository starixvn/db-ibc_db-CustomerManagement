/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeRateUpdisDeleted]
	@refNo  bigint = null
AS
/*
	Created: N/A
	Task : 
	DB: DBTXN/bodb02

	Revisions:
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20110624@Tom: Change DB02 to DBTRANS (SplittingEXECUTE DB02 to DBPros and DBTRANS)
		- 20111017@Johnson: Check permission for update ABS system
		- 20120531@Sophia: Change the way to write log & add new parameter @OldMemPolicys
		- 20130118@Elodie: Get Username from currrent server instead of DBTrans 
						   Write more log on UserLog table in case of DBLOG server failure
		- 20180808@Helen: DB05.DBPOLICY migration -  move to DBTRANS for exchangeRate [Redmine:99462]				   
*/
BEGIN
	SET NOCOUNT ON 
	IF EXISTS (SELECT 1 FROM dbo.Acc_ExchangeRate_InvalidTransfer WHERE refno = @refNo )
	BEGIN 
		UPDATE dbo.Acc_ExchangeRate_InvalidTransfer SET isDeleted = 1 WHERE refno = @refNo
	END 
END
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateUpdisDeleted] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateUpdisDeleted] TO [vnteam]