/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0"></info>*/
/*
	Created: 20210212@Helen
	Task: https://nexdev.net/issues/150242
	DB:DBCUST/CUSTDB
*/
USE CUSTDB
GO
UPDATE w 
	SET IsNotified = 0
FROM WinLimit_CustGameMonitoring_History w WITH (ROWLOCK)
WHERE LogID in (60908, 60907) AND IsNotified = 1


