declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdDisableOpenTote',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
 
WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
		ActionId = 1119
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END