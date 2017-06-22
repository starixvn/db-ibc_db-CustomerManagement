/*
	DOING VALUE: Update customer Suspended for CustID=1373389, Suspended=0, SubAccName=, UserID=8, Language=E, ErrCode=0 O, ErrMsg= O, IP=127.0.0.1 
	
	ACTION: 700 Acc_CustomerUpdTransferOption Update Transfer Condition 
	
		
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdTransferOption', REPLACE(DOING, 'Update customer Suspended for ', ''))
, dbo.UserLog_RunSP.ActionID = 700
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdTransferOption'
*/
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdTransferOption',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(DOING, 'Update Transfer Option for ', '')),
	ActionID = 700
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
