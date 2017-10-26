/*
	Created: 20171024@Helen
	Task: TO Phase 3 - Support UAT - https://nexdev.net/issues/85459 [Redmine:85459]
	DB: DBCUST/CUSTDB
	
*/
USE CustDB

GO

DELETE TS
FROM dbo.TOControl_GlobalSetting TS
WHERE IsGroupHeadLine = 1 OR Sporttype = 99

DELETE TS
FROM dbo.TOControl_Setting TS
WHERE IsGroupHeadLine = 1

GO	