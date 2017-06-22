ALTER PROCEDURE [dbo].[DBA_ArchiveAccount0_CloseAgent]
	@AccName varchar(50),
	@UserID int = 360418,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT
AS
    
SET NOCOUNT ON

Declare @roleid int, @AgentID int, @Enabled bit, @Closed bit

SELECT @roleid = roleid, @AgentID = custid, @Enabled = Enabled, @Closed = Closed
FROM custinfo (nolock)
WHERE username = @AccName

if isnull(@AgentID,0) = 0 or @roleid NOT in (2)
BEGIN
	Select @ErrMsg = @AccName +':'+ 'Invalid Agent User Name', @ErrCode = 101
	print @ErrMsg
	return
END

if @Enabled = 0
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has been archived!!', @ErrCode = 101
	print @ErrMsg
	return
END

if @Closed = 1
BEGIN
	Select @ErrMsg = @AccName +':'+ 'This agent has already been CLOSED!!', @ErrCode = 101
	print @ErrMsg
	return
END

Update custinfo set closed = 1 where custid = @AgentID


------------------
declare @LogSPData varchar(5000)

Select @LogSPData = 'DBA_ArchiveAccount0_CloseAgent AccName="'+ coalesce(cast(@AccName as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @AgentID,
	@ActionID = 1115,
	@TrackingValue = @LogSPData

GO
GRANT VIEW DEFINITION ON [dbo].[DBA_ArchiveAccount0_CloseAgent] TO [vnteam]