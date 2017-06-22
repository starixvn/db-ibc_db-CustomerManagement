--212	2	Acc_CustomerUpdMember_CommissionHR	Update Horse racing Commission for member
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMember_CommissionHR',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.ConvertToXML(@SPName, REPLACE(Doing, 'v151discount_41', 'v151discount_41=')),
	ActionID = 212
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END