/*
SPName: Dot_Dep_CustomerInsMember_Ag
ActionID = 617
*/

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Dot_Dep_CustomerInsMember_Ag',
		@fromdate = '2009-05-01 00:00:00.000',
		@todate = '2009-10-31 23:59:59.000'

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  dbo.GenerateXML(@SPName, REPLACE(Doing,'Dot_Dep_CustomerInsMember_Ag','')),
	ActionID = 617
	WHERE	SPName = @SPName
			AND ActionID is null
			AND logdate between @fromdate and @todate
			AND doing is not null
	IF  @@ROWCOUNT < 1000
			BREAK
END
