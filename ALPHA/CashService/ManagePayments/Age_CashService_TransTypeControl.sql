/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_TransTypeControl
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - Dropdownlist Transaction Type [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896] 

	Param:
		exec Age_CashService_TransTypeControl
*/  
BEGIN
	SET NOCOUNT ON;

	SELECT *
	FROM (
		VALUES
		(1, 'Manual Deposit',	1),
		(2, 'Auto Deposit',	1),
		(3, 'Manual Withdraw',	2),
		(4, 'Auto Withdraw',	2)
	) AS TransactionTypes(TransactionTypeID, TransTypeDesc, TransactionType)
END