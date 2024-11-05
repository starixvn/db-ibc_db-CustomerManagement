/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
	Created: 20241001@Eddie
	DB: DBCUST-CustDB
	Task: Update exchange code of HKK [RedmineID: #211537]
*/

USE CustDB
GO

UPDATE exchange WITH (ROWLOCK, UPDLOCK)
SET Code = 'MYR', RepUpdateTime = SYSDATETIME()  -- old: HKD
WHERE exchangeid = 67
GO
