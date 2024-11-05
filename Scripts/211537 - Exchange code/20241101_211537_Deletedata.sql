/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
	Created: 20241101@Eddie
	DB: DBCUST-CustDB
	Task: delete row HKD [RedmineID: #211537]
*/

USE CustDB
GO

DELETE ExchangeDailyOanda WITH (ROWLOCK, UPDLOCK)
WHERE exchangeid = 67 AND Code = 'HKD' AND ExchangeDate = '2024-11-01'
GO
