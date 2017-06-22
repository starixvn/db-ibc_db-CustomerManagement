/*
DOING VALUE: Update customer Internal/Betting status for custid:=1374738, IsInternal=0, userid=8, ErrCode=0 O, ErrMsg= O, IP=127.0.0.1 

ACTION: 1112	Acc_CustomerUpdInternal	Update Account type
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(REPLACE(Doing, 'Update customer Internal/Betting status for custid:', 'custid'),
dbo.UserLog_RunSP.ActionID = 1112
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdInternal' 
*/
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdInternal',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer Internal/Betting status for custid:', 'custid')),
		ActionId = 1112
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END