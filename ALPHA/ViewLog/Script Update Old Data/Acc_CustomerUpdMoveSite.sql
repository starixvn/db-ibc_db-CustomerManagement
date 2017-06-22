

/* Created:20100102@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- Update doing value records which sp name is Acc_CustomerUdpMoveSite 

	DOING VALUE: Move site for customer from old site 222227 to new site 222225 
	
	ACTION: 1106	Acc_CustomerUpdImportant	Update Special status */
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveSite',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
		
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Doing),
		ActionId = 614
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END