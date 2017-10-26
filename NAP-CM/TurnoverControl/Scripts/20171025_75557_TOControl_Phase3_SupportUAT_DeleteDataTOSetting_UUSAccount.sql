/*
	Created: 20171024@Helen
	Task: TO Phase 3 - Support UAT - https://nexdev.net/issues/85459 [Redmine:85459]
	DB: DBCUST/CUSTDB
	
*/
USE CustDB

GO

DELETE TS
FROM dbo.TOControl_Setting TS
WHERE Custid IN (23003140,19235084)

GO	