--407	Acc_CustomerUpdMember_Master	Update Master's Sportsbook Position Taking at member

declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMember_Master',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, '', ','),' O',''), ',,',',')),
	ActionID = 407
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END