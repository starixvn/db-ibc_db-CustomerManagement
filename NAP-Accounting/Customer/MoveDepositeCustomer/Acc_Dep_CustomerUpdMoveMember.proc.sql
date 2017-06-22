USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Dep_CustomerUpdMoveMember]    Script Date: 06/11/2015 09:42:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_Dep_CustomerUpdMoveMember    Script Date: 12/24/2013 2:49:26 AM ******/
/****** Object:  Stored Procedure dbo.Acc_Dep_CustomerUpdMoveMember    Script Date: 12/5/2013 5:09:05 PM ******/
ALTER PROCEDURE [dbo].[Acc_Dep_CustomerUpdMoveMember]
	@agentname varchar(40),
	@membername varchar(40),
	@userid int,
	@IP	VARCHAR(15)='',	
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a member to another agent
DB: DBTXN/CustDB
Original:

Revisions:
	- 20080213@Tommy: Check permission for account site
	- 20090525@Daniel: add check contraints for Horse & Finance
	- 20090528@Daniel: Fix check commission for all sports
	- 20090716@Jamie: Check auto master PT on agent 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
	- 20090917@Phuc: Write log to dblog	
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091112@Jamie: Check DisableOutright before moving
	- 200911224@Kiwi: Use loop to update in case number of tickets is huge
	- 20091214@Jamie: Correct member's commission
	- 20091216@Jamie: Separate 3rd Party to CustSetting3rd 
	- 20091222@Kiwi: Apply Execution Replication (dbo.Acc_ExecRep_00)
	- 20100114@Kiwi: Call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
	- 20100205@Jamie: Update the CS status of Member when Agent disabled
	- 20100209@Lewin: Change sp format
	- 20100512@Henry: Check DisableOpenTote before moving
	- 20100911@Henry: Check Number Game + Bingo before moving
	- 20101019@Henry: Record execution time
	- 20110317@Johnson: check for Greyhound and Harness
	- 20110413@Lukas: check closed/suspended
	- 20110801@Johnson: - remove bettype dead ball over/under of number game
						- add more bettype for nubmer game Warrior,  Next combo and Number Group
	- 20110907@Sophia: Change Linked Server from DB052 to DB053	
	- 20110930@Johnson: Add more groups under Won currency.
	- 20111020@Tom:Add check P2P Game: Status, game setting, commission.
	- 20120322@Johnson: Check live casino
	- 20130723@Jim: change server alias name
	- 20131108@Elodie: Splitting bodb02 into CustDB (Roll back updates on custinfo,customer table in main SP)  	
	- 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]			
	 
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error. 
	Max errorcode:	133
• @ErrMsg: Error description.
Note: Check Disable status between Agent and Member 
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()


EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

declare @srecommend			int, 
		@mrecommend			int, 
		@recommend			int, 
		@acurrency			tinyint,
		--==Member Info ==--
		@srecommend_old 	int, 
		@mrecommend_old 	int, 
		@recommend_old		int, 
		@currency_old		tinyint,
		@custid				int, 
		--== Enable/Disable HR, FI  ==--- 
		@adisable151_31		bit,-- @adisableHR -> @adisable151_31 
		@disable151_31		bit,-- @disableHR -> @disable151_31 
		@adisableFI			bit, 
		@disableFI			bit,
		@aDisableOutright	bit,
		@DisableOutright	bit,
		@aSyncCasino		bit,
		@SyncCasino			bit,
		@aSyncLiveCasino 	bit,
		@SyncLiveCasino  	bit,
		@aSyncBingo			bit,
		@SyncBingo			bit,
		@aDisable151_41		BIT,-- @aDisableOpenTote -> @aDisable151_41
		@Disable151_41		BIT,-- @Disable151_41 -> @Disable151_41
		@aDisable151_51		BIT,
		@Disable151_51		BIT,
		@aDisable152_41		BIT,
		@Disable152_41		BIT,
		@aDisable152_51		BIT,
		@Disable152_51		BIT,
		@aDisable153_51		BIT,
		@Disable153_51		BIT,
		@aDisableBingo		BIT,
		@DisableBingo		BIT,
		@aDisableNumber		BIT,
		@DisableNumber		BIT,
		@aClosed			BIT,
		@Closed				BIT,
		@aSuspended			BIT,
		@Suspended			BIT
		--@aMaxTransferP2P	MONEY,
		--@MaxTransferP2P		MONEY,
		--@aIsAutoResetP2P	BIT,
		--@IsAutoResetP2P		BIT,
		--@aDisableP2P		BIT, 
		--@DisableP2P			BIT, 
		--@aDisableFunP2P		BIT,
		--@DisableFunP2P		BIT
		
