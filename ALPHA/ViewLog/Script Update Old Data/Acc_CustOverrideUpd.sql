/* Created:20100115@Kiwi
    Task: ViewLog
    DB: bodb_CustomerLog

	Description: dbo.ConvertToXML
	500	Acc_CustOverrideUpd	Update Sportsbook Min/Max Position Taking


*/
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustOverrideUpd',
		@fromdate = '2009-01-01',
		@todate = '2010-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN	
	
	UPDATE dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.TrimEnd(dbo.Trim(REPLACE(Doing, '',', ')), ','), ActionId = 500
	WHERE	SPName = @SPName AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
	
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE (REPLACE(REPLACE(TrackingValue, 'Acc_CustOverrideUpd',''),'<info>',''),'</info>','')),
		ActionId = 500
	WHERE	SPName = @SPName
			--AND ActionID is null
			AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END