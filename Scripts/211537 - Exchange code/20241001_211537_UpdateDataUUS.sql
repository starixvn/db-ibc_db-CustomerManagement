/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
	Created: 20241001@Eddie
	DB: DBCUST-CustDB
	Task: Update exchange code of UUS [RedmineID: #211537]
*/

USE CustDB
GO

UPDATE exchange WITH (ROWLOCK, UPDLOCK)
SET Code = 'UUS', RepUpdateTime = SYSDATETIME()
WHERE exchangeid = 20
GO


