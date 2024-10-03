/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdResetMemberCredit]
	@agentID		INT,
	@closedOnly		BIT = 1,
	@UserID			INT,
	@IP				VARCHAR(15)='',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
AS
/*	Created by: [Creator]
	DB: DBCUST/CustDB
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
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181102@Johnson: Apply service broker for logging [Redmine: #103547]
		- 20210716@Tina: Lock account & indirect close account [redmine: #148600]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @LogData VARCHAR(500), @AgentUserName VARCHAR(30), @isLicensee BIT = 0
	SET @ErrCode = 0

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @agentID, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <>0 RETURN
	--end

	DECLARE @tmpCust TABLE( custid INT, Credit MONEY)

	SELECT @AgentUserName = username FROM custinfo (NOLOCK) WHERE custid = @agentID

	--check Licensee customer
	SELECT @isLicensee = 1
	FROM CustInfo ci WITH (NOLOCK)
		INNER JOIN Dep_CustSuper sup WITH (NOLOCK) ON ci.srecommend = sup.custid
	WHERE ci.custid = @agentID

	IF @closedOnly = 1
	BEGIN
		IF (@isLicensee = 1)
		BEGIN
			UPDATE custinfo WITH (ROWLOCK,UPDLOCK) SET credit = 0 
			OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
			WHERE roleid = 1 AND closed=1 AND recommend = @agentID AND Credit != 0 
		END
		ELSE
		BEGIN
			UPDATE ci  SET credit = 0 
			OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
			FROM custinfo ci WITH (ROWLOCK,UPDLOCK)
				INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
			WHERE roleid = 1 AND cps.CloseInfo > 0 AND recommend = @agentID AND Credit != 0 
		END

		SELECT @LogData = 'Clear Credit of the specified agent ' + @AgentUserName + ' and all downlines [CLOSED ACCOUNTS ONLY]'
	END
	ELSE
	BEGIN
		UPDATE custinfo WITH (ROWLOCK,UPDLOCK) SET credit = 0 
		OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
		WHERE roleid = 1 AND recommend = @agentID AND Credit != 0 
		SELECT @LogData = 'Clear Credit of the specified agent ' + @AgentUserName + ' and all downlines'
	END

	DECLARE @log xml, @SB_Error BIT = 0
		
	SELECT @log = (
		SELECT @UserID as UserID,CustID, Credit as OldValue, 0 as NewValue, @ip as IP, @LogData as Doing, 1202 as ActionID, getdate() as LogDate
		FROM @tmpCust
		FOR XML RAW('Row')
	)

	EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @log, 
													@MessageType='MessageType_CustomerLog_UserLog_Credit', 
													@functionName = 'UserLog_Others',
													@SB_Error = @SB_Error out

	--if ssb error
	IF @SB_Error = 1
	BEGIN
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
END
GO
