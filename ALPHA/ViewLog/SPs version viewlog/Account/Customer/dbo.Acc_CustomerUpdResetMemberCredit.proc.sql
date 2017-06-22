ALTER PROCEDURE [dbo].[Acc_CustomerUpdResetMemberCredit]
	@agentID		INT,
	@closedOnly		BIT = 1,
	@UserID			INT,
	@IP				VARCHAR(15)='',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*	Created by: [Creator]
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [Credit]		
		- 20090915@Simon: Write Credit Log into Userlog_Credit table.
		- 20090916@Jamie: Write credit of all members under agent also 					
		- 20090917@Phuc: Write log into dblog.	
		- 20090926@Simon: Only write log the Credit != 0.
		- 20100102@Kiwi: Modify Log.
*/
BEGIN
SET NOCOUNT ON 
DECLARE @LogData NVARCHAR(300), @AgentUserName VARCHAR(30)
SET @ErrCode = 0

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[Credit]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
IF @ErrCode <> 0
	RETURN
--end
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @agentID, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
IF @ErrCode <>0 RETURN
--end

DECLARE @tmpCust TABLE( custid INT, Credit MONEY)

SELECT @AgentUserName = username FROM custinfo (NOLOCK) WHERE custid = @agentID

IF @closedOnly = 1
BEGIN
	UPDATE custinfo SET credit = 0 
	OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
	WHERE roleid = 1 AND closed=1 AND recommend = @agentID AND Credit != 0 
	SELECT @LogData = 'Clear Credit of the specified agent ' + @AgentUserName + ' and all downlines [CLOSED ACCOUNTS ONLY]'
END
ELSE
BEGIN
	UPDATE custinfo SET credit = 0 
	OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
	WHERE roleid = 1 AND recommend = @agentID AND Credit != 0 
	SELECT @LogData = 'Clear Credit of the specified agent ' + @AgentUserName + ' and all downlines'
END

-- Write Log Credit
INSERT INTO DBLOG.bodb_CustomerLog.dbo.Userlog_Credit (userid, custid, OldValue, NewValue, ip, doing, ActionID)
SELECT	@UserID, custid, Credit, 0, @ip, @LogData, 1202
FROM	@tmpCust 

END
GO

GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdResetMemberCredit]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdResetMemberCredit] TO [vnteam]