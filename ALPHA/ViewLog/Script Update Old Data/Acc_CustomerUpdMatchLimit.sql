/*
	- DOING VALUE: Update creditpermatch CustID= 1906396,matchlimit = 0.99 by user 8
	
	- ACTION: 800 Acc_CustomerUpdMatchLimit Update Max Exposure (%) 
*/
/*
UPDATE dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdMatchLimit', REPLACE(REPLACE(Doing, 'Update creditpermatch ', ''),' by user ', ' UserId=' ))
, ActionId = 800
WHERE SpName = 'Acc_CustomerUpdMatchLimit'
*/
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMatchLimit',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(Doing, 'Update creditpermatch ', ''),' by user ', ', UserId=' )),
		ActionId = 800
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END