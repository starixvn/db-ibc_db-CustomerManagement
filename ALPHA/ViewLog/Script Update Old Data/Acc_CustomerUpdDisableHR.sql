
/* Update data of records, spName is Acc_CustomerUpdDisableHR

   DOING VALUE: Update customer Disabled Horseracing Status for CustID=1906396, DisableHorseracing=0, DisableDownline=1, SubAccName=, UserID=25520, Language=E, ErrCode=0 O, ErrMsg= O, IP=202.78.228.8
   
   ACTION : 1107	Acc_CustomerUpdDisableHR	Update Enabled/Disabled Horse racing status */
/*
UPDATE dbo.UserLog_RunSP with (ROWLOCK, UPDLOCK)
SET TrackingValue = GenerateXML('Acc_CustomerUpdDisableHR', REPLACE(Doing, 'Update customer Disabled Horseracing Status for', ''))
, ActionId = 1107
WHERE SpName = 'Acc_CustomerUpdDisableHR'

*/	
 -- 20100106@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdDisableHR',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'
 
DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE spname = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH (ROWLOCK, UPDLOCK)
	SET TrackingValue = dbo.GenerateXML(@SPName, Replace(Doing, 'Update customer Disabled Horseracing Status for', '')),
		ActionId = 1107
	WHERE	SPName = @SPName
			AND ActionID IS NULL
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
    IF  @@ROWCOUNT < 1000
        BREAK
END