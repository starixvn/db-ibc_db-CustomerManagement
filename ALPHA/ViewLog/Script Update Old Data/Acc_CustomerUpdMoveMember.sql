/*
	DOING VALUE: Move member itPC001 from agent id 68289 to agent itPC (id 138948) , userid=8, ReturnErrCode=0, ErrCode=0 O, ErrMsg= O 
	ACTION: 615	Acc_CustomerUpdMoveMember	Move member to new Agent
	
	FORMAT: <Acc_CustomerUpdMoveMember MemberName='member' OldAgentId="" NewAgentName="" NewAgentId=""  Userid="" IP="ip address" /> 

	
*/
/*
UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(DOING, 'Move member ', 'MemberName=')
, dbo.UserLog_RunSP.ActionID = 615
WHERE dbo.UserLog_RunSP.SPName = 'Acc_CustomerUpdMoveMember'

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' from agent id ', ',OldAgentId=')
WHERE  dbo.UserLog_RunSP.ActionID = 615

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' to agent ', ',NewAgentName=')
WHERE  dbo.UserLog_RunSP.ActionID = 615


go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ' (id ', ',NewAgentId=')
WHERE  dbo.UserLog_RunSP.ActionID = 615
go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = REPLACE(TrackingValue, ') , ', ',')
WHERE  dbo.UserLog_RunSP.ActionID = 615

go

UPDATE dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML('Acc_CustomerUpdMoveMember', TrackingValue)
WHERE  dbo.UserLog_RunSP.ActionID = 615
*/
declare @SPname varchar (50), @fromdate smalldatetime, @todate smalldatetime
select @SPName = 'Acc_CustomerUpdMoveMember',
		@fromdate = '2009-01-01',
		@todate = '2009-06-30'

DECLARE @User TABLE (UserID INT)
INSERT INTO @User
SELECT userid FROM dbo.UserLog_RunSP (NOLOCK) WHERE SPName = @SPName

WHILE (1=1)
BEGIN
	UPDATE TOP (1000) dbo.UserLog_RunSP WITH(ROWLOCK, UPDLOCK)
SET TrackingValue = dbo.GenerateXML(@SPName, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DOING, 'Move member ', 'MemberName='),' from agent id ', ',OldAgentId='),' to agent ', ',NewAgentName='),' (id ', ',NewAgentId='),') ,', ',')),
	ActionID = 615
	WHERE	SPName = @SPName
			AND ActionID is null
			AND userid IN (SELECT userid FROM @User)
			AND logdate between @fromdate and @todate	
	IF  @@ROWCOUNT < 1000
			BREAK
END