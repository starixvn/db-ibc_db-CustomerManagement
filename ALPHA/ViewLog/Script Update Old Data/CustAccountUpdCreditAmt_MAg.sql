/* Created:20100109@Kiwi
    Task: ViewLog
    DB: bodb_CustomerLog

	Description: dbo.ConvertToXML
	1213	CustAccountUpdCreditAmt_MAg	Update Master's Credit


*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'CustAccountUpdCreditAmt_MAg',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
		ActionId = 1213
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END