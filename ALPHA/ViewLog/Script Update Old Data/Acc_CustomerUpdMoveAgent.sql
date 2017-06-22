/*
	DOING VALUE: Move agent SHA0264 from master id 120909 to master SHA02 (id 1138591) , Userid=1567559, IP=202.78.228.8 	
	ACTION: 606	Acc_CustomerUpdMoveAgent	Move Agent to new Master
	
	FORMAT: <Acc_CustomerUpdMoveAgent  AgentName='agent name' OldMasterId="" NewMasterName="" NewMasterId=""  Userid IP="ip address" /> 

	
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(DOING, 'Move agent ', 'AgentName=')
, dbo.UserLog_RunSP.ActionID = 606
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdMoveAgent'

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' from master id ', ',OldMasterId=')
WHERE  dbo.UserLog_RunSP.ActionID = 606

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, '  to master ', ',NewMasterName=')
WHERE  dbo.UserLog_RunSP.ActionID = 606


go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' (id ', ',NewMasterId=')
WHERE  dbo.UserLog_RunSP.ActionID = 606
go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ') , ', ',')
WHERE  dbo.UserLog_RunSP.ActionID = 606

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdMoveAgent', TrackingValue)
WHERE  dbo.UserLog_RunSP.ActionID = 606

*/ 
--20100109@Kiwi
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveAgent',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move agent ', 'AgentName='),' from master id ', ',OldMasterId='),' to master ', ',NewMasterName='),' (id ', ',NewMasterId='),') ,', ',')),
	ActionID = 606
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate
	IF  @@ROWCOUNT < 1000
			BREAK
END