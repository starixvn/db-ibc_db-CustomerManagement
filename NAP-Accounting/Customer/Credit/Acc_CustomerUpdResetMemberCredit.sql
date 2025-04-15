/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdResetMemberCredit]
	@UplineID		INT,			-- SMA Input
	@closedOnly		BIT			= 1,
	@UserID		INT,
	@IP			VARCHAR(15)		='',
	@ErrCode		INT			= 0 OUTPUT,
	@ErrMsg		NVARCHAR(200)	= '' OUTPUT
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
		- 20241217@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]  
*/
BEGIN
	SET NOCOUNT ON 
	DECLARE @LogData VARCHAR(500), @UplineUserName VARCHAR(30), @isLicensee BIT = 0 , @IsDirectMember INT
	SET @ErrCode = 0

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @UplineID, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
		IF @ErrCode <>0 RETURN
	--end

	-- Chek Isdirect Member
	SELECT TOP 1 @IsDirectMember = i.recommend FROM Custinfo i WITH (NOLOCK) WHERE i.srecommend = @UplineID AND i.recommend = -4 AND i.roleid = 1
	SELECT TOP 1 @IsDirectMember = i.recommend FROM Custinfo i WITH (NOLOCK) WHERE i.mrecommend = @UplineID AND i.recommend = -3 AND i.roleid = 1
	SELECT TOP 1 @IsDirectMember = i.recommend FROM Custinfo i WITH (NOLOCK) WHERE i.recommend = @UplineID  AND i.recommend NOT IN (-3,-4) AND i.roleid = 1
	
	--check Licensee customer
	SELECT @isLicensee = 1
	FROM CustInfo ci WITH (NOLOCK)
		INNER JOIN Dep_CustSuper sup WITH (NOLOCK) ON ci.srecommend = sup.custid
	WHERE ci.custid = @UplineID

	DECLARE @tmpCust TABLE( custid INT, Credit MONEY)

	IF @IsDirectMember NOT IN (-3,-4) -- Normal Member: Upline is Agent
	BEGIN
		SELECT @UplineUserName = username
		FROM custinfo ci (NOLOCK) 
		WHERE ci.recommend = @UplineID

		IF @closedOnly = 1
		BEGIN
			IF (@isLicensee = 1)
			BEGIN
				UPDATE custinfo WITH (ROWLOCK,UPDLOCK) 
				SET credit = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
				WHERE roleid = 1 AND closed=1 AND recommend = @UplineID AND Credit != 0 
			END
			ELSE
			BEGIN
				UPDATE ci  
				SET credit = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
				FROM custinfo ci WITH (ROWLOCK,UPDLOCK)
					INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
				WHERE roleid = 1 AND cps.CloseInfo > 0 AND recommend = @UplineID AND Credit != 0 
			END

			SELECT @LogData = 'Clear Credit of the specified agent ' + @UplineUserName + ' and all downlines [CLOSED ACCOUNTS ONLY]'
		END
		ELSE
		BEGIN
			UPDATE custinfo WITH (ROWLOCK,UPDLOCK) 
			SET credit = 0,
				RepUpdateTime = dbo.f_GetDateTime2()
			OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
			WHERE roleid = 1 AND recommend = @UplineID AND Credit != 0 
			SELECT @LogData = 'Clear Credit of the specified agent ' + @UplineUserName + ' and all downlines'
		END

	END
	ELSE IF @IsDirectMember = -3	-- Master Direct Member: Upline is Master
	BEGIN
		SELECT @UplineUserName = username
		FROM custinfo ci (NOLOCK) 
		WHERE ci.mrecommend = @UplineID

		IF @closedOnly = 1
		BEGIN
			IF (@isLicensee = 1)
			BEGIN
				UPDATE custinfo WITH (ROWLOCK,UPDLOCK) 
				SET credit = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
				WHERE roleid = 1 AND closed=1 AND mrecommend = @UplineID AND recommend = -3 AND Credit != 0 
			END
			ELSE
			BEGIN
				UPDATE ci  
				SET credit = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
				FROM custinfo ci WITH (ROWLOCK,UPDLOCK)
					INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
				WHERE roleid = 1 AND cps.CloseInfo > 0 AND mrecommend = @UplineID AND recommend = -3 AND Credit != 0 
			END

			SELECT @LogData = 'Clear Credit of the specified agent ' + @UplineUserName + ' and all downlines [CLOSED ACCOUNTS ONLY]'
		END
		ELSE
		BEGIN
			UPDATE custinfo WITH (ROWLOCK,UPDLOCK) 
			SET credit = 0,
				RepUpdateTime = dbo.f_GetDateTime2()
			OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
			WHERE roleid = 1 AND mrecommend = @UplineID AND recommend = -3 AND Credit != 0 
			SELECT @LogData = 'Clear Credit of the specified agent ' + @UplineUserName + ' and all downlines'
		END
	END
	ELSE IF @IsDirectMember = -4	-- Super Direct Member: Upline is Super
	BEGIN
		SELECT @UplineUserName = username
		FROM custinfo ci (NOLOCK) 
		WHERE ci.srecommend = @UplineID

		IF @closedOnly = 1
		BEGIN
			IF (@isLicensee = 1)
			BEGIN
				UPDATE custinfo WITH (ROWLOCK,UPDLOCK) 
				SET credit = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
				WHERE roleid = 1 AND closed=1 AND srecommend = @UplineID AND recommend = -4 AND Credit != 0 
			END
			ELSE
			BEGIN
				UPDATE ci  
				SET credit = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
				FROM custinfo ci WITH (ROWLOCK,UPDLOCK)
					INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = ci.custid
				WHERE roleid = 1 AND cps.CloseInfo > 0 AND srecommend = @UplineID AND recommend = -4 AND Credit != 0 
			END

			SELECT @LogData = 'Clear Credit of the specified agent ' + @UplineUserName + ' and all downlines [CLOSED ACCOUNTS ONLY]'
		END
		ELSE
		BEGIN
			UPDATE custinfo WITH (ROWLOCK,UPDLOCK) 
			SET credit = 0,
				RepUpdateTime = dbo.f_GetDateTime2()
			OUTPUT deleted.custid, deleted.Credit INTO @tmpCust(custid, Credit)
			WHERE roleid = 1 AND srecommend = @UplineID AND recommend = -4 AND Credit != 0 
			SELECT @LogData = 'Clear Credit of the specified agent ' + @UplineUserName + ' and all downlines'
		END
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
