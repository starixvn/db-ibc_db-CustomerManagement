
/*  Update data of records, spName is Acc_CustomerUpdClosed
	
	DOING VALUE: Update customer status for CustID=1906440, Closed=0, SubAccName=, UserID=8, Language=E, ErrCode=0 O, ErrMsg= O, IP=127.0.0.1 
	
	ACTION: 1105	Acc_CustomerUpdClosed	Update Closed status
*/

/*
UPDATE dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET TrackingValue = GenerateXML('Acc_CustomerUpdClosed', REPLACE(Doing, 'Update customer status for ', ''))
, ActionId = 1105
WHERE SpName = 'Acc_CustomerUpdClosed'
*/

-- 20100106@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdClosed',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer status for ', '')),
		ActionId = 1105
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END

  