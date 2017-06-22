USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdResetMemberCredit]    Script Date: 06/10/2015 14:51:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_CustomerUpdResetMemberCredit    Script Date: 12/25/2013 3:09:38 PM ******/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdResetMemberCredit]
	@agentID		INT,
	@closedOnly		BIT = 1,
	@UserID			INT,
	@IP				VARCHAR(15)='',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT,
	@system VARCHAR(50) = ''
AS
/*	Created by: [Creator]
	DB: DBTXN/bodb02
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [Credit]		
		- 20090915@Simon: Write Credit Log into Userlog_Credit table.
		- 20090916@Jamie: Write credit of all members under agent also 				 	
		- 20090917@Phuc: Write log into dblog.	
		- 20090926@Simon: Only write log the Credit != 0.
		- 20100102@Kiwi: Modify Log.
		- 20110907@Sophia: Change Linked Server from DB052 to DB053
		- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
		- 20131025@Lukas: add system define permission checking when call from external accounting		
		- 20150609@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
*/
BEGIN
SET NOCOUNT ON 
DECLARE @LogData VARCHAR(500), @AgentUserName VARCHAR(30)
SET @ErrCode = 0

IF @system = 'EXTERNAL'
BEGIN
	--- no check permssion in case of calling from external accounting
	SET @ErrMsg = ''
END
ELSE
BEGIN
	--Check permission for account site: @phuc20080213
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[Credit]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end
END

--Check disable user
EXEC dbo.Acc_CustomerSelCheckEnable @custid = @agentID, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
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
BEGIN TRY
	INSERT INTO DBLOG.bodb_CustomerLog.dbo.Userlog_Credit (userid, custid, OldValue, NewValue, ip, doing, ActionID)
	SELECT	@UserID, custid, Credit, 0, @ip, @LogData, 1202
	FROM	@tmpCust 
END TRY
BEGIN CATCH
	Select @LogData = @LogData + ' ErrMsg=' + error_message()
	
	INSERT INTO bodb_CustomerLog.dbo.Userlog_Credit (userid, custid, OldValue, NewValue, ip, doing, ActionID)
	SELECT	@UserID, custid, Credit, 0, @ip, @LogData, 1202
	FROM	@tmpCust 
END CATCH

END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdResetMemberCredit] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdResetMemberCredit] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdResetMemberCredit] TO [vnteam] AS [dbo]