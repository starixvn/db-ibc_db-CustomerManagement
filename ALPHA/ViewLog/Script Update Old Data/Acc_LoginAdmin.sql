/* Created:20100107@Kiwi
    Task: ViewLog
    DB: bodb_CustomerLog

	Description: dbo.ConvertToXML
	905	Acc_LoginAdmin	Account closed by failed login 5 times, The A/C is closed due to 6 wrong password attempts

*/
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_LoginAdmin',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE (REPLACE(Doing, 'The A/C is closed due to 5 wrong password attempts, ',''),'The A/C is closed due to 6 wrong password attempts','IP=')),
		ActionId = 905
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END