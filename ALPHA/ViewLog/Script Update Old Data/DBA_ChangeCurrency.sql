
/* Created:20100107@Kiwi
    Task: ViewLog function
    DB: bodb_CustomerLog

	Description: dbo.GenerateXML
	
	804	DBA_ChangeCurrency 	IT Admin changed customer currency

*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_ChangeCurrency',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(Doing, 'Update currency for Super ','CustID=,CustName='),' from old currency: ',',Old='),' to new currency: ',',New=')),
	ActionID = 804
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
