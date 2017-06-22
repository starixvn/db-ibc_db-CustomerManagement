/*
	DOING VALUE: Move master SHA02 from super id 13 to super SHA (id 1131889) , Userid=1567559, IP=202.78.228.8  
	ACTION: 613	DBA_CustomerUpdMoveMaster	IT Admin moved Master to new Super
	
	FORMAT: <Acc_CustomerUpdMoveMaster  MasterName='agent name' OldSuperId="" NewSuperName="" NewSuperId=""  Userid="" IP="ip address" /> 

	
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(DOING, 'Move master ', 'MasterName=')
, dbo.UserLog_RunSP.ActionID = 613
WHERE dbo.UserLog_RunSP.SPName = 'DBA_CustomerUpdMoveMaster'

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' from super id ', ',OldSuperId=')
WHERE  dbo.UserLog_RunSP.ActionID = 613

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' to master ', ',NewSuperName=')
WHERE  dbo.UserLog_RunSP.ActionID = 613


go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' (id ', ',NewSuperId=')
WHERE  dbo.UserLog_RunSP.ActionID = 613
go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ') , ', ',')
WHERE  dbo.UserLog_RunSP.ActionID = 613

 go
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('DBA_CustomerUpdMoveMaster', TrackingValue)
WHERE  dbo.UserLog_RunSP.ActionID = 613

*/
--20100109
declare @SPname varchar (100), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'DBA_CustomerUpdMoveMaster',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move master ', 'MasterName='),' from super id ', ',OldSuperId='),' to super ', ',NewSuperName='),' (id ', ',NewSuperId='),') ,', ',')),
	ActionID = 613
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)	
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END