select	@srecommend			= srecommend, 
		@mrecommend			= mrecommend, 
		@recommend			= recommend,
		@acurrency			= currency, 
		@adisable151_31		= DisableHorseracing, 
		@adisableFI			= DisableFinancial,
		@aDisableOutright	= DisableOutright,
		@aSyncCasino		= syncCasino,
		@aSyncLiveCasino	= SyncLiveCasino,
		@aSyncBingo			= syncBingo,
		@aDisable151_41		= DisableOpenTote,
		@aDisable151_51		= Disable151_AU,
		@aDisable152_41		= Disable152_UK,
		@aDisable152_51		= Disable152_AU,
		@aDisable153_51		= Disable153_AU,
		@aDisableBingo		= DisableBingo,
		@aDisableNumber		= DisableNumber,
		@aClosed			= closed,
		@aSuspended			= reject
		--@aMaxTransferP2P	= MaxTransferP2P, 
		--@aIsAutoResetP2P	= IsAutoResetP2P, 
		--@aDisableP2P		= DisableP2P, 
		--@aDisableFunP2P		= DisableFunP2P	
from	custinfo with (nolock)
where	username = @agentname and roleid = 2

select	@custid				= custid, 
		@recommend_old		= recommend, 
		@srecommend_old		= srecommend, 
		@mrecommend_old		= mrecommend,
		@currency_old		= currency,
		@disable151_31		= DisableHorseracing, 
		@disableFI			= DisableFinancial,
		@DisableOutright	= DisableOutright,
		@SyncCasino			= SyncCasino ,
		@SyncLiveCasino		= SyncLiveCasino,
		@SyncBingo			= SyncBingo ,
		@Disable151_41		= DisableOpenTote,
		@Disable151_51		= Disable151_AU,
		@Disable152_41		= Disable152_UK,
		@Disable152_51		= Disable152_AU,
		@Disable153_51		= Disable153_AU,
		@DisableBingo		= DisableBingo,
		@DisableNumber		= DisableNumber,
		@Closed				= closed,
		@Suspended			= reject
		--@MaxTransferP2P		= MaxTransferP2P, 
		--@IsAutoResetP2P		= IsAutoResetP2P, 
		--@DisableP2P			= DisableP2P, 
		--@DisableFunP2P		= DisableFunP2P
from	custinfo with (nolock) 
where	username = @membername and roleid = 1

if isnull(@recommend, 0) = 0
BEGIN
	Select @ErrMsg = 'Error agent ' + @agentname + ': agent not found.',
		@ErrCode = 101					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if isnull(@recommend_old, 0) = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent not found.',
		@ErrCode = 102					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if isnull(@recommend, 0) = @recommend_old
BEGIN
	Select @ErrMsg = 'Error occurs. The member '+ @membername +' already belongs to agent '+ @agentname +'.',
		@ErrCode = 103					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END
--check an account disabled or not 
EXEC dbo.Acc_CustomerSelCheckEnable @username = @membername, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
if @ErrCode <>0		return 

EXEC dbo.Acc_CustomerSelCheckEnable @username = @agentname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
if @ErrCode <>0		return 

if @currency_old <> @acurrency
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': currency of new agent and member does not match.',
		@ErrCode = 104					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

----------------------------------
-- check is closed
IF @aClosed = 1
BEGIN
	SELECT @ErrMsg = 'Error occurs. Cannot move to closed agent.',
		@ErrCode = 105
	RETURN
END

--Check Horse, FI enable status:
if @adisable151_31 = 1 and @disable151_31 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled SA Racing but new agent is not enabled SA Racing.',
		@ErrCode = 106					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check OpenTote
if @aDisable151_41 = 1 and @Disable151_41 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled UK/IRish Racing but new agent is not enabled UK/IRish Racing.',
		@ErrCode = 107				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Horse Racing for AU Tote
if @aDisable151_51 = 1 and @Disable151_51 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Racing but new agent is not enabled Aust Racing.',
		@ErrCode = 108
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Greyhound for UK Tote
if @aDisable152_41 = 1 and @Disable152_41 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled UK Greyhound but new agent is not enabled UK Greyhound.',
		@ErrCode = 109				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Greyhound for AU Tote
