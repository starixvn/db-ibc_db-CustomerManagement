/*<info serverAlias="DBCUST-CUSTDB" executers="" isFunction="0"></info>*/
/*
	Created: 20210410@Helen
	Task: https://nexdev.net/issues/153241
	DB:DBCUST/CUSTDB
*/
USE CUSTDB
GO
UPDATE w 
	SET IsNotified = 0
FROM WinLimit_CustGameMonitoring_History w WITH (ROWLOCK)
WHERE CustID IN (49744553,49743156)
	AND LogID IN (63252,63254) AND IsNotified = 1 

