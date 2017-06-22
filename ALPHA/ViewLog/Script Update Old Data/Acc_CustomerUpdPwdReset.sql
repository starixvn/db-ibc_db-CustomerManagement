/*
	DOING VALUE: Reset password CustID:1906328 IP:127.0.0.1 
	ACTION: 900 Acc_CustomerUpdPwdReset Reset downline's password 
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(Doing, 'Reset password ', '')	
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdPwdReset'

GO

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, 'CustID: ', 'CustID=')	
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdPwdReset'

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, 'IP:', ', IP=')	
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdPwdReset'

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdPwdReset', TrackingValue)
, dbo.UserLog_RunSP.ActionID = 900	
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdPwdReset'
*/
--20100109@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdPwdReset',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(DOING, 'Reset password CustID:', 'CustID='),'IP:', ', IP=')),
	ActionID = 900
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