if @aDisable152_51 = 1 and @Disable152_51 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Greyhound but new agent is not enabled Aust Greyhound.',
		@ErrCode = 110				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check Harness for AU Tote
if @aDisable153_51 = 1 and @Disable153_51 = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Harness but new agent is not enabled Aust Harness.',
		@ErrCode = 111				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if @adisableFI = 1 and @disableFI = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Finance but new agent is not enabled Finance.',
		@ErrCode = 112
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END


--Check CS SyncCasino between Agent and Member 
IF @aSyncCasino = 0 AND @SyncCasino = 1 
BEGIN
	SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': member is synchronized Casino but new agent is not synchronized Casino.',
		@ErrCode = 113	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return	
END 

--Check SyncBingo between Agent and Member 
IF @aSyncBingo = 0 AND @SyncBingo = 1 
BEGIN
	SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': member is synchronized Bingo but new agent is not synchronized Bingo.',
		@ErrCode = 114	
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return	
END 

--Check Bingo & Number enable status:
if @adisableBingo = 1 and @disableBingo = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Bingo but new agent is not enabled Bingo.',
		@ErrCode = 115					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if @adisableNumber = 1 and @disableNumber = 0
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Number Game but new agent is not enabled Number Game.',
		@ErrCode = 116
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

IF @aSyncLiveCasino = 0 AND @SyncLiveCasino = 1
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is synchronized Live Casino but new agent is not synchronized Live Casino.',
		@ErrCode = 117
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END
----------------------------------
--Check Horse, FI, Casino sync status:
if exists(select 1 from dep_custsetting3rd with (nolock) where custid = @custid and sporttype = 151)
	AND not exists(select 1 from dep_custsetting3rd with (nolock) where custid = @recommend and sporttype = 151)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Horse Racing setting.',
		@ErrCode = 118					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--number game
if exists(select 1 from dep_custsetting3rd with (nolock) where custid = @custid and sporttype = 161)
	AND not exists(select 1 from dep_custsetting3rd with (nolock) where custid = @recommend and sporttype = 161)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Number Game setting.',
		@ErrCode = 120					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

if exists(select 1 from custinfo with (nolock) where custid = @custid and SyncCasino = 1)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already Casino-synchronized.',
		@ErrCode = 121					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--bingo
if exists(select 1 from custinfo with (nolock) where custid = @custid and SyncBingo = 1)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already Bingo-synchronized.',
		@ErrCode = 122					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END
--live casino
IF EXISTS (SELECT 1 FROM CustInfo WITH(NOLOCK) WHERE custid = @custid AND SyncLiveCasino = 1)
BEGIN
	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already live Casino-synchronized.',
		@ErrCode = 123					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

--Check identical auto master position taking for live casino
IF EXISTS (
		SELECT 1
		FROM CustSettingGame acs_old WITH(NOLOCK) 
			INNER JOIN CustSettingGame acs_new WITH(NOLOCK) ON acs_new.custid = @recommend AND acs_new.sporttype = acs_old.sporttype AND acs_new.bettype = acs_old.bettype
		WHERE acs_old.custid = @recommend_old AND acs_old.sporttype = 162 AND acs_old.bettype = 1101
			AND acs_old.isautompositiontaking <> acs_new.isautompositiontaking
	)
BEGIN
	Select @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		@ErrCode = 202					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

----Check P2P :Game Setting
--IF exists(
--	SELECT TOP 1 1
--	FROM dbo.P2PGROUPCOMM me WITH(NOLOCK)
--		INNER JOIN dbo.P2PGROUPCOMM a WITH(NOLOCK)
--			ON a.GroupID = me.GroupID
--		WHERE  me.custid = @custid AND A.custid = @recommend
--				AND (a.discount < me.playerdiscount )
--)
--BEGIN
--	Select @ErrMsg = 'Error agent ' + @agentname + ', member ' + @membername + ': P2P''s commission of member is greater than P2P''s commission of new agent .',
--		@ErrCode = 203
--	return
--END

----------------------------
DECLARE
	@apositiontaking_1 SMALLMONEY,
	@apositiontaking_2 SMALLMONEY,
	@apositiontaking_3 SMALLMONEY,
	@apositiontaking_4 SMALLMONEY,
	@apositiontaking_5 SMALLMONEY,
	@apositiontaking_6 SMALLMONEY,
	@apositiontaking_7 SMALLMONEY,
	@apositiontaking_8 SMALLMONEY,
	@apositiontaking_9 SMALLMONEY,
	@apositiontaking_10 SMALLMONEY,
	
	@alivepositiontaking_1 SMALLMONEY,
	@alivepositiontaking_3 SMALLMONEY,
	@alivepositiontaking_7 SMALLMONEY,
	@alivepositiontaking_8 SMALLMONEY,
	
	@v2apositiontaking_1 SMALLMONEY,
	@v2apositiontaking_2 SMALLMONEY,
	@v2apositiontaking_3 SMALLMONEY,
	@v2apositiontaking_7 SMALLMONEY,
	@v2apositiontaking_8 SMALLMONEY,
	--@v2apositiontaking_9 SMALLMONEY,
	@v2apositiontaking_20 SMALLMONEY,
	
	@v3apositiontaking_1 SMALLMONEY,
	@v3apositiontaking_2 SMALLMONEY,
	@v3apositiontaking_3 SMALLMONEY,
	@v3apositiontaking_20 SMALLMONEY,

	@v5apositiontaking_1 SMALLMONEY,
	@v5apositiontaking_2 SMALLMONEY,
	@v5apositiontaking_3 SMALLMONEY,
	@v5apositiontaking_20 SMALLMONEY,

	@v8apositiontaking_1 SMALLMONEY,
	@v8apositiontaking_3 SMALLMONEY,
	@v8apositiontaking_20 SMALLMONEY,

	@v10apositiontaking_1 SMALLMONEY,
	@v10apositiontaking_2 SMALLMONEY,
	@v10apositiontaking_3 SMALLMONEY,
	@v10apositiontaking_20 SMALLMONEY,

	@v11apositiontaking_1 SMALLMONEY,
	@v11apositiontaking_20 SMALLMONEY,
	
	@v99apositiontaking_1 SMALLMONEY,
	@v99apositiontaking_2 SMALLMONEY,
	@v99apositiontaking_3 SMALLMONEY,
	@v99apositiontaking_9 SMALLMONEY,
	@v99apositiontaking_20 SMALLMONEY,

	@v201apositiontaking_2 SMALLMONEY,
	@v201apositiontaking_3 SMALLMONEY,
	
	@v151apositiontaking_31 SMALLMONEY,
	@v151apositiontaking_32 SMALLMONEY,
	@v151apositiontaking_41 SMALLMONEY,
	@v151apositiontaking_42 SMALLMONEY,
	@v151apositiontaking_51 SMALLMONEY,
	@v151apositiontaking_52 SMALLMONEY,
	@v152apositiontaking_41 SMALLMONEY,
	@v152apositiontaking_42 SMALLMONEY,
	@v152apositiontaking_51 SMALLMONEY,
	@v152apositiontaking_52 SMALLMONEY,
	@v153apositiontaking_51 SMALLMONEY,
	@v153apositiontaking_52 SMALLMONEY,
	
	@v161apositiontaking_81 SMALLMONEY,
	@v161apositiontaking_83 SMALLMONEY,
	--@v161apositiontaking_85 SMALLMONEY,
	@v161apositiontaking_86 SMALLMONEY,
	@v161apositiontaking_88 SMALLMONEY,
	
	@v161alivepositiontaking_85 SMALLMONEY,
	@v161alivepositiontaking_86 SMALLMONEY,
	@v161alivepositiontaking_87 SMALLMONEY,
	@v161alivepositiontaking_89 SMALLMONEY,
	@v161alivepositiontaking_90 SMALLMONEY,
	--livecasino
	@v162apositiontaking_1101 SMALLMONEY
	

SELECT @apositiontaking_1 = apositiontaking FROm dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=1 AND islive = 0
SELECT @alivepositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=1 AND islive = 1
SELECT @apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=1 AND islive = 0
SELECT @alivepositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=1 AND islive = 1
SELECT @apositiontaking_7 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=1 AND islive =0
SELECT @alivepositiontaking_7 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=1 AND islive =1
SELECT @apositiontaking_8 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=1 AND islive =0
SELECT @alivepositiontaking_8 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=1 AND islive =1

SELECT @apositiontaking_2 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=1
SELECT @apositiontaking_4 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=4 AND sporttype=1
SELECT @apositiontaking_5 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=5 AND sporttype=1
SELECT @apositiontaking_6 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=6 AND sporttype=1
SELECT @apositiontaking_9 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=1
SELECT @apositiontaking_10 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=10 AND sporttype=1

SELECT @v2apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=2
SELECT @v2apositiontaking_2 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=2
SELECT @v2apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=2
SELECT @v2apositiontaking_7 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=2
SELECT @v2apositiontaking_8 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=2
SELECT @v2apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=2

SELECT @v3apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=3
SELECT @v3apositiontaking_2 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=3
SELECT @v3apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=3
SELECT @v3apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=3

SELECT @v5apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=5
SELECT @v5apositiontaking_2 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=5
SELECT @v5apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=5
SELECT @v5apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=5

SELECT @v8apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=8
SELECT @v8apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=8
SELECT @v8apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=8

SELECT @v10apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=10
SELECT @v10apositiontaking_2 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=10
SELECT @v10apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=10
SELECT @v10apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=10

SELECT @v11apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=11
SELECT @v11apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=11

SELECT @v99apositiontaking_1 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=99
SELECT @v99apositiontaking_2 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=99
SELECT @v99apositiontaking_3 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=99
SELECT @v99apositiontaking_9 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=99
SELECT @v99apositiontaking_20 = apositiontaking FROM dep_custsetting WITH (NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=99

SELECT @v201apositiontaking_2 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=201
SELECT @v201apositiontaking_3 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=201

SELECT @v151apositiontaking_31 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=31 AND sporttype=151
SELECT @v151apositiontaking_32 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=32 AND sporttype=151
SELECT @v151apositiontaking_41 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=151
SELECT @v151apositiontaking_42 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=151
SELECT @v151apositiontaking_51 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=151
SELECT @v151apositiontaking_52 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=151
SELECT @v152apositiontaking_41 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=152
SELECT @v152apositiontaking_42 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=152
SELECT @v152apositiontaking_51 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=152
SELECT @v152apositiontaking_52 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=152
SELECT @v153apositiontaking_51 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=153
SELECT @v153apositiontaking_52 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=153

SELECT @v161apositiontaking_81 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=81 AND sporttype=161
SELECT @v161apositiontaking_83 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=83 AND sporttype=161
SELECT @v161apositiontaking_86 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=86 AND sporttype=161 AND islive = 0
SELECT @v161apositiontaking_88 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=88 AND sporttype=161

SELECT @v161alivepositiontaking_85 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=85 AND sporttype=161
SELECT @v161alivepositiontaking_86 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=86 AND sporttype=161 AND islive = 1
SELECT @v161alivepositiontaking_87 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=87 AND sporttype=161
SELECT @v161alivepositiontaking_89 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=89 AND sporttype=161
SELECT @v161alivepositiontaking_90 = apositiontaking FROM dep_custsetting3rd WITH (NOLOCK) WHERE custid = @custid AND bettype=90 AND sporttype=161

SELECT @v162apositiontaking_1101 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 162 AND bettype = 1101


print  'Move member '+@membername+' from agent id '+convert(varchar(20), @recommend_old)+' to agent '+@agentname+' (id ' + convert(varchar(20), @recommend)+')'

----P2PGAMESETTING table
--UPDATE G_P
--SET stakelevel1 = CASE WHEN s.stakelevel1 = 1 AND G_P.stakelevel1 = 1 THEN 1 ELSE 0 END,
--	stakelevel2 = CASE WHEN s.stakelevel2 = 1 AND G_P.stakelevel2 = 1 THEN 1 ELSE 0 END,
--	stakelevel3 = CASE WHEN s.stakelevel3 = 1 AND G_P.stakelevel3 = 1 THEN 1 ELSE 0 END,
--	stakelevel4 = CASE WHEN s.stakelevel4 = 1 AND G_P.stakelevel4 = 1 THEN 1 ELSE 0 END,
--	stakelevel5 = CASE WHEN s.stakelevel5 = 1 AND G_P.stakelevel5 = 1 THEN 1 ELSE 0 END
--FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
--	INNER JOIN 
--		( SELECT * FROM dbo.P2PGameSetting s WITH(NOLOCK) WHERE custid = @srecommend) s
--			ON G_P.BETTYPE = s.BETTYPE
--WHERE G_P.custid = @CustID

--IF @@ERROR <> 0 
--	BEGIN
--		IF @@ERROR <>0
--			SELECT	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (P2PGameSetting).',
--					@ErrCode = 300
--		RETURN
--	END

--if (@aDisableP2P = 1 and @DisableP2P = 0) 
--	OR (@aIsAutoResetP2P = 0 and @IsAutoResetP2P = 1)
--	OR (@aDisableFunP2P = 1 and @DisableFunP2P = 0)
--	OR (@aMaxTransferP2P < @MaxTransferP2P)
--BEGIN
--	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
--	SET		DisableP2P = CASE WHEN @aDisableP2P = 1 THEN 1 ELSE DisableP2P END,
--			DisableFunP2P = CASE WHEN @aIsAutoResetP2P = 1 THEN 1 ELSE DisableFunP2P END,
--			IsAutoResetP2P = CASE WHEN @aDisableFunP2P = 0 THEN 0 ELSE IsAutoResetP2P END,
--			MaxTransferP2P = CASE WHEN @aMaxTransferP2P < MaxTransferP2P THEN @aMaxTransferP2P ELSE MaxTransferP2P END
--	WHERE	custid = @CustID
--	IF @@ERROR <>0
--	BEGIN
--		Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 301
--		RETURN 
--	END
--END

----P2PGroupComm table
--UPDATE G_C 
--SET sdiscount = a.sdiscount,
--	adiscount  =a.adiscount,
--	discount  =a.discount
--FROM P2PGroupComm G_C WITH (ROWLOCK, UPDLOCK)
--	INNER JOIN 
--		( SELECT * FROM dbo.P2PGROUPCOMM a WITH(NOLOCK) WHERE custid = @recommend) a
--		ON G_C.GroupID = a.GroupID
--WHERE G_C.custid = @custid

--IF @@ERROR <> 0 
--BEGIN
--	IF @@ERROR <>0
--		SELECT	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 302
--	RETURN
--END

--customer table
update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend, mrecommend = @mrecommend,
											recommend = @recommend
where custid = @custid
if @@Error <> 0 
BEGIN
	
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid

	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (customer).',
		@ErrCode = 303				 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	
	return
END

--custinfo table
update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend, mrecommend = @mrecommend,
											recommend = @recommend
where custid = @custid
if @@Error <> 0 
BEGIN
	--ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											recommend = @recommend_old
	where custid = @custid

	Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 304					 
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	
	return
END

--- update suspended status
IF @aSuspended = 1 AND @Suspended = 0
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	reject = 1 
	WHERE	custid = @custid
	IF @@ERROR <>0
	BEGIN
		Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 305
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
	END
END

IF @aDisableOutright = 1 AND (@aDisableOutright <> @DisableOutright)
BEGIN 

	UPDATE Custinfo WITH (UPDLOCK,ROWLOCK)
	SET DisableOutright = 1 
	WHERE custid = @custid 
	IF @@ERROR<>0
	BEGIN
		Select @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 306
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
	END 
END 

--Apply ExeReplication
-- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
EXEC DBTXN.bodb02.dbo.Acc_ExecRep_00 
	@custid = @custid,
	@recommend = @recommend,
	@recommend_old = @recommend_old,
	@mrecommend = @mrecommend,
	@mrecommend_old = @mrecommend_old,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 1,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <> 0
BEGIN			
	-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  				
	--ROLLBACK TRANSACTION MANUALLY     
    UPDATE customer WITH (ROWLOCK, UPDLOCK) 
    SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	WHERE custid = @custid
	
	UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
	SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	WHERE custid = @custid
	
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)                  
    RETURN
END	

EXEC DBTXN.bodb02.dbo.Acc_ExecRep_00 
	@custid = @custid,
	@recommend = @recommend,
	@recommend_old = @recommend_old,
	@mrecommend = @mrecommend,
	@mrecommend_old = @mrecommend_old,
	@srecommend = @srecommend,
	@srecommend_old = @srecommend_old,
	@roleid = 1,
	@ErrCode = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT
IF @ErrCode <> 0
BEGIN			
	-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  				
	--ROLLBACK TRANSACTION MANUALLY     
    UPDATE customer WITH (ROWLOCK, UPDLOCK) 
    SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	WHERE custid = @custid
	
	UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
	SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	WHERE custid = @custid
	
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)                  
    RETURN
END	

--super 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		sdiscount = scs.sdiscount
FROM	Dep_CustSetting3rd scs WITH (NOLOCK)
		INNER JOIN Dep_CustSetting3rd cs ON scs.custid = @srecommend AND cs.custid = @custid 
										AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
WHERE	scs.sdiscount< cs.sdiscount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update super commission unsuccessfully.',
		@ErrCode = 307				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--live casino

UPDATE cs WITH(UPDLOCK,ROWLOCK)
SET sdiscount = scs.sdiscount
FROM CustSettingGame scs WITH(NOLOCK)
	INNER JOIN CustSettingGame cs ON scs.custid = @srecommend AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101
	AND scs.sdiscount < cs.sdiscount

IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update super commission unsuccessfully.',
		@ErrCode = 308				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END


--master 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		adiscount = mcs.adiscount 
FROM	Dep_CustSetting3rd mcs WITH (NOLOCK)
		INNER JOIN Dep_CustSetting3rd cs ON mcs.custid = @mrecommend AND cs.custid = @custid 
										AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
WHERE	mcs.adiscount< cs.adiscount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update master commission unsuccessfully.',
		@ErrCode = 310					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--live casino
UPDATE cs WITH(UPDLOCK,ROWLOCK) 
SET adiscount = mcs.adiscount
FROM CustSettingGame mcs WITH(NOLOCK) 
	INNER JOIN CustSettingGame cs ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101
	AND mcs.adiscount < cs.adiscount

IF @@ERROR <> 0
BEGIN
	Select @ErrMsg = 'update master commission unsuccessfully.',
		@ErrCode = 311					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--agent 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		cs.discount = acs.discount
FROM	Dep_CustSetting3rd acs WITH (NOLOCK)
		INNER JOIN Dep_CustSetting3rd cs ON acs.custid = @recommend AND cs.custid = @custid 
										AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE	acs.discount< cs.discount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update agent commission unsuccessfully.',
		@ErrCode = 313					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

--live casino
UPDATE cs WITH(UPDLOCK,ROWLOCK) 
SET cs.discount = acs.discount
FROM CustSettingGame acs WITH(NOLOCK)
	INNER JOIN CustSettingGame cs ON acs.custid = @recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101 
	AND acs.discount < cs.discount

IF @@ERROR <> 0
BEGIN
	Select @ErrMsg = 'update agent commission unsuccessfully.',
		@ErrCode = 314					 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END	
	
--member 3rd
UPDATE	cs WITH (UPDLOCK,ROWLOCK)
SET		playerdiscount = acs.discount 
FROM	Dep_CustSetting3rd acs WITH (NOLOCK)
		INNER JOIN Dep_CustSetting3rd cs ON acs.custid = @recommend AND cs.custid = @custid 
									 AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 

WHERE	acs.discount< cs.playerdiscount
IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update commission unsuccessfully.',
		@ErrCode = 316				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END
--live casino 
UPDATE cs WITH(UPDLOCK,ROWLOCK)
SET playerdiscount = acs.discount
FROM CustSettingGame acs WITH(NOLOCK) 
	INNER JOIN CustSettingGame cs ON acs.custid = @recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
WHERE cs.custid = @custid AND cs.sporttype = 162 AND cs.bettype = 1101 
	AND acs.discount < cs.playerdiscount

IF @@ERROR<>0
BEGIN
		Select @ErrMsg = 'update commission unsuccessfully.',
		@ErrCode = 317				 
		if @ReturnErrCode = 0
			RaisError (@ErrMsg, 16, 1)
		return
END

DECLARE @LogSPData VARCHAR(4000)
SELECT  @LogSPData = '<Acc_CustomerUpdMoveMember  MemberName="' + @membername + '" OldAgentId="'
            + CONVERT(VARCHAR(20), @recommend_old) + '" NewAgentName="' + @agentname+ '" '
            + 'NewAgentId="' + CONVERT(VARCHAR(20), @recommend) + '" '  
			+'userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + '" '
			+'ReturnErrCode="' + COALESCE(CAST(@ReturnErrCode AS VARCHAR(50)), SPACE(1)) + '" '
			+'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
			+'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

/*615	Acc_CustomerUpdMoveMember	Move member to new Agent*/
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @custid,
        @ActionID = 615, 
		@TrackingValue = @LogSPData,
		@duration = @duration

GO
GRANT EXECUTE ON [dbo].[Acc_Dep_CustomerUpdMoveMember] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Dep_CustomerUpdMoveMember] TO [vnteam] AS [dbo]