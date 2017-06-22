/*
	DOING VALUE: AgentID=1575060, ClosedOnly=0, UserID=25520
	ACTION: 1202 Acc_CustomerUpdResetMemberCredit Clear Member's Credit 
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdResetMemberCredit', Doing)
, ActionID = 1202
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdResetMemberCredit'
*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdResetMemberCredit',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
	ActionID = 1202
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END