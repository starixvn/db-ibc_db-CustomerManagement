/*
	DOING VALUE: Update Virtual Rate for CustID=68289, NewValue=0.50, OldValue=1.55, UserID=8, ErrCode=0, ErrMsg=, IP=202.78.228.8  
	
	ACTION: 801 Acc_CustomerUpdVirtualMultiplier Update Virtual Rate 
	
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdVirtualMultiplier', REPLACE(DOING, 'Update Virtual Rate for ', ''))
, dbo.UserLog_RunSP.ActionID = 801
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdVirtualMultiplier'
*/
--20100109@kIWI
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdVirtualMultiplier',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(DOING, 'Update Virtual Rate for ', ''),'Acc_CustomerUpdVirtualMultiplier','')),
	ActionID = 801
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END