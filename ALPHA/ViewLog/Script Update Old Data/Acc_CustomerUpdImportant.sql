/*
DOING VALUE: Update customer Special status for CustID=1575083, Important=0, UserID=25520, Language=E, ErrCode=0, ErrMsg=, IP=202.78.228.8

ACTION: 1106	Acc_CustomerUpdImportant	Update Special status
*/

/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(REPLACE(Doing, 'Update customer Special status for ', ''),
dbo.UserLog_RunSP.ActionID = 1106
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdImportant' 
*/
--20100108@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdImportant',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer Special status for ', '')),
		ActionId = 1106
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END