/*
	DOING VALUE: Update group of membersubaru01 from a to b, Userid=25520, IP=202.78.228.8, ErrCode=0 O, ErrMsg= O  
	
	ACTION: 608 Acc_CustomerUpdUserGroup Change user group 
	
	TRACKING VALUE: <Acc_CustomerUpdUserGroup CustName="member name" 
From="group A" To="B" UserId="25520" 
IP="" ErrCode="" ErrMsg="" />
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(Doing, 'Update group of', 'CustName=')
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserGroup'
GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, 'from', ', From=')
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserGroup'

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, 'to', ', To=')
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserGroup'

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ', Userid', '", Userid"')
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserGroup'

GO
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdUserGroup', TrackingValue)
, ActionID = 608
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdUserGroup'
*/
--20100109@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdUserGroup',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Update group of', 'CustName='),'from', ', From='),'to', ', To='),', Userid', '", Userid"')),
	ActionID = 608
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK

END