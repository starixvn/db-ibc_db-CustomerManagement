/*
	Created: 20171024@Helen
	Task: TO Phase 3 - Support UAT - https://nexdev.net/issues/85459 [Redmine:85459]
	DB: DBCUST/CUSTDB
	
*/
USE CustDB

GO

DELETE TS
FROM dbo.TOControl_Setting TS
WHERE CustID = 19235084  
	AND matchid IN (23236845, 23311169) 
	AND IsGroupHeadLine = 0
GO	