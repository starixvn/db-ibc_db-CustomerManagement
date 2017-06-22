/* Created:20100107@Kiwi
    Task: ViewLog
    DB: bodb_CustomerLog

	Description: dbo.ConvertToXML
	908	Age_LoginVerifyDownline	Account closed by failed login 5 times

*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_LoginVerifyDownline'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE (REPLACE(Doing, 'The A/C is closed due to 5 wrong password attempts, ',''),'The sub-account is closed due to 5 wrong password attempts, ',''),'The A/C is closed due to 6 wrong password attempts','IP='),'The sub-account is closed due to 6 wrong password attempts','IP='),'The A/C is closed due to 5 wrong password attempts','IP=')),
		ActionId = 908
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)

	IF  @@ROWCOUNT < 1000
			BREAK
END