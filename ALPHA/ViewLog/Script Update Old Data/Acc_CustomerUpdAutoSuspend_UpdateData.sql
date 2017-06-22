

/* Created:20100102@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	DESCRIPTION:
	- Update doing value record which sp name is Acc_CustomerUpdAutoSuspend   
	
	DOING VALUE:  update customer autosuspend for CustID=2, AutoSuspend=0, UserID=8, ErrCode=0, ErrMsg=, IP=127.0.0.1 
	
	ACTION: 1110	Acc_CustomerUpdAutoSuspend	Update Auto Suspended status	
*/


/*
UPDATE UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET UserLog_RunSP.TrackingValue = dbo.ConvertToXML(Replace(Doing, 'update customer autosuspend for ', ''))
, ActionId = 1110
WHERE SPName='Acc_CustomerUpdAutoSuspend'
*/

-- 20100106@Kiwi
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdAutoSuspend',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'update customer autosuspend for ', '')),
		ActionId = 1110
	WHERE	SPName=@SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END
