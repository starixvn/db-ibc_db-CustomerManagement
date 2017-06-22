/*
	DOING VALUE: Update username from MNB0101 to MNB0102, userid=25520, IP=, ErrCode=0 O, ErrMsg= O 
	
	ACTION: 605 Acc_CustomerUpdUserName Change username 	
	
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(Doing, 'Update username from ', 'FromName='),
ACTIONID=605
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserName'

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, 'to ', ', ToName=')
WHERE ACTIONID=605

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdUserName', TrackingValue)
WHERE ACTIONID=605
*/
--20100109@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserName',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, 'Update username from ', 'FromName='),'Update usename of ','FromName='),'to ', ', ToName=')),
	ActionID = 605
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END