
/*Update data of records, spName is Acc_CustomerUpdDangercust
- DOING VALUE: "Update dangerous status for CustID=73104,OldValue=1,Danger=8,UserID=8, Language=E, ErrCode=0, ErrMsg=, IP=202.78.228.8" 
- Action: 1114	Acc_CustomerUpdDangercust	Update Dangerous status for member*/
/*
UPDATE dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET TrackingValue = GenerateXML('Acc_CustomerUpdDangercust', REPLACE(Doing, 'Update dangerous status for ', ''))
, ActionId = 1114
WHERE SpName = 'Acc_CustomerUpdDangercust'
*/
  
-- 20100106@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdDangercust',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update dangerous status for ', '')),
		ActionId = 1114
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
			
    IF  @@ROWCOUNT < 1000
        BREAK
END