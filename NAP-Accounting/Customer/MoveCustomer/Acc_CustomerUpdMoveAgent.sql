SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveAgent]
	@mastername		varchar(40),
	@agentname		varchar(40),
	@userid			int,
	@IP				varchar(15)='',
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a agent to another master
DB: DBTXN/CustDB
Original:

Revisions:
    - 20090525@Daniel: add check contraints for Horse & Finance
	- 20090528@Daniel: remove check groupe, groupf when checking commission
	- 20090716@Jamie: check auto master pt 
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]		
	- 20090917@Phuc: Write log to dblog	
	- 20090923@Shifu: Remove checking synchronized casino constraint
	- 20090924@Jamie:  Not allowing moving master see if the total tickets under master exceed 20000
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091102@Kiwi: Remove RaisError and change to check total tickets from db02 to db052
	- 20091104@Jamie: Remove the input param @update 
	- 20091107@Daniel: use @temp table to cache custids for updating.
	- 20091110@Daniel: Add check internal contraint
	- 20091112@Jamie: Check DisableOutright before moving
	- 200911224@Kiwi: Use loop to update in case number of tickets is huge
	- 20091205@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20091222@Kiwi: Apply Execution Replication (use dbo.Acc_ExecRep_00)
	- 20100114@Kiwi: Change the way to check allowed Auto Master PT and Call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
	- 20100115@Jamie: Remove checking syncCasino and add the constrainst for checking syncCasino between Master and Agent 
	- 20100205@Jamie: Update the Casino status of Agent when master disabled 
	- 20100208@Lewin: Change LogSP data format
	- 20100512@Henry: Check DisableOpenTote before moving
	- 20100911@Henry: Check Number Game + Bingo before moving
	- 20101019@Henry: Record execution time
	- 20110318@Johnson: check for Greyhound and Harness
	- 20110413@Lukas: check closed/suspended
	- 20110801@Johnson: - remove bettype dead ball over/under of number game
						- add more bettype for nubmer game Warrior,  Next combo and Number Group
	- 20111019@Tom:Add check P2P Game: Status, game setting, commission.
	- 20120322@Johnson: - separate checking and moving account
						- move setting Live casino
	- 20120821@Dan: add virtual soccer, remove FI
	- 20121002@Johnson: Check double comm losing status
	- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
	- 20130307@Elodie: Add Virtual HR
	- 20131022@Elodie: Remove checking setting for Financial and Poker products [Redmine:#6480]
	- 20131108@Elodie: Splitting bodb02 into CustDB (Roll back updates on custinfo,customer table in main SP)  			
	- 20131126@Kathy: Add Virtual Greyhounds/Motor Racing (182, 184) [Redmine:#7234]	
	- 20131203@Johnson:- Correct comm setting for downlines after moving customers
					- Apply execrep Acc_CustSetting_04/Acc_CustSetting3rd_04 instead of calling SPs Acc_CustomerUpdAgent_MinMaxPositiontaking/Acc_CustomerUpdAgentHR_MinMaxPositiontaking/..
	- 20140314@Elodie: Add Keno product [Redmine:#13326]
	- 20140403@Kathy: Add Virtual Speedway (183), Virtual Virtual Cycling (185)	[Redmine:#14142]
	- 20140611@Elodie: Implement separate setting pages for Keno [Redmine:#13156]
	- 20150511@Kathy: Add Gold Deluxe product [Redmine:#34486]
	- 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerCheckMoveAgent, Acc_CustomerSelCheckAllowedDownlines to DBCUST.CustDB) [Redmine:#36216]
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20150904@Helen: commission setting for MO [Redmine #41470]	
	- 20151030@Dominic: Add MuayThai product [Redmine: #46732]
	- 20160205@Billy:	Apply for AllBet product - [Redmine: #51590]
	- 20160218@Dominic: Not allow to move a IMBC customer to MBC line and vice versa [Redmine: #50221]
	- 20160426@Winnie: fix  Bug #56653 [Move account: IsHidden of move master is changed to 0]
	- 20160819@Winnie: fix  Bug #62755 [NAP - IsDailyAutoReset of downline is changed to 0 after moving downline although both downline and upline has IsDailyAutoReset=1]

Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    Max errorcode: 142
• @ErrMsg: Error description.
*/

BEGIN
SET NOCOUNT ON;

declare @startRun datetime;
declare @endRun datetime;
declare @duration int;
set @startRun = getdate();

--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output;
If @ErrCode <> 0
	RETURN;
--end
	
declare	@srecommend			int, 
			@mrecommend			int, 
			@recommend			int,
			@srecommend_old		int, 
			@mrecommend_old		int,
			@mDisableOutright	BIT,
			@aDisableOutright	BIT,
			@mDisableCasino		BIT,
			@aDisableCasino		BIT,
			@mDisableLiveCasino BIT,
			@aDisableLiveCasino BIT,
			@mDoubleCommLosing	BIT,
			@aDoubleCommLosing	BIT,			
			@aSuspended			BIT,	
			@mSuspended			BIT,
			--@aMaxTransferP2P	MONEY,
			--@mMaxTransferP2P	MONEY,
			--@aIsAutoResetP2P	BIT,
			--@mIsAutoResetP2P	BIT,
			--@aDisableP2P		BIT, 
			--@mDisableP2P		BIT, 
			--@aDisableFunP2P		BIT,
			--@mDisableFunP2P		BIT,
			@aDisableVirtualSports		BIT,
			@mDisableVirtualSports		BIT,	
			@aHideKeno				BIT,		
			@mHideKeno				BIT,
			@mHideGoldDeluxe	BIT,
			@aHideGoldDeluxe	BIT,
			@mDisableGoldDeluxe	BIT,
			@aDisableGoldDeluxe	BIT,
			@mHideColossusBet	BIT,
			@aHideColossusBet	BIT,
			@mDisableColossusBet	BIT,
			@aDisableColossusBet	BIT;  
 

	select	@srecommend			= srecommend, 
			@mrecommend			= custid, 
			@mDisableOutright	= DisableOutright,			
			@mDisableCasino		= disableCasino,
			@mDisableLiveCasino = DisableLivecasino, 
			@mDoubleCommLosing	= DoubleCommLosing,			
			@mSuspended			= reject,
			--@mMaxTransferP2P	= MaxTransferP2P, 
			--@mIsAutoResetP2P	= IsAutoResetP2P, 
			--@mDisableP2P		= DisableP2P, 
			--@mDisableFunP2P		= DisableFunP2P,
			@mDisableVirtualSports	= DisableVirtualSports,
			@mHideKeno				= HideKeno,
			@mHideGoldDeluxe	= HideGoldDeluxe,
			@mDisableGoldDeluxe = DisableGoldDeluxe,
			@mHideColossusBet	= HideColossusBet,
			@mDisableColossusBet = DisableColossusBet
	from	custinfo with (nolock) 
	where	username = @mastername and roleid = 3;

	select	@recommend			= custid, 
			@srecommend_old		= srecommend, 
			@mrecommend_old		= mrecommend, 			
			@aDisableOutright	= DisableOutright,			
			@aDisableCasino		= disableCasino,
			@aDisableLiveCasino = DisableLiveCasino,	
			@aDoubleCommLosing	= DoubleCommLosing,		
			@aSuspended			= reject,
			--@aMaxTransferP2P	= MaxTransferP2P, 
			--@aIsAutoResetP2P	= IsAutoResetP2P, 
			--@aDisableP2P		= DisableP2P, 
			--@aDisableFunP2P		= DisableFunP2P,
			@aDisableVirtualSports	= DisableVirtualSports,
			@aHideKeno				= HideKeno ,
			@aHideGoldDeluxe	= HideGoldDeluxe,
			@aDisableGoldDeluxe = DisableGoldDeluxe,
			@aHideColossusBet	= HideColossusBet,
			@aDisableColossusBet = DisableColossusBet  		
	from	custinfo with (NOLOCK) 
	where	username = @agentname and roleid = 2;

	-- 20160218@Dominic: Not allow to move a IMBC customer to MBC line and vice versa
	DECLARE @_SiteMaster VARCHAR(10),@_SiteAgent VARCHAR(10)
	
	SELECT @_SiteMaster = site
	FROM dbo.Customer WITH(NOLOCK)
	WHERE CustID = @mrecommend
	
	SELECT @_SiteAgent = site
	FROM dbo.Customer WITH(NOLOCK)
	WHERE CustID = @recommend
	
	IF (@_SiteMaster = 'IMBC' OR @_SiteAgent = 'IMBC') AND @_SiteMaster <> @_SiteAgent
	BEGIN
		SELECT @ErrMsg = 'Not allow to move customer between MBC and IMBC sites!',@ErrCode = 911								
		RETURN	
	END
		
--Check Allowed downlines 
 EXEC dbo.Acc_CustomerSelCheckAllowedDownlines 
	@custid=@recommend,
    @roleid=2,
    @isExecRep=0,
    @isUpdatePT = 1,
    @Sporttype = 1,
    @Language='E',
    @ErrMsg=@ErrMsg output,
    @ErrCode=@ErrCode output;
 IF @ErrCode <> 0 
  RETURN;
  	
EXEC dbo.Acc_CustomerCheckMoveAgent @mastername = @mastername, @agentname = @agentname,@userid = @userid, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;

IF @ErrCode > 0
	RETURN;
	
--Declare @temp table to contain customer info before update.
CREATE TABLE #CustInfo (custid INT);
INSERT INTO #CustInfo
SELECT custid 
from customer with (NOLOCK) where recommend = @recommend;


----P2PGAMESETTING table
--UPDATE G_P
--SET stakelevel1 = CASE WHEN M.stakelevel1 = 1 AND G_P.stakelevel1 = 1 THEN 1 ELSE 0 END,
--	stakelevel2 = CASE WHEN M.stakelevel2 = 1 AND G_P.stakelevel2 = 1 THEN 1 ELSE 0 END,
--	stakelevel3 = CASE WHEN M.stakelevel3 = 1 AND G_P.stakelevel3 = 1 THEN 1 ELSE 0 END,
--	stakelevel4 = CASE WHEN M.stakelevel4 = 1 AND G_P.stakelevel4 = 1 THEN 1 ELSE 0 END,
--	stakelevel5 = CASE WHEN M.stakelevel5 = 1 AND G_P.stakelevel5 = 1 THEN 1 ELSE 0 END
--FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
--	INNER JOIN 
--		( SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE custid = @mrecommend) m
--			ON G_P.BETTYPE = M.BETTYPE
--WHERE G_P.custid IN (SELECT custid FROM @CustInfo)

--IF @@ERROR <> 0 
--	BEGIN	
--		SELECT	@ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': update unsuccessfully (P2PGameSetting).',
--				@ErrCode = 300
--		RETURN
--	END

--IF exists (
--	SELECT TOP 1 1 FROM 
--	(SELECT * FROM dbo.P2PGameSetting a WITH(NOLOCK) WHERE a.custid = @recommend)  a
--	INNER JOIN
--		(SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE m.custid = @mrecommend)   m
--				ON a.BETTYPE = m.BETTYPE
--	WHERE (a.stakelevel2 = 0 AND a.stakelevel3 = 0 AND a.stakelevel4 = 0 AND a.stakelevel5 = 0 )
--	AND (m.stakelevel2 = 1 OR m.stakelevel3 = 1 OR m.stakelevel4 = 1 OR m.stakelevel5 = 1 )
--)
--BEGIN
--	UPDATE G_P
--	SET stakelevel1 = CASE WHEN M.stakelevel1 = 1 THEN 1 ELSE 0 END,
--		stakelevel2 = CASE WHEN M.stakelevel2 = 1 THEN 1 ELSE 0 END,
--		stakelevel3 = CASE WHEN M.stakelevel2 = 0 AND M.stakelevel3 = 1 THEN 1 ELSE 0 END,
--		stakelevel4 = CASE WHEN M.stakelevel2 = 0 AND M.stakelevel3 = 0 AND M.stakelevel4 = 1 THEN 1 ELSE 0 END,
--		stakelevel5 = CASE WHEN M.stakelevel2 = 0 AND M.stakelevel3 = 0 AND M.stakelevel4 = 0 AND M.stakelevel5 = 1 THEN 1 ELSE 0 END
--	FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
--		INNER JOIN 
--			( SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE custid = @mrecommend) m
--				ON G_P.BETTYPE = M.BETTYPE
--	WHERE G_P.custid = @recommend AND G_P.stakelevel2 = 0 AND G_P.stakelevel3 = 0 AND G_P.stakelevel4 = 0 AND G_P.stakelevel5 = 0
	
--	IF @@ERROR <> 0 
--	BEGIN		
--			SELECT	@ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': update unsuccessfully (P2PGameSetting).',
--					@ErrCode = 301
--		RETURN
--	END	
--END

----P2PGroupComm table
--UPDATE G_C 
--SET sdiscount = M.sdiscount,
--	adiscount  =M.adiscount
--FROM P2PGroupComm G_C WITH (ROWLOCK, UPDLOCK)
--	INNER JOIN 
--		( SELECT * FROM dbo.P2PGROUPCOMM m WITH(NOLOCK) WHERE custid = @mrecommend) m
--		ON G_C.GroupID = M.GroupID
--WHERE G_C.custid IN (SELECT custid FROM @CustInfo)

--IF @@ERROR <> 0 
--BEGIN	
--	SELECT	@ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': update unsuccessfully (P2PGroupComm).',
--			@ErrCode = 302
--	RETURN
--END

--if (@mDisableP2P = 1 and @aDisableP2P = 0) 
--	OR (@mIsAutoResetP2P = 0 and @aIsAutoResetP2P = 1)
--	OR (@mDisableFunP2P = 1 and @aDisableFunP2P = 0)
--	OR (@mMaxTransferP2P < @aMaxTransferP2P)
--	OR (@mDoubleCommLosing = 0 and @aDoubleCommLosing = 1)
--BEGIN
--	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
--	SET		DisableP2P = CASE WHEN @mDisableP2P = 1 THEN 1 ELSE DisableP2P END,
--			DisableFunP2P = CASE WHEN @mDisableFunP2P = 1 THEN 1 ELSE DisableFunP2P END,
--			IsAutoResetP2P = CASE WHEN @mIsAutoResetP2P = 0 THEN 0 ELSE IsAutoResetP2P END,
--			MaxTransferP2P = CASE WHEN @mMaxTransferP2P < MaxTransferP2P THEN @mMaxTransferP2P ELSE MaxTransferP2P END,
--			DoubleCommLosing = CASE WHEN @mDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
--	WHERE	custid IN(SELECT CustID FROM @CustInfo)
--	IF @@ERROR <>0
--	BEGIN
--		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 303
--		RETURN 
--	END
--END

if (@mDoubleCommLosing = 0 and @aDoubleCommLosing = 1)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DoubleCommLosing = CASE WHEN @mDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 303;
		RETURN; 
	END;
END;

--customer table
update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend, mrecommend = @mrecommend 
where custid IN(SELECT CustID FROM #CustInfo);
if @@Error <> 0 
BEGIN
    --ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
	where custid IN(SELECT CustID FROM #CustInfo);
	
	Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (customer).',
		@ErrCode = 304;					 
	return;
END;

--custinfo table
update custinfo with (ROWLOCK, UPDLOCK) 
set srecommend = @srecommend, 
	mrecommend = @mrecommend 
where  custid IN(SELECT CustID FROM #CustInfo);
if @@Error <> 0 
BEGIN
    --ROLLBACK TRANSACTION MANUALLY
	update customer with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
	where  custid IN(SELECT CustID FROM #CustInfo);
	
	update custinfo with (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
	where  custid IN(SELECT CustID FROM #CustInfo);
	
	Select @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		@ErrCode = 305;				 	
	return;
END;

--- update suspended status
IF @mSuspended = 1 AND @aSuspended = 0
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	reject = 1 
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		SELECT	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 306;
		RETURN;
	END;
END;

IF @mDisableOutright = 1 AND (@mDisableOutright <> @aDisableOutright ) 
BEGIN
	UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
	SET	DisableOutright = 1 
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 307;
		RETURN; 
	END;
END; 

IF @mDisableCasino = 1 AND (@mDisableCasino <> @aDisableCasino)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableCasino = 1 
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 308;
		RETURN; 
	END;
END;

IF @mDisableLiveCasino = 1 AND @mDisableLiveCasino <> @aDisableLiveCasino
BEGIN
	UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
	SET DisableLiveCasino = 1
	WHERE custid IN (SELECT custid FROM #CustInfo);
	
	IF @@ERROR <> 0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 309;
		RETURN; 
	END;
END;

-- VS
IF @mDisableVirtualSports = 1 AND (@mDisableVirtualSports <> @aDisableVirtualSports)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableVirtualSports = 1 
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 310;
		RETURN; 
	END;
END;

--DECLARE @xmlStrDisabled XML;
--DECLARE @xmlStrHidden XML;

--SET @xmlStrDisabled =(
--			SELECT (
--					SELECT stt.bitmapOrder	AS '@b'
--						, 1	AS '@s'
--					FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
--						INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
--						INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
--					WHERE dbo.f_GetProductStatus(m.bitmapIsDisabled, stt.bitmapOrder) = 1
--							AND dbo.f_GetProductStatus(a.bitmapIsDisabled, stt.bitmapOrder) = 0
	
--					FOR XML PATH('r')
--						, TYPE
--					)
--			FOR XML PATH('root')
--				, TYPE
--			);

--IF CONVERT(VARCHAR(MAX),@xmlStrDisabled) <> '<root/>'
--BEGIN
--	UPDATE CustProductStatus
--		SET bitmapIsDisabled = (SELECT bitmap FROM dbo.f_GenerateProductStatus_multiple (bitmapIsDisabled, CONVERT(VARCHAR(MAX),@xmlStrDisabled)))	
--	WHERE	custid IN(SELECT CustID FROM #CustInfo);
--	IF @@ERROR <>0
--	BEGIN
--		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 9111;
--		RETURN; 
--	END;
--END;

--SET @xmlStrHidden =(
--			SELECT (
--					SELECT stt.bitmapOrder	AS '@b'
--						, 0	AS '@s'
--					FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
--						INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
--						INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
--					WHERE dbo.f_GetProductStatus(m.bitmapIsHidden, stt.bitmapOrder) = 0
--							AND dbo.f_GetProductStatus(a.bitmapIsHidden, stt.bitmapOrder) = 1
	
--					FOR XML PATH('r')
--						, TYPE
--					)
--			FOR XML PATH('root')
--				, TYPE
--			);

--IF CONVERT(VARCHAR(MAX),@xmlStrHidden) <> '<root/>'
--BEGIN
--	UPDATE CustProductStatus
--		SET bitmapIsHidden = (SELECT bitmap FROM dbo.f_GenerateProductStatus_multiple (bitmapIsHidden, CONVERT(VARCHAR(MAX),@xmlStrHidden)))	
--	WHERE	custid IN(SELECT CustID FROM #CustInfo);
--	IF @@ERROR <>0
--	BEGIN
--		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
--				@ErrCode = 9112;
--		RETURN; 
--	END;
--END;

-- Keno
IF @mHideKeno = 0 AND (@mHideKeno <> @aHideKeno)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		HideKeno = 0
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 311;
		RETURN; 
	END;
END;

-- Gold Deluxe
IF @mDisableGoldDeluxe = 1 AND (@mDisableGoldDeluxe <> @aDisableGoldDeluxe)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableGoldDeluxe = 1 
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 313;
		RETURN; 
	END;
END;

-- Colossus Bet
IF @mDisableColossusBet = 1 AND (@mDisableColossusBet <> @aDisableColossusBet)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableColossusBet = 1 
	WHERE	custid IN(SELECT CustID FROM #CustInfo);
	IF @@ERROR <>0
	BEGIN
		SELECT	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 314;
		RETURN; 
	END;
END;


UPDATE	acg WITH (UPDLOCK,ROWLOCK)
SET		acg.IsDisabled = 1 
FROM CustGameType mcg WITH (NOLOCK) 
	INNER JOIN CustGameType acg ON mcg.CustID = @mrecommend AND acg.GameTypeID = mcg.GameTypeID
WHERE	acg.custid IN(SELECT CustID FROM #CustInfo) AND mcg.IsDisabled = 1 AND acg.IsDisabled = 0;
IF @@ERROR <>0
BEGIN
	Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
			@ErrCode = 312;
	RETURN;
END;

/*
IF @mDisableBingo = 1 AND (@mDisableBingo <> @aDisableBingo)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableBingo = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 138
	RETURN 
END
IF @mDisableNumber = 1 AND (@mDisableNumber <> @aDisableNumber)
BEGIN
	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	SET		DisableNumber = 1 
	WHERE	custid IN(SELECT CustID FROM @CustInfo)
	IF @@ERROR <>0
		Select	@ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				@ErrCode = 139
	RETURN 
END
*/

--Apply ExeReplication
-- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
--Apply ExeReplication
-- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
EXEC DBTXN.bodb02.dbo.Acc_ExecRep_00 
    @custid = 0,
    @recommend = @recommend,
    @recommend_old = 0,
    @mrecommend = @mrecommend,
    @mrecommend_old = @mrecommend_old,
    @srecommend = @srecommend,
    @srecommend_old = @srecommend_old,
    @roleid = 2,
    @ErrCode = @ErrCode OUTPUT,
    @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
BEGIN			
	-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  				
	--ROLLBACK TRANSACTION MANUALLY
    UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
    WHERE  custid IN(SELECT CustID FROM #CustInfo);
    
    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
    WHERE  custid IN(SELECT CustID FROM #CustInfo);                      
    RETURN;
END;	

EXEC DBTXN.bodb02.dbo.Acc_ExecRep_00 
    @custid = 0,
    @recommend = @recommend,
    @recommend_old = 0,
    @mrecommend = @mrecommend,
    @mrecommend_old = @mrecommend_old,
    @srecommend = @srecommend,
    @srecommend_old = @srecommend_old,
    @roleid = 2,
    @ErrCode = @ErrCode OUTPUT,
    @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
BEGIN			
	-- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)  				
	--ROLLBACK TRANSACTION MANUALLY
    UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old
    WHERE  custid IN(SELECT CustID FROM #CustInfo);
    
    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) set srecommend = @srecommend_old, mrecommend = @mrecommend_old
    WHERE  custid IN(SELECT CustID FROM #CustInfo);                      
    RETURN;
END;	



--when separate code we must use EXEC Acc_CustomerUpdAgent_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
--Check & update n4<=s1+m1+a1<=l4
--Apply execrep for these sps
/*
EXEC dbo.Acc_CustomerUpdAgent_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentHR_MinMaxPositiontaking @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentLiveCS_MaxPositiontaking @recommend = @recommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=180, @bettype = 1201, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=181, @bettype = 1231, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=182, @bettype = 1231, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=184, @bettype = 1231, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
EXEC dbo.Acc_CustomerUpdAgentVS_MinMaxPositiontaking  @sporttype=186, @bettype = 1220, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend
*/
EXEC Acc_CustSetting_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'number', @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'horse', @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=180, @bettype = 1201, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=181, @bettype = 1231, @roleid = 2;
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=182, @bettype = 1231, @roleid = 2;
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=183, @bettype = 1231, @roleid = 2;
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=184, @bettype = 1231, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=185, @bettype = 1231, @roleid = 2;
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @recommend = @recommend, @mode = 'virtual-sports', @sporttype=186, @bettype = 1220, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend,	@mode = 'LiveCasino', @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1501, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1511, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1503, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1504, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1505, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1513, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1507, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1508, @roleid = 2;	
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1509, @roleid = 2;
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'Keno', @sporttype=202, @bettype = 1514, @roleid = 2;
EXEC Acc_CustSetting3rd_04 @srecommend = @srecommend, @mrecommend = @mrecommend, @custid = @recommend, @mode = 'GoldDeluxe', @sporttype=255, @bettype = 1701, @roleid = 2;		

--Correct PT for DCS products
DECLARE @xml XML;
SET @xml = (
			SELECT (
					SELECT SportType AS '@SportType'
						, BetType AS '@BetType'
						, IsLive AS '@IsLive'
					FROM dbo.ProductSettingDetail WITH(NOLOCK)
					WHERE settingtype = 1
					FOR XML PATH('PT')
						, TYPE
					)
			FOR XML PATH('ROOT')
				, TYPE
			);
DECLARE @SportBettypeXML NVARCHAR(MAX) = CONVERT(NVARCHAR(MAX),@xml);
EXEC dbo.Acc_DynamicCustSetting3rd_04 
			@AgentID = @recommend
			,@MasterID = @mrecommend
			,@SuperID = @srecommend
			,@RoleID = 2
			,@SportBettypeXML = @SportBettypeXML;

IF EXISTS (SELECT 1 FROM #CustInfo)
BEGIN
	update cs
	set cs.sdiscount= mcs.sdiscount 
	FROM custsetting cs with (ROWLOCK, UPDLOCK) 
		INNER JOIN custsetting mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	where EXISTS (SELECT 1 FROM #CustInfo t WHERE t.custid = cs.custid )
	and isnull(cs.sdiscount, 0) < mcs.sdiscount;

	update cs
	set cs.adiscount = mcs.adiscount 
	FROM custsetting cs with (ROWLOCK, UPDLOCK) 
		INNER JOIN custsetting mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	where EXISTS (SELECT 1 FROM #CustInfo t WHERE t.custid = cs.custid )
	and isnull(cs.adiscount, 0) < mcs.adiscount;

	--Correct commission for DCS products
	UPDATE cs
	SET cs.SuperDiscount = scs.Discount
	FROM dbo.CustDiscount3rd_Member cs 
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.CustDiscount3rd_Agent scs WITH(NOLOCK) 
			ON scs.custid = @srecommend 
				AND scs.sporttype = cs.sporttype
				AND scs.bettype = cs.bettype
	WHERE ci.recommend = @recommend AND ci.RoleID = 1
		AND ISNULL(cs.SuperDiscount, 0) < scs.Discount;

		
	UPDATE cs
	SET cs.MasterDiscount = mcs.Discount
	FROM dbo.CustDiscount3rd_Member cs 
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.CustDiscount3rd_Agent mcs WITH(NOLOCK) 
			ON mcs.custid = @mrecommend 
				AND mcs.sporttype = cs.sporttype
				AND mcs.bettype = cs.bettype
	WHERE ci.recommend = @recommend AND ci.RoleID = 1
		AND ISNULL(cs.MasterDiscount, 0) < mcs.Discount;


	--correct commission for 3rd party
	update cs
	set cs.sdiscount= mcs.sdiscount 
	FROM custsetting3rd cs with (ROWLOCK, UPDLOCK) 
		INNER JOIN custsetting3rd mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	where EXISTS (SELECT 1 FROM #CustInfo t WHERE t.custid = cs.custid )
	and isnull(cs.sdiscount, 0) < mcs.sdiscount;

	update cs
	set cs.adiscount = mcs.adiscount 
	FROM custsetting3rd cs with (ROWLOCK, UPDLOCK) 
		INNER JOIN custsetting3rd mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	where EXISTS (SELECT 1 FROM #CustInfo t WHERE t.custid = cs.custid )
	and isnull(cs.adiscount, 0) < mcs.adiscount;

	--correct commission for live casino
	update cs
	set cs.sdiscount= mcs.sdiscount 
	FROM custsettingGame cs with (ROWLOCK, UPDLOCK) 
		INNER JOIN custsettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	where EXISTS (SELECT 1 FROM #CustInfo t WHERE t.custid = cs.custid )
	and isnull(cs.sdiscount, 0) < mcs.sdiscount;

	update cs
	set cs.adiscount = mcs.adiscount 
	FROM custsettingGame cs with (ROWLOCK, UPDLOCK) 
		INNER JOIN custsettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype
	where EXISTS (SELECT 1 FROM #CustInfo t WHERE t.custid = cs.custid )
	and isnull(cs.adiscount, 0) < mcs.adiscount;

	-- For CB
	DECLARE @adiscountColossusBet_18001 DECIMAL (9,8) = 0;
	DECLARE @adiscountColossusBet_18002 DECIMAL (9,8) = 0;
	
	DECLARE @sdiscountColossusBet_18001 DECIMAL (9,8) = 0;
	DECLARE @sdiscountColossusBet_18002 DECIMAL (9,8) = 0;
	
	
	SET @adiscountColossusBet_18001 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 204 AND Bettype = 18001);
	SET @adiscountColossusBet_18002 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 204 AND Bettype = 18002);
	
	SET @sdiscountColossusBet_18001 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 204 AND Bettype = 18001);
	SET @sdiscountColossusBet_18002 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 204 AND Bettype = 18002);
	
	UPDATE C
		SET adiscount = @adiscountColossusBet_18001,
			sdiscount = @sdiscountColossusBet_18001
	FROM CustCommRate C WITH(ROWLOCK, UPDLOCK)
		JOIN custInfo CI WITH (NOLOCK) ON C.CustId = CI.custid			 
	WHERE CI.mrecommend =@mrecommend AND CI.roleid = 1
		 AND C.Sporttype = 204 AND C.Bettype = 18001;

	UPDATE C
		SET adiscount = @adiscountColossusBet_18002,
			sdiscount = @sdiscountColossusBet_18002
	FROM CustCommRate C WITH(ROWLOCK, UPDLOCK)
		JOIN custInfo CI WITH (NOLOCK) ON C.CustId = CI.custid			 
	WHERE CI.mrecommend =@mrecommend AND CI.roleid = 1
		 AND C.Sporttype = 204 AND C.Bettype = 18002;		 
	
	-- For Myanmar Odds
	DECLARE @IsMyanmarOdds BIT = 0;
	DECLARE @adiscountMyanmarOdds DECIMAL (9,8) = 0;
	DECLARE @sdiscountMyanmarOdds DECIMAL (9,8) = 0;
	
	SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@mrecommend);

	IF @IsMyanmarOdds = 1
	BEGIN
		SET @adiscountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 1 AND Bettype = 301);
		SET @sdiscountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 1 AND Bettype = 301);
		
		UPDATE C
			SET adiscount = @adiscountMyanmarOdds,
				sdiscount = @sdiscountMyanmarOdds
		FROM CustCommRate C WITH(ROWLOCK, UPDLOCK)
			JOIN custInfo CI WITH (NOLOCK) ON C.CustId = CI.custid			 
		WHERE CI.mrecommend =@mrecommend AND CI.roleid = 1
			 AND C.Sporttype = 1 AND C.Bettype = 301;
	END;
	
	-- Update Stake Level for moved agent 
	DECLARE	@removedStakeLevel	TABLE (
									SportType		SMALLINT
								,	BetType			INT
								,	StakeLevelList	VARCHAR(100)
								);

	DECLARE	@StakeLevelExecRep	VARCHAR(MAX)	
		,	@StartRow			INT				= 1
		,	@MaxRow				INT				
		,	@Threshold			INT				= 20000
		,	@StopRow			INT;				

	CREATE TABLE	#UpdateStakeLevelList (
						CustID					INT
					,	UplineCustID			INT
					,	RoleID					TINYINT
					,	BetType					INT
					,	StakeLevelList			VARCHAR(200)
					,	StakeLevelList_new		VARCHAR(200)
					,	StakeLevelList_upline	VARCHAR(200)
					);
	
	INSERT INTO	@removedStakeLevel
		(	SportType        , BetType        , StakeLevelList)
	SELECT	cslaNew.SportType, cslaNew.BetType, fsls.String
	FROM		dbo.CustStakeLevel_Agent AS cslaOld WITH (NOLOCK)
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaNew WITH (NOLOCK)
			ON	cslaNew.SportType = cslaOld.SportType
			AND	cslaNew.BetType = cslaOld.BetType
	CROSS APPLY	dbo.f_StakeLevelcorrectString(cslaOld.StakeLevelList, cslaNew.StakeLevelList) AS fsls
	WHERE	cslaOld.CustID = @mrecommend_old
		AND	cslaNew.CustID = @mrecommend;
	
	INSERT INTO	#UpdateStakeLevelList
		(	CustID    , UplineCustID , RoleID   , BetType      , StakeLevelList      , StakeLevelList_new, StakeLevelList_upline)
	SELECT	tci.custid, ci.mrecommend, ci.roleid, cslaA.BetType, cslaA.StakeLevelList, fsls.String       , cslaM.StakeLevelList
	FROM		#CustInfo AS tci
	INNER JOIN	dbo.custInfo AS ci WITH (NOLOCK)
			ON	ci.custid = tci.custid
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaA WITH (NOLOCK)
			ON	tci.CustID = cslaA.custid
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaM WITH (NOLOCK)
			ON	cslaM.SportType = cslaA.SportType
			AND	cslaM.BetType = cslaA.BetType
			AND	cslaM.CustID = ci.mrecommend
	INNER JOIN	@removedStakeLevel AS rsl
			ON	rsl.SportType = cslaA.SportType
			AND	rsl.BetType = cslaA.BetType
	CROSS APPLY	dbo.f_StakeLevelcorrectString(cslaA.StakeLevelList, rsl.StakeLevelList) AS fsls
	WHERE	ci.roleid = 2;

	INSERT INTO	#UpdateStakeLevelList
		(	CustID    , UplineCustID, RoleID   , BetType     , StakeLevelList     , StakeLevelList_new, StakeLevelList_upline)
	SELECT	tci.custid, ci.recommend, ci.roleid, cslm.BetType, cslm.StakeLevelList, fsls.String       , CASE WHEN usll.StakeLevelList_new = '' THEN usll.StakeLevelList_upline ELSE usll.StakeLevelList_new END
	FROM		#CustInfo AS tci
	INNER JOIN	dbo.custInfo AS ci WITH (NOLOCK)
			ON	ci.custid = tci.custid
	INNER JOIN	dbo.CustStakeLevel_Member AS cslm WITH (NOLOCK)
			ON	cslm.CustID = ci.custid
	INNER JOIN	#UpdateStakeLevelList AS usll WITH (NOLOCK)
			ON	usll.CustID = ci.recommend
			AND	usll.BetType = cslm.BetType
	INNER JOIN	@removedStakeLevel AS rsl
			ON	rsl.SportType = cslm.SportType
			AND	rsl.BetType = cslm.BetType
	CROSS APPLY	dbo.f_StakeLevelcorrectString(cslm.StakeLevelList, rsl.StakeLevelList) AS fsls
	WHERE	ci.roleid = 1;

	UPDATE	usll WITH (ROWLOCK, UPDLOCK)
	SET	usll.StakeLevelList_new = sr.LowestStakeLevel
	FROM	#UpdateStakeLevelList AS usll
	CROSS APPLY (
		SELECT TOP(1) ISNULL(CONVERT(VARCHAR(200), sl.StakeLevelID), '') AS LowestStakeLevel
		FROM (
			SELECT	CAST(val AS INT) AS val
			FROM	dbo.strSplit(usll.StakeLevelList_Upline, ',')
		) AS ss
		INNER JOIN	dbo.StakeLevel AS sl WITH(NOLOCK)
				ON	ss.val = sl.StakeLevelID
		WHERE	sl.MinStake <> 0
			AND	sl.MaxStake <> 0
		ORDER BY	sl.MaxStake, sl.MinStake
	) sr
	WHERE	usll.StakeLevelList_new = '';

	DELETE	#UpdateStakeLevelList
	WHERE	StakeLevelList_new = StakeLevelList;

	ALTER TABLE	#UpdateStakeLevelList
	ADD ID	INT IDENTITY(1,1);

	SELECT	@MaxRow = MAX(ID)
	FROM #UpdateStakeLevelList AS usll;

	IF	@Threshold > @MaxRow
		SELECT	@Threshold = @MaxRow;

	SELECT	@StopRow = @Threshold;

	IF	EXISTS (SELECT 1 FROM #UpdateStakeLevelList AS usll)
	BEGIN
	    WHILE (0 = 0)
		BEGIN
		    SELECT	@StakeLevelExecRep =	(
												SELECT	usll.CustID				AS CustID
													,	usll.BetType			AS BetType
													,	usll.StakeLevelList_new	AS StakeLevelList
												FROM	#UpdateStakeLevelList AS usll
												WHERE	ID >= @StartRow
													AND	ID <= @StopRow
												FOR XML RAW ('StakeLevel')
											,	ROOT ('ROOT')
											);
			
			-- Correct Stake Level using ExecRep
			EXECUTE	dbo.Acc_DynamicCustSetting3rd_02 
						@CustID			= @recommend
					,	@RoleID			= 2
					,	@StakeLevel		= @StakeLevelExecRep;
			
			IF	@StopRow = @MaxRow
				BREAK;

			SELECT	@StartRow = @StopRow + 1;
			SELECT	@StopRow = 1 + @StopRow + @Threshold;

			IF	@StopRow >= @MaxRow
				SELECT	@StopRow = @MaxRow;

		END;
	END;

	-- Update Daily Auto Reset Win Loss Limit for moved agent
	CREATE TABLE #WinLossLimit_tmp (SportType SMALLINT, BetType INT)
	
	INSERT INTO #WinLossLimit_tmp (SportType,BetType)
	SELECT SportType,BetType
	FROM dbo.CustWinLossLimit_Agent AS s WITH (NOLOCK) 
	WHERE s.Custid=@mrecommend AND IsAutoReset=0
	
	IF EXISTS (SELECT 1 FROM #WinLossLimit_tmp)
	BEGIN
		UPDATE	cwlla
			SET	cwlla.IsAutoReset = 0
		FROM		#CustInfo AS ci
			INNER JOIN	dbo.CustWinLossLimit_Agent AS cwlla WITH (ROWLOCK, UPDLOCK)
			ON	cwlla.CustId = ci.custid 
			INNER JOIN #WinLossLimit_tmp S
			ON cwlla.sporttype=s.sporttype AND cwlla.bettype=s.bettype
			WHERE cwlla.IsAutoReset = 1
			
		UPDATE	cwlla
			SET	cwlla.IsAutoReset = 0
		FROM		#CustInfo AS ci
			INNER JOIN	dbo.CustWinLossLimit_Member AS cwlla WITH (ROWLOCK, UPDLOCK)
			ON	cwlla.CustId = ci.custid 
			INNER JOIN #WinLossLimit_tmp S
			ON cwlla.sporttype=s.sporttype AND cwlla.bettype=s.bettype
			WHERE cwlla.IsAutoReset = 1
		END	
	DROP TABLE #WinLossLimit_tmp

	
END;


declare @LogSPData varchar(8000);

SELECT  @LogSPData = '<Acc_CustomerUpdMoveAgent AgentName="' + @agentname + 
					'" OldMasterId="' + CONVERT(VARCHAR(20), @mrecommend_old) + 
					'" NewMasterName="' + @mastername + 
					'" NewMasterId="' + CONVERT(VARCHAR(20), @mrecommend) + 
					'" Userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + 
					'" IP="' + @IP + '" />';

set @endRun = getdate();
set @duration  = datediff (millisecond,@startRun,@endRun);

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @recommend,
		@ActionID = 606, 
		@TrackingValue = @LogSPData,
		@duration = @duration;
END TRY
BEGIN CATCH
	SELECT  @LogSPData = '<Acc_CustomerUpdMoveAgent AgentName="' + @agentname + 
					'" OldMasterId="' + CONVERT(VARCHAR(20), @mrecommend_old) + 
					'" NewMasterName="' + @mastername + 
					'" NewMasterId="' + CONVERT(VARCHAR(20), @mrecommend) + 
					'" Userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + 
					'" IP="' + @IP + 
					'" ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + 
					'" ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />';
					
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @recommend,
		@ActionID = 606, 
		@TrackingValue = @LogSPData,
		@duration = @duration;	
END CATCH;		
	DROP TABLE #CustInfo;
END;





GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveAgent] TO [bodbAdminNet] AS [dbo];
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveAgent] TO [vnteam] AS [dbo];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveAgent] TO [vnteam] AS [dbo];