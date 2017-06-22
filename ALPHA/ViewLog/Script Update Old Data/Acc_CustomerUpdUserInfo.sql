/*
	DOING VALUE: Update customer info for CustID=1373389, 
		fname=Test, lname=Casino, address= , postal= , city= , 
		state= , country= , phone=AA, mphone=, fax=123, 
		email=, birthda
	
	ACTION: 604 Acc_CustomerUpdUserInfo Update customer info 

*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdUserInfo', REPLACE(Doing, 'Update customer info for ', '')),
actionid=604
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserInfo'
*/
/*
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserInfo',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(dbo.f_EncodeXMLValue(Doing), 'Update customer info for ', ''), ', ', 'xxxxx'),',', '.'),'xxxxx', ', ')),
	ActionID = 604
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK	   
END
*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserInfo',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName


UPDATE dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET TrackingValue = replace (doing, 'Update customer info for ', '')
WHERE	SPName = @SPName
		AND logdate between @fromdate and @todate
	

DECLARE @temp Table
(
	LogId int,
	TrackingValue nvarchar(max)
)

INSERT @temp(logid, trackingvalue)
SELECT logid, dbo.GenerateXML(SpName, dbo.f_EncodeXMLValue( dbo.RegExReplace
	(dbo.RegExReplace(trackingvalue, '(\d{1,3})(,)(\d{1,3})', '$1.$3'), '(\d{1,3})(,)(\d{1,3})', '$1.$3')))		
FROM dbo.UserLog_RunSP with (nolock)
WHERE spname = @SPName and doing is not null
		
WHILE (1=1)
BEGIN	
	
	UPDATE TOP (1000) dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
	SET TrackingValue = (SELECT TOP 1 trackingvalue FROM @temp A WHERE A.logid = dbo.UserLog_RunSP.logid),
	ActionId = 604
	WHERE	SPName = @SPName
			AND ActionID is null
			--AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
			
	IF  @@ROWCOUNT < 1000
			BREAK
END
