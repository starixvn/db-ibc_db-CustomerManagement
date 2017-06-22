
/* Created:20100107@Kiwi
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description: dbo.GenerateXML
	
	1500	DBA_ArchiveAccount1_UpdateMove	Archive Account by IT Admin
	1501	DBA_ArchiveAccount2_UpdateMove	Archive Account by IT Admin	
	1503	DBA_ArchiveAccount1_Rollback 	Roll back archive account by IT Admin
	1504	DBA_ArchiveAccount2_Rollback 	Roll back archive account by IT Admin
	1502	DBA_ArchiveAccount2_ClearBalance	Clear Member Balance to archive account by IT Admin
	1115	DBA_ArchiveAccount0_CloseAgent	Close Agent to archive account by IT Admin
*/
declare @fromdate smalldatetime, @todate smalldatetime
select	@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname ='DBA_ArchiveAccount1_UpdateMove'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount1_UpdateMove', REPLACE(doing,'DBA_ArchiveAccount1_UpdateMove' ,'') ),
		ActionId = 1500
	WHERE	SPName='DBA_ArchiveAccount1_UpdateMove'
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

delete @User
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname ='DBA_ArchiveAccount2_UpdateMove'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount2_UpdateMove', REPLACE(doing,'DBA_ArchiveAccount2_UpdateMove' ,'')),
		ActionId = 1501
	WHERE	SPName='DBA_ArchiveAccount2_UpdateMove'
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END


delete @User
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname ='DBA_ArchiveAccount1_Rollback'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount1_Rollback', doing),
		ActionId = 1503
	WHERE	SPName='DBA_ArchiveAccount1_Rollback'
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

delete @User
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname ='DBA_ArchiveAccount2_Rollback'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount2_Rollback', doing),
		ActionId = 1504
	WHERE	SPName='DBA_ArchiveAccount2_Rollback'
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END


delete @User
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname ='DBA_ArchiveAccount2_ClearBalance'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount2_ClearBalance', REPLACE(doing,'DBA_ArchiveAccount2_ClearBalance' ,'')),
		ActionId = 1502
	WHERE	SPName='DBA_ArchiveAccount2_ClearBalance'
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

delete @User
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname ='DBA_ArchiveAccount0_CloseAgent'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML('DBA_ArchiveAccount0_CloseAgent', REPLACE(doing,'DBA_ArchiveAccount0_CloseAgent' ,'')),
		ActionId = 1115
	WHERE	SPName='DBA_ArchiveAccount0_CloseAgent'
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END