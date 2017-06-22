/*
	DOING VALUE: 
	subaccid=80375, custid=79560, username=MBRM99Sub01, fname=, lname=, PageAccess=[A][B][C][D][E], success=1 O, Language=E, LoginSubAccID=0, LoginIP=202.78.228.8, UserID=79560, ErrCode=0 O, ErrMsg= O 

	ACTION: 612	Age_CustSubIns	Open new sub-account

*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue =  dbo.GenerateXML('Age_CustSubIns', DOING)
, dbo.UserLog_RunSP.ActionID = 612
WHERE dbo.UserLog_RunSP.SPName = 'Age_CustSubIns'
*/
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Age_CustSubIns',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
	ActionID = 612
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END
