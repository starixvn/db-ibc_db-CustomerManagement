/* Created:20091224@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	Deploy assembly CLR IBCViewLogCLR
	
	DOING VALUE: Username=KLO0501001, Userid=25520, ReturnErrCode=1, ErrCode=0, ErrMsg=, IP=202.78.228.8 
		
	ACTION:
		1201	Acc_CustomerUpdClearCredit	Clear Credit
*/
/*
UPDATE UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(UserLog_RunSP.Doing)
, ActionID = 1201
WHERE SPName='Acc_CustomerUpdClearCredit';
*/

--20100108@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdClearCredit',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName,Doing),
		ActionId = 1201
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END