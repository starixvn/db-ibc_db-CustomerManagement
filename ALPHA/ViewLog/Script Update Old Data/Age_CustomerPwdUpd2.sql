/*
	DOING VALUE: reset password userID:1906367 IP: 202.78.228.8  
	
	ACTION: 902	Age_CustomerPwdUpd2	Reset own password 
	
	XML FORMAT: <Age_CustomerPwdUpd2 UserID="1906367" IP="202.78.228.8" />

*/

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustomerPwdUpd2',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(DOING, 'reset password userID:', 'UserID='),'IP:', ', IP=')),
		ActionId = 902
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
