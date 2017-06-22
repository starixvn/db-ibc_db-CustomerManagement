
/*
Doing Value:
		Select @LogData = 'reset password userID:' + convert(varchar(20), @CustID) + ' IP:' +@LoginIP
		---------------------------
		-- ***Check Sub-Account***
		if @SubAccID > 0
		begin
			SET @LogData = 'SubAccount:' +  dbo.f_GetSubUsername(@SubAccID) + ' - ' + @LogData
		END
Action 
	901	Age_CustomerUpdPwd	Reset Password
*/

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustomerUpdPwd',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'SubAccount:', 'SubAccount='),' - ',''), 'reset password userID:',', UserID='),' IP ', ', IP='),' IP:',', IP=')),
		ActionId = 901
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END