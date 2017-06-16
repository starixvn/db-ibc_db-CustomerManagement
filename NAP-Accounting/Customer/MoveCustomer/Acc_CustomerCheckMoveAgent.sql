ALTER PROCEDURE [dbo].[Acc_CustomerCheckMoveAgent]
	@mastername		VARCHAR(40)
	, @agentname	VARCHAR(40)
	, @userid		INT
	, @IP			VARCHAR(15) = ''
	, @ErrCode		INT = 0				OUTPUT
	, @ErrMsg		NVARCHAR(200) = ''	OUTPUT
AS
/*
	Created: 
	Task : Check moving a agent to another master
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).
		- 20120821@Dan: add virtual soccer, remove FI
		- 20130121@Dan: remove unneeded linked server call DB052
		- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
		- 20131022@Elodie: Remove checking setting for Financial and Poker products [Redmine:#6480]
		- 20131024@Elodie: Add HR Fixed Odds [Redmine:#6505]
		- 20140314@Elodie: Add Keno product [Redmine:#13326]
		- 20140828@Logan: Add constraint for E-Sports status [Redmine: #20531]
		- 20150508@Kathy: Add Gold Deluxe product [Redmine:#34486]
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20150707@Elodie: Add Super Live product [Redmine: #35776]
		- 20150825@Helen: Colossus Bet - [Redmine: #41264]	
		- 20150904@Helen: commission setting for MO [Redmine #41470]
		- 20151030@Dominic: Add MuayThai product [Redmine: #46732]
		- 20160201@Billy: Apply for AllBet product - [Redmine: #51590]
	Param's Explanation:
	- @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
		Max errorcode: 214
	- @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @srecommend				INT
	      , @mrecommend				INT
	      , @recommend				INT
	      , @srecommend_old			INT
	      , @mrecommend_old			INT
	      , @scurrency				TINYINT
	      , @mcurrency				TINYINT
	      , @acurrency				TINYINT
	      , @mdisable151_31			BIT
	      , @adisable151_31			BIT
	      , @DisableAutoMPT			BIT
	      , @DisableAutoMPT_old 	BIT
	      , @mIsInternal			BIT
	      , @aIsInternal			BIT
	      , @mDisableOutright		BIT
	      , @aDisableOutright		BIT
	      , @mSyncCasino			BIT
	      , @aSyncCasino			BIT
	      , @mSyncLiveCasino		BIT
	      , @mSyncLiveCasino_Old	BIT
	      , @aSyncLiveCasino		BIT
	      , @mSyncBingo				BIT
	      , @aSyncBingo				BIT
	      , @mDisableCasino			BIT
	      , @aDisableCasino			BIT
	      , @mDisableLiveCasino 	BIT
	      , @aDisableLiveCasino 	BIT
	      , @mDisableBingo			BIT
	      , @aDisableBingo			BIT
	      , @mDisableNumber			BIT
	      , @aDisableNumber			BIT
	      , @aDisable151_41			BIT
	      , @mDisable151_41			BIT
	      , @aDisable151_51			BIT
	      , @mDisable151_51			BIT
	      , @aDisable152_41			BIT
	      , @mDisable152_41			BIT
	      , @aDisable152_51			BIT
	      , @mDisable152_51			BIT
	      , @aDisable153_51			BIT
	      , @mDisable153_51			BIT
	      , @aClosed				BIT
	      ,	@mClosed				BIT
	      , @aSuspended				BIT
	      , @mSuspended				BIT
	      ,	@mDisableHRFixedOdds	BIT
	      , @aDisableHRFixedOdds	BIT
	      , @mDisableEsports	    BIT
	      , @aDisableEsports	    BIT
	      , @aGivenCredit			MONEY
	      , @mGivenCredit			MONEY
	      , @mUsedCredit			MONEY
	      , @aHideVirtualSports		BIT
	      , @mHideVirtualSports		BIT
	      , @aHideKeno				BIT
	      , @mHideKeno				BIT
	      ,	@mHideGoldDeluxe		BIT
	      , @aHideGoldDeluxe		BIT
		  ,	@mHideColossusBet		BIT
	      , @aHideColossusBet		BIT
		  , @mDisableSuperLive		BIT
	      , @aDisableSuperLive		BIT
	      , @AdminUser				VARCHAR(50)
	      , @DCSSportType			INT
	      , @DCSSportName			NVARCHAR(50)


	SELECT @srecommend		    = srecommend
	     , @mrecommend		    = custid
	     , @mcurrency		    = currency
	     , @scurrency		    = currency
	     , @mdisable151_31	    = DisableHorseracing
	     , @mDisableOutright    = DisableOutright
	     , @mSyncCasino		    = syncCasino
	     , @mSyncLiveCasino	    = SyncLiveCasino
	     , @mSyncBingo		    = SyncBingo
	     , @mDisableBingo	    = DisableBingo
	     , @mDisableNumber	    = DisableNumber
	     , @mDisableCasino	    = disableCasino
	     , @mDisableLiveCasino  = DisableLivecasino
	     , @mDisable151_41	    =  DisableOpenTote
	     , @mDisable151_51	    = Disable151_AU
	     , @mDisable152_41	    = Disable152_UK
	     , @mDisable152_51	    = Disable152_AU
	     , @mDisable153_51	    = Disable153_AU
	     , @mClosed			    = closed
	     , @mSuspended			= reject
	     , @mDisableHRFixedOdds = DisableHRFixedOdds
	     , @mGivenCredit		= credit
	     , @mHideVirtualSports  = HideVirtualSports
	     , @mHideKeno			= HideKeno
	     , @mDisableEsports     = DisableEsports
	     , @mHideGoldDeluxe		= HideGoldDeluxe
	     , @mHideColossusBet	= HideColossusBet
		 , @mDisableSuperLive	= DisableSuperLive
	  FROM custinfo WITH(NOLOCK)
	 WHERE username = @mastername
	   AND roleid = 3


	SELECT @recommend			= custid
	     , @srecommend_old		= srecommend
	     , @mrecommend_old		= mrecommend
	     , @acurrency			= currency
	     , @adisable151_31		= DisableHorseracing
	     , @aDisableOutright	= DisableOutright
	     , @aSyncCasino		    = syncCasino
	     , @aSyncLiveCasino	    = SyncLiveCasino
	     , @aSyncBingo			= SyncBingo
	     , @aDisableBingo		= DisableBingo
	     , @aDisableNumber		= DisableNumber
	     , @aDisableCasino		= disableCasino
	     , @aDisableLiveCasino  = DisableLiveCasino
	     , @aDisable151_41		= DisableOpenTote
	     , @aDisable151_51		= Disable151_AU
	     , @aDisable152_41		= Disable152_UK
	     , @aDisable152_51		= Disable152_AU
	     , @aDisable153_51		= Disable153_AU
	     , @aClosed			    = closed
	     , @aSuspended			= reject
	     , @aDisableHRFixedOdds = DisableHRFixedOdds
	     , @aGivenCredit		= credit
	     , @aHideVirtualSports  = HideVirtualSports
	     , @aHideKeno			= HideKeno
	     , @aDisableEsports     = DisableEsports
	     , @aHideGoldDeluxe		= HideGoldDeluxe
	     , @aHideColossusBet	= HideColossusBet
		 , @aDisableSuperLive	= DisableSuperLive
	  FROM custinfo WITH(NOLOCK)
	 WHERE username = @agentname
	   AND roleid = 2

	-- 20130920@Elodie: Add constraINT to avoid the insufficient Given Credit of any new super/master/agent being moving to.
	SELECT @mUsedCredit = sum(credit) FROM custinfo WITH(NOLOCK) WHERE roleid = 2 AND mrecommend = @mrecommend
	IF ISNULL(@mGivenCredit,0) - ISNULL(@mUsedCredit,0) < ISNULL(@aGivenCredit,0)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': New master credit is insufficient to move this agent.',
			@ErrCode = 100			 
		return
	END
		
	SELECT @mSyncLiveCasino_Old = SyncLiveCasino FROM CustInfo WITH(NOLOCK) WHERE custid = @mrecommend_old
	
	SELECT @DisableAutoMPT = DisableAutoMPT 
	from	custMaster with (nolock)
	WHERE custid = @mrecommend

	SELECT @DisableAutoMPT_old = DisableAutoMPT 
	from	custMaster with (nolock)
	WHERE custid = @mrecommend_old 

	IF isnull(@mrecommend, 0) = 0 or isnull(@srecommend, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master not found.',
			@ErrCode = 101					 
		return
	END

	IF isnull(@recommend, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent not found.',
			@ErrCode = 102					 
		return
	END

	IF isnull(@mrecommend_old, 0) = @mrecommend
	BEGIN
		SELECT @ErrMsg = 'The agent '+ @agentname +' already belongs to master '+ @mastername +'.',
			@ErrCode = 103					 
		return
	END

	--Check an account disabled or not 
	EXEC dbo.Acc_CustomerSelCheckEnable @username = @mastername, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	IF @ErrCode <>0		return 

	EXEC dbo.Acc_CustomerSelCheckEnable @username = @agentname, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output 
	IF @ErrCode <>0		return 

	IF @mcurrency <> @acurrency
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': currency of master and agent does not match.',
			@ErrCode = 104					 
		return
	END

	--Check Internal status
	SELECT @mIsInternal = IsInternal FROM CustMaster  WITH(NOLOCK)WHERE custid = @mrecommend
	SELECT @aIsInternal = IsInternal FROM CustAgent  WITH(NOLOCK)WHERE custid = @recommend
	IF ISNULL(@mIsInternal, 0) = 1 AND ISNULL(@aIsInternal, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) agent to new internal master.',
			@ErrCode = 105					 
		RETURN
	END
	
	--20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).

	SELECT @AdminUser = username FROM custinfo  WITH(NOLOCK)WHERE custid = @userid
	
	
	IF ((ISNULL(@mIsInternal, 0) = 1 AND ISNULL(@aIsInternal, 0) = 1 AND (@AdminUser NOT LIKE 'dba%') AND (@AdminUser NOT LIKE 'pgm%') AND (@AdminUser NOT IN ('vndbateam','vnQaTeam'))))
	BEGIN 
			SELECT @ErrMsg = N'This function is not allowed to perform the moving for financial accounts. Please contact IT@nexcel.vn for assistance. Thanks.', 
					@ErrCode = 119
			RETURN
	END

	-- check is closed
	IF @mClosed = 1
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move to closed master.',
			@ErrCode = 106					 
		RETURN
	END

	--Check Horse enable status:
	IF @mdisable151_31 = 1 and @adisable151_31 = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled SA Racing but new master not enabled SA Racing.',
			@ErrCode = 107					 
		return
	END


	--Check OpenTote enable status:
	IF @mDisable151_41 = 1 and @aDisable151_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled UK/Irish Racing but new master not enabled UK/IRish Racing.',
			@ErrCode = 108
		return
	END

	--Check Horse Racing for Aust Tote
	IF @mDisable151_51 = 1 and @aDisable151_51 = 0 
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled Aust Racing but new master not enabled Aust Racing .',
			@ErrCode = 109
		return
	END

	-- Check Greyhound for UK
	IF @mDisable152_41 = 1 and @aDisable152_41 = 0 
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled UK Greyhound but new master not enabled UK Greyhound.',
			@ErrCode = 110
		return
	END

	-- Check Greyhound for UK
	IF @mDisable152_51 = 1 and @aDisable152_51 = 0 
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled Aust Greyhound but new master not enabled Aust Greyhound.',
			@ErrCode = 111
		return
	END

	-- Check Harness for Aust
	IF @mDisable153_51 = 1 and @aDisable153_51 = 0 
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent enabled Aust Harness but new master not enabled Aust Harness.',
			@ErrCode = 112
		return
	END
	
	-- Check DCS Product's [disabled]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
		INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
	WHERE dbo.f_GetProductStatus(m.bitmapIsDisabled, stt.bitmapOrder) = 1
			AND dbo.f_GetProductStatus(a.bitmapIsDisabled, stt.bitmapOrder) = 0
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname 
					+ ': agent enabled '
					+ @DCSSportName
					+ ' but new master not enabled '
					+ @DCSSportName
					+ '.',
			@ErrCode = 9111
		return
	END

	-- Check DCS Product's [hidden]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
		INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
	WHERE dbo.f_GetProductStatus(m.bitmapIsHidden, stt.bitmapOrder) = 1
			AND dbo.f_GetProductStatus(a.bitmapIsHidden, stt.bitmapOrder) = 0
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg = 'Agent is offered '
					+ @DCSSportName
					+ ' but new master is not offered '
					+ @DCSSportName
					+ '.',
			@ErrCode = 9112
		return
	END
	
	-- Check DCS Product's [sync]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
		INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
	WHERE dbo.f_GetProductStatus(m.bitmapHasSynced, stt.bitmapOrder) = 0
			AND dbo.f_GetProductStatus(a.bitmapHasSynced, stt.bitmapOrder) = 1
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg	= 'Error Master ' + @mastername + ', agent ' + @agentname 
						+ ': Agent has setting of ' + @DCSSportName	+ ' but new master doesn''t have setting of ' + @DCSSportName + '.',
			@ErrCode = 9113
		return
	END
	--Check SyncCasino between Master and Agent 
	IF @mSyncCasino = 0 AND @aSyncCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Casino but new master is not synchronized Casino.',
			@ErrCode = 114					 
		RETURN
	END

	--Check Sync Live Casino
	IF @mSyncLiveCasino = 0 AND @aSyncLiveCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Casino but new master is not synchronized Casino.',
			@ErrCode = 115				 
		RETURN
	END

	/*
	--Check Casino enable status
	IF @mDisableCasino = 1 AND (@aDisableCasino = 0)
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Casino but new master is not enabled Casino.',
			@ErrCode = 115					
		RETURN
	END
	*/
	--Check SyncBingo between Master and Agent 
	IF @mSyncBingo = 0 AND @aSyncBingo = 1
	BEGIN
		SELECT @ErrMsg = 'Error Master ' + @mastername + ', agent ' + @agentname + ': agent is synchronized Bingo but new master is not synchronized Bingo.',
			@ErrCode = 116					
		RETURN
	END

	--Check Number Game + Bingo enable status
	IF @mdisableNumber = 1 and @adisableNumber = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Number Game but new master is not enabled Number Game.',
			@ErrCode = 117					 
		return
	END
	
	--Check Virtual sport enable status
	IF @mHideVirtualSports = 1 and @aHideVirtualSports = 0
	BEGIN
		SELECT @ErrMsg = 'Agent is offered Virtual Sports but new master is not offered Virtual Sports.',
			@ErrCode = 123					 
		return
	END		

	--Check Keno enable status
	IF @mHideKeno = 1 and @aHideKeno = 0
	BEGIN
		SELECT @ErrMsg = 'Agent is offered Keno but new master is not offered Keno.',
			@ErrCode = 125				 
		return
	END		

	
	IF @mdisableBingo = 1 and @adisableBingo = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Bingo but new master is not enabled Bingo',
			@ErrCode = 118
		return
	END

	IF @mdisableHRFixedOdds = 1 and @adisableHRFixedOdds = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Horse Racing Fixed Odds but new master is not enabled Horse Racing Fixed Odds',
			@ErrCode = 118
		return
	END

    --E-Sports
	IF @mDisableEsports = 1 and @aDisableEsports = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled E-Sports but new master is not enabled E-Sports.'
		     , @ErrCode = 126
		RETURN
	END
	
	--Super Live
	IF @mDisableSuperLive = 1 and @aDisableSuperLive = 0
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is enabled Super Live but new master is not enabled Super Live.'
		     , @ErrCode = 127
		RETURN
	END

	--Check Gold Deluxe enable status	
	IF @mHideGoldDeluxe = 1 and @aHideGoldDeluxe = 0
	BEGIN
		SELECT @ErrMsg = 'Agent is offered Gold Deluxe but new master is not offered Gold Deluxe.',
			@ErrCode = 128
		return
	END	
	
	--Check Colossus Bet enable status	
	IF @mHideColossusBet = 1 and @aHideColossusBet = 0
	BEGIN
		SELECT @ErrMsg = 'Agent is offered Colossus Bets but new master is not offered Colossus Bets.',
			@ErrCode = 129
		RETURN
	END	
	
	--Check identical auto master PT 
	IF (@DisableAutoMPT_old = 0 and @DisableAutoMPT = 1)
	begin
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Master Position Taking of new master is not allowed yet',
			@ErrCode = 119					 
		return
	end

	--Check Horse, Casino, Number Game sync status:
	IF exists(SELECT 1 from custsetting3rd  WITH(NOLOCK)where custid = @recommend and sporttype = 151)
		AND not exists(SELECT 1 from custsetting3rd  WITH(NOLOCK)where custid = @mrecommend and sporttype = 151)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Horse Racing setting.',
			@ErrCode = 120					 
		return
	END

	--Number Game
	IF exists(SELECT 1 from custsetting3rd  WITH(NOLOCK)where custid = @recommend and sporttype = 161)
		AND not exists(SELECT 1 from custsetting3rd  WITH(NOLOCK)where custid = @mrecommend and sporttype = 161)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Number Game setting.',
			@ErrCode = 122					 
		return
	END

	-- Virtual sports
	IF exists(SELECT 1 from custsetting3rd  WITH(NOLOCK)where custid = @recommend and sporttype = 180)
		AND not exists(SELECT 1 from custsetting3rd  WITH(NOLOCK)where custid = @mrecommend and sporttype = 180)		
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': master does not have Virtual Sports setting.',
			@ErrCode = 124					 
		return
	END

	--Check casino Syn
	--Remove checking Casino 
	--IF exists(SELECT 1 from custinfo  WITH(NOLOCK)where custid = @recommend and SyncCasino = 1)
	--BEGIN
	--	SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': agent is already Casino-synchronized.',
	--		@ErrCode = 112					 
	--	return
	--END

	--Check commission 
	IF exists (
			SELECT 1 
			from custsetting as mcs with (NOLOCK)
				inner join custsetting as acs  WITH(NOLOCK)on mcs.custid = @mrecommend and acs.custid = @recommend 
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype 
			where 
				(mcs.bettype in (1,2,3,7,8) and ((mcs.groupa<acs.groupa) or (mcs.groupb<acs.groupb) 
				or (mcs.groupc<acs.groupc) or (mcs.groupd<acs.groupd)))
				or (mcs.bettype not in (1,2,3,7,8) and mcs.adiscount<acs.discount)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission for Sportbook is less than agent''s commission.',
			@ErrCode = 200					 
		return
	END

	--Check commission for 3rd party
	IF exists (
			SELECT 1 
			from custsetting3rd as mcs with (NOLOCK)
				inner join custsetting3rd as acs  WITH(NOLOCK)on mcs.custid = @mrecommend and acs.custid = @recommend 
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype 
			where mcs.adiscount<acs.discount AND mcs.sporttype <> 201 
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission is less than agent''s commission.',
			@ErrCode = 201					 
		return
	END
	
	--Check commission for DCS products
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustDiscount3rd_Agent m WITH (NOLOCK)
			INNER JOIN dbo.CustDiscount3rd_Agent a WITH (NOLOCK)
				ON m.SportType = a.sporttype  
					AND m.BetType = a.bettype
					AND a.CustID = @recommend 
		WHERE m.CustID =  @mrecommend AND m.Discount < a.Discount)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission is less than agent''s commission.',
			@ErrCode = 9114					 
		return
	END

	--Check commission for live casino
	IF EXISTS (
			SELECT 1
			FROM CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = @recommend AND acs.sporttype = mcs.sporttype AND acs.bettype = mcs.bettype
			WHERE mcs.custid = @mrecommend AND mcs.sporttype = 162 AND mcs.bettype = 1101
				AND mcs.adiscount < acs.discount
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission for Live Casino is less than agent''s commission.',
			@ErrCode = 202
		RETURN
	END

	--Check commission for Keno
	IF EXISTS (
			SELECT 1
			FROM CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = @recommend AND acs.sporttype = mcs.sporttype AND acs.bettype = mcs.bettype
			WHERE mcs.custid = @mrecommend AND mcs.sporttype = 202 AND mcs.bettype between 1501 and 1599
				AND mcs.adiscount < acs.discount
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission for Keno is less than agent''s commission.',
			@ErrCode = 214
		RETURN
	END

	--Check commission for Gold Deluxe
	IF EXISTS (
			SELECT	1
			FROM	CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) 
					ON	acs.custid = @recommend 
						AND acs.sporttype = mcs.sporttype 
						AND acs.bettype = mcs.bettype
			WHERE	mcs.custid = @mrecommend 
					AND mcs.sporttype = 255 
					AND mcs.bettype = 1701
					AND mcs.adiscount < acs.discount
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission for Gold Deluxe is less than agent''s commission.',
			@ErrCode = 215
		RETURN
	END

	--Check commission for Colossus Bet
	IF EXISTS (
			SELECT	1
			FROM	AgentCommRate mcs WITH(NOLOCK) 
				JOIN AgentCommRate acs WITH(NOLOCK) ON	acs.custid = @recommend 
														AND acs.sporttype = mcs.sporttype 
														AND acs.bettype = mcs.bettype
			WHERE	mcs.custid = @mrecommend 
					AND mcs.sporttype = 204 
					AND mcs.bettype = 18001
					AND mcs.CommRate < acs.CommRate
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s commission for Colossus Bets is less than agent''s commission.',
			@ErrCode = 216
		RETURN
	END

	--Check Cash-In share for Colossus Bet
	IF EXISTS (
			SELECT	1
			FROM	AgentCommRate mcs WITH(NOLOCK) 
				JOIN AgentCommRate acs WITH(NOLOCK) ON	acs.custid = @recommend 
														AND acs.sporttype = mcs.sporttype 
														AND acs.bettype = mcs.bettype
			WHERE	mcs.custid = @mrecommend 
					AND mcs.sporttype = 204 
					AND mcs.bettype = 18002
					AND mcs.CommRate < acs.CommRate
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s cash-in share for Colossus Bets is less than agent''s cash-in share.',
			@ErrCode = 217
		RETURN
	END	
	
	--Check commission for Myanmar Odds
	DECLARE @IsMyanmarOdds_source BIT = 0
	DECLARE @IsMyanmarOdds_destination BIT = 0
	
	SET @IsMyanmarOdds_destination =  dbo.fn_IsMyanmarOdds (@mrecommend)

	SET @IsMyanmarOdds_source =  dbo.fn_IsMyanmarOdds (@mrecommend_old)

	IF @IsMyanmarOdds_source <> @IsMyanmarOdds_destination
	BEGIN
		SELECT @ErrMsg = 'Cannot move customer ' + @agentname + ' since amongs its new and old sites, one has % Odds.',
					@ErrCode = 218
		RETURN	
	END	
	
	IF @IsMyanmarOdds_source = 1
	BEGIN
		IF EXISTS(
			SELECT	1
			FROM	AgentCommRate mcs WITH(NOLOCK) 
				JOIN AgentCommRate acs WITH(NOLOCK) ON	acs.custid = @recommend 
														AND acs.sporttype = mcs.sporttype 
														AND acs.bettype = mcs.bettype
			WHERE	mcs.custid = @mrecommend 
					AND mcs.sporttype = 1 
					AND mcs.bettype = 301
					AND mcs.CommRate < acs.CommRate
		)
		BEGIN
			SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Master''s cash-in share for Colossus Bets is less than agent''s cash-in share.',
					@ErrCode = 219
			RETURN	
		END
	END


	--Check identical autoposition taking
	IF exists (
		SELECT 1 from 
			custsetting as mcs_old with (nolock)
			inner join custsetting as mcs_new  WITH(NOLOCK)on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and(	mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking
					or mcs_old.isautolivepositiontaking <> mcs_new.isautolivepositiontaking
			)
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 203					 
		return
	END

	--Check identical autoposition taking for DCS products
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustPTSetting3rd_Agent m WITH (NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent mo WITH (NOLOCK)
				ON m.SportType = mo.sporttype  
					AND m.BetType = mo.bettype
					AND m.IsLive = mo.IsLive
					AND mo.CustID = @mrecommend_old 
		WHERE m.CustID =  @mrecommend AND 
				(m.IsAutoSuperPT <> mo.IsAutoSuperPT OR m.AutoSuperPT <> mo.AutoSuperPT)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 9115					 
		return
	END
	
	--Check identical autoposition taking for 3rd Party
	IF exists (
		SELECT 1 from 
			custsetting3rd as mcs_old with (nolock)
			inner join custsetting3rd as mcs_new  WITH(NOLOCK)on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend AND mcs_old.sporttype <> 201
			and ( mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking
				  or mcs_old.isautolivepositiontaking <> mcs_new.isautolivepositiontaking
			)
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 204				 
		return
	END

	--Check identical autoposition taking for live casino
	IF EXISTS (
			SELECT 1
			FROM CustSettingGame mcs_old WITH(NOLOCK)
				INNER JOIN	CustSettingGame mcs_new WITH(NOLOCK) ON mcs_new.custid = @mrecommend AND mcs_new.sporttype = mcs_old.sporttype AND mcs_new.bettype = mcs_old.bettype 
			WHERE mcs_old.custid = @mrecommend_old AND mcs_old.sporttype in(162,202) AND (mcs_old.bettype = 1101 OR mcs_old.bettype between 1501 and 1599)
			AND (mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 205				 
		RETURN
	END
	
	--Check identical autoposition taking for Gold Deluxe
	IF EXISTS (
			SELECT	1
			FROM	CustSettingGame mcs_old WITH(NOLOCK)
				INNER JOIN CustSettingGame mcs_new WITH(NOLOCK) 
					ON	mcs_new.custid = @mrecommend 
						AND mcs_new.sporttype = mcs_old.sporttype 
						AND mcs_new.bettype = mcs_old.bettype 
			WHERE	mcs_old.custid = @mrecommend_old 
					AND mcs_old.sporttype = 255 
					AND mcs_old.bettype = 1701
					AND (mcs_old.isautopositiontaking <> mcs_new.isautopositiontaking)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Auto Position Taking of new master is not matched with old master.',
			@ErrCode = 209			 
		RETURN
	END

	--Check Position Taking
		--check m3_master_old <= m3_master_new

	IF exists (
		SELECT 1 from 
			custsetting as mcs_old with (nolock)
			inner join custsetting as mcs_new  WITH(NOLOCK)on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and
			(mcs_old.mpositiontaking > mcs_new.mpositiontaking
			or (mcs_old.bettype in (1,3,7,8) and mcs_old.sporttype =1 and mcs_old.mlivepositiontaking > mcs_new.mlivepositiontaking))
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 206					 
		return
	END
	
	--Check Position Taking for DCS products
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustPTSetting3rd_Agent m WITH (NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent mo WITH (NOLOCK)
				ON m.SportType = mo.sporttype  
					AND m.BetType = mo.bettype
					AND m.IsLive = mo.IsLive
					AND mo.CustID = @mrecommend_old 
		WHERE m.CustID =  @mrecommend AND mo.MasterPT > m.MasterPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 9116				 
		return
	END

	--Check Position Taking for 3rd Party
		--check m3_master_old <= m3_master_new

	IF exists (
		SELECT 1 from 
			custsetting3rd as mcs_old with (nolock)
			inner join custsetting3rd as mcs_new  WITH(NOLOCK)on mcs_old.sporttype=mcs_new.sporttype and mcs_old.bettype=mcs_new.bettype						
		where
			mcs_old.custid = @mrecommend_old and  mcs_new.custid = @mrecommend
			and ((mcs_old.mpositiontaking > mcs_new.mpositiontaking AND mcs_new.sporttype <> 201)
			or (mcs_old.bettype in (85,86,87,89,90) and mcs_old.sporttype =161 and mcs_old.mlivepositiontaking > mcs_new.mlivepositiontaking)
			)
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 207					 
		return
	END

	--Check Position Taking for live casino
		--check m3_master_old <= m3_master_new
	
	IF @mSyncLiveCasino_Old = 1 AND @mSyncLiveCasino = 1 AND EXISTS(
			SELECT 1 
			FROM CustSettingGame mcs_old WITH(NOLOCK) 
				INNER JOIN CustSettingGame mcs_new WITH(NOLOCK) ON mcs_new.custid = @mrecommend AND mcs_new.sporttype = mcs_old.sporttype AND mcs_new.bettype = mcs_old.bettype
			WHERE mcs_old.custid = @mrecommend_old AND mcs_old.sporttype = 162 AND mcs_old.bettype = 1101
				AND mcs_old.mpositiontaking > mcs_new.mpositiontaking	
		)	
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 208					 
		return
	END	

	--Check Position Taking for Keno
		--check m3_master_old <= m3_master_new
	
	IF EXISTS(
			SELECT 1 
			FROM CustSettingGame mcs_old WITH(NOLOCK) 
				INNER JOIN CustSettingGame mcs_new WITH(NOLOCK) ON mcs_new.custid = @mrecommend AND mcs_new.sporttype = mcs_old.sporttype AND mcs_new.bettype = mcs_old.bettype
			WHERE mcs_old.custid = @mrecommend_old AND mcs_old.sporttype = 202 AND mcs_old.bettype between 1501 and 1599
				AND mcs_old.mpositiontaking > mcs_new.mpositiontaking	
		)	
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 208					 
		return
	END
	
	--Check Position Taking for Gold Deluxe
		--check m3_master_old <= m3_master_new
	
	IF EXISTS(
			SELECT	1 
			FROM	CustSettingGame mcs_old WITH(NOLOCK) 
				INNER JOIN CustSettingGame mcs_new WITH(NOLOCK) 
					ON	mcs_new.custid = @mrecommend 
						AND mcs_new.sporttype = mcs_old.sporttype 
						AND mcs_new.bettype = mcs_old.bettype
			WHERE	mcs_old.custid = @mrecommend_old 
					AND mcs_old.sporttype = 255 
					AND mcs_old.bettype = 1701
					AND mcs_old.mpositiontaking > mcs_new.mpositiontaking	
		)	
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ': Master Position Taking of new master is less than Master Position Taking of old master.',
			@ErrCode = 210			 
		return
	END	

		--m2+a2<=m3		
		--check n3<=m2+a2<=l3 IF im2 = 0, 
		--a2<=l3 and um2+a2>=n3 IF im2 = 1
	IF exists (
		SELECT 1 from 
			custsetting as mcs with (nolock)
			inner join custsetting as acs  WITH(NOLOCK)on mcs.custid = @mrecommend and acs.custid = @recommend
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype
			inner join custoverride as mco  WITH(NOLOCK)on mcs.custid = mco.custid and mcs.sporttype = mco.sporttype and mcs.bettype = mco.bettype
		where
		
		--m2+a2<=m3
		(
			(acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking)
			or
			((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) and (acs.mlivepositiontaking + acs.alivepositiontaking > mcs.mlivepositiontaking))
		)	
					
		--check n3<=m2+a2<=l3 IF im2 = 0, 
		--a2<=l3 and um2+a2>=n3 IF im2 = 1
		or
		(			
			((acs.isautompositiontaking = 0) and (acs.mpositiontaking + acs.apositiontaking > mco.maxpositiontaking or acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking))
			or 
			((acs.isautompositiontaking = 1) and (acs.apositiontaking > mco.maxpositiontaking or acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking))			
			or
			((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) and (acs.isautolivempositiontaking = 0) and (acs.mlivepositiontaking + acs.alivepositiontaking > mco.maxlivepositiontaking or acs.mlivepositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
			or 
			((mcs.sporttype =1) and (mcs.bettype in (1,3,7,8)) and (acs.isautolivempositiontaking = 1) and (acs.alivepositiontaking > mco.maxlivepositiontaking or acs.autolivempositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
		)			
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 209					 
		return
	END

	--Check Position Taking for DCS products
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustPTSetting3rd_Agent m WITH (NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent a WITH (NOLOCK)
				ON m.SportType = a.sporttype  
					AND m.BetType = a.bettype
					AND m.IsLive = a.IsLive
					AND a.CustID = @recommend 
		WHERE m.CustID =  @mrecommend
			AND
			(
				--m2+a2<=m3
				(a.MasterPT + a.AgentPT > m.MasterPT)
				OR
				--check n3<=m2+a2<=l3 IF im2 = 0, 
				--a2<=l3 and um2+a2>=n3 IF im2 = 1
				((a.IsAutoMasterPT = 0) and (a.MasterPT + a.AgentPT > m.MaxPT or a.MasterPT + a.AgentPT < m.MinPT))
				or 
				((a.IsAutoMasterPT = 1) and (a.AgentPT > m.MaxPT or a.AutoMasterPT + a.AgentPT < m.MinPT))			
			)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 9117				 
		return
	END
	
	
		--Check for 3rd party
		--m2+a2<=m3	
		--check n3<=m2+a2<=l3 IF im2 = 0, 
		--a2<=l3 and um2+a2>=n3 IF im2 = 1
	IF exists (
		SELECT 1 from 
			custsetting3rd as mcs with (nolock)
			inner join custsetting3rd as acs  WITH(NOLOCK)on mcs.custid = @mrecommend and acs.custid = @recommend
															and mcs.sporttype=acs.sporttype and mcs.bettype=acs.bettype
			inner join custoverride3rd as mco  WITH(NOLOCK)on mcs.custid = mco.custid and mcs.sporttype = mco.sporttype and mcs.bettype = mco.bettype
		where
		--m2+a2<=m3
		(
			((acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking) AND mcs.sporttype <> 201)
			or
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) and (acs.mlivepositiontaking + acs.alivepositiontaking > mcs.mlivepositiontaking))
		)			
		--check n3<=m2+a2<=l3 IF im2 = 0, 
		--a2<=l3 and um2+a2>=n3 IF im2 = 1
		or
		(
			((acs.isautompositiontaking = 0) and (acs.mpositiontaking + acs.apositiontaking > mco.maxpositiontaking or acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking) AND mcs.sporttype <> 201)
			or 
			((acs.isautompositiontaking = 1) and (acs.apositiontaking > mco.maxpositiontaking or acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking) AND mcs.sporttype <> 201)			
			or
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) and (acs.isautolivempositiontaking = 0) and (acs.mlivepositiontaking + acs.alivepositiontaking > mco.maxlivepositiontaking or acs.mlivepositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
			or 
			((mcs.sporttype =161) and (mcs.bettype in (85,86,87,89,90)) and (acs.isautolivempositiontaking = 1) and (acs.alivepositiontaking > mco.maxlivepositiontaking or acs.autolivempositiontaking + acs.alivepositiontaking < mco.minlivepositiontaking))
		)			
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 210					 
		return
	END

		--Check for live casino
		--m2+a2<=m3
		--n3<= im = 0? m2+a2 : um2 + a2
	IF @aSyncLiveCasino = 1 AND @mSyncLiveCasino = 1 AND EXISTS(
			SELECT 1
			FROM CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = @recommend AND mcs.sporttype = acs.sporttype AND acs.bettype = mcs.bettype 
				INNER JOIN CustOverrideGame mco WITH(NOLOCK) ON mco.custid = @mrecommend AND mco.sporttype = mcs.sporttype AND mco.bettype = mcs.bettype
			WHERE mcs.custid = @mrecommend AND mcs.sporttype = 162 AND mcs.bettype = 1101			
				AND (-- m2+a2<=m3
					acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking OR 
					--n3<=m2+a2
					(acs.isautompositiontaking = 0 AND acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking)
					OR
					(acs.isautompositiontaking = 1 AND acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking)
				)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 211
		RETURN
	END
	
		--Check for Keno
		--m2+a2<=m3
		--n3<= im = 0? m2+a2 : um2 + a2
	IF EXISTS(
			SELECT 1
			FROM CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) ON acs.custid = @recommend AND mcs.sporttype = acs.sporttype AND acs.bettype = mcs.bettype 
				INNER JOIN CustOverrideGame mco WITH(NOLOCK) ON mco.custid = @mrecommend AND mco.sporttype = mcs.sporttype AND mco.bettype = mcs.bettype
			WHERE mcs.custid = @mrecommend AND mcs.sporttype = 202 AND mcs.bettype between 1501 and 1599			
				AND (-- m2+a2<=m3
					acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking OR 
					--n3<=m2+a2
					(acs.isautompositiontaking = 0 AND acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking)
					OR
					(acs.isautompositiontaking = 1 AND acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking)
				)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 211
		RETURN
	END
			
		--Check for Gold Deluxe
		--m2+a2<=m3
		--n3<= im = 0? m2+a2 : um2 + a2
	IF EXISTS(
			SELECT	1
			FROM	CustSettingGame mcs WITH(NOLOCK) 
				INNER JOIN CustSettingGame acs WITH(NOLOCK) 
					ON	acs.custid = @recommend 
						AND mcs.sporttype = acs.sporttype 
						AND acs.bettype = mcs.bettype 
				INNER JOIN CustOverrideGame mco WITH(NOLOCK) 
					ON	mco.custid = @mrecommend 
						AND mco.sporttype = mcs.sporttype 
						AND mco.bettype = mcs.bettype
			WHERE	mcs.custid = @mrecommend 
					AND mcs.sporttype = 255 
					AND mcs.bettype = 1701
				AND (-- m2+a2<=m3
					acs.mpositiontaking + acs.apositiontaking > mcs.mpositiontaking OR 
					--n3<=m2+a2
					(acs.isautompositiontaking = 0 AND acs.mpositiontaking + acs.apositiontaking < mco.minpositiontaking)
					OR
					(acs.isautompositiontaking = 1 AND acs.autompositiontaking + acs.apositiontaking < mco.minpositiontaking)
				)
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': Agent exceeded new master position taking.',
			@ErrCode = 211
		RETURN
	END
	--Check Position Taking	
		--all a2<=a4
		--all a1<=a4
	IF exists (
			SELECT 1 from 
				custsetting as scs with (nolock)
				inner join custsetting as acs  WITH(NOLOCK)on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c  WITH(NOLOCK)on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where
			--all a<=a4
			(
				(acs.apositiontaking > scs.apositiontaking)
				or
				((acs.sporttype =1) and (acs.bettype in (1,3,7,8)) and (acs.alivepositiontaking > scs.alivepositiontaking))
			)
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 212					 

		return
	END
	
	--Check Position Taking for DCS products  --all a2<=a4
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.custinfo c WITH(NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent s WITH (NOLOCK) ON @srecommend = s.CustID
			INNER JOIN dbo.CustPTSetting3rd_Agent a WITH (NOLOCK)
				ON s.SportType = a.sporttype  
					AND s.BetType = a.bettype
					AND s.IsLive = a.IsLive
					AND a.CustID = c.CustID 
		WHERE c.recommend =  @recommend AND c.RoleID = 2 AND a.AgentPT > s.AgentPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 9118			 
		return
	END
	
	--Check Position Taking for DCS products --all a1<=a4
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.custinfo c WITH(NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent s WITH (NOLOCK) ON @srecommend = s.CustID
			LEFT JOIN dbo.CustPTSetting3rd_Member mem WITH (NOLOCK)
				ON s.SportType = mem.sporttype  
					AND s.BetType = mem.bettype
					AND s.IsLive = mem.IsLive
					AND mem.CustID = c.CustID 
			LEFT JOIN dbo.CustPTGroupSetting3rd_Member memg WITH (NOLOCK)
				ON s.SportType = memg.sporttype  
					AND s.BetType = memg.bettype
					AND s.IsLive = memg.IsLive
					AND memg.AgentID = c.recommend 
		WHERE c.recommend =  @recommend AND c.RoleID = 1 AND ISNULL(mem.AgentPT,memg.AgentPT) > s.AgentPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 9119			 
		return
	END
	
	--Check Position Taking for DCS products --all us1<=s4 if is1 = 1
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.custinfo c WITH(NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent s WITH (NOLOCK) ON @srecommend = s.CustID
			LEFT JOIN dbo.CustPTSetting3rd_Member mem WITH (NOLOCK)
				ON s.SportType = mem.sporttype  
					AND s.BetType = mem.bettype
					AND s.IsLive = mem.IsLive
					AND mem.CustID = c.CustID 
			LEFT JOIN dbo.CustPTGroupSetting3rd_Member memg WITH (NOLOCK)
				ON s.SportType = memg.sporttype  
					AND s.BetType = memg.bettype
					AND s.IsLive = memg.IsLive
					AND memg.AgentID = c.recommend 
		WHERE c.recommend =  @recommend AND c.RoleID = 1 
			AND ISNULL(mem.IsAutoSuperPT,memg.IsAutoSuperPT) = 1
			AND ISNULL(mem.AutoSuperPT,memg.AutoSuperPT) > s.SuperPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 9120			 
		return
	END
	
	--Check Position Taking	for 3rd party
		--all a2<=a4
		--all a1<=a4
	IF exists (
			SELECT 1 from 
				custsetting3rd as scs with (nolock)
				inner join custsetting3rd as acs  WITH(NOLOCK)on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c  WITH(NOLOCK)on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where 
			((acs.apositiontaking > scs.apositiontaking) AND scs.sporttype <> 201)
			or
			((acs.sporttype =161) and (acs.bettype in (85,86,87,89,90)) and (acs.alivepositiontaking > scs.alivepositiontaking))
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 213				 

		return
	END

	--Check Position Taking	for Keno
		--all a2<=a4
		--all a1<=a4
	IF exists (
			SELECT 1 from 
				CustSettingGame as scs with (nolock)
				inner join CustSettingGame as acs  WITH(NOLOCK)on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				inner join customer as c  WITH(NOLOCK)on c.custid = acs.custid and c.roleid in (1,2) 
														and c.recommend = @recommend --get member and agent			
			where (acs.apositiontaking > scs.apositiontaking) AND scs.sporttype = 202	
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 213				 

		return
	END
	
	--Check Position Taking	for Gold Deluxe 
		--all a2<=a4
		--all a1<=a4
	IF exists (
			SELECT 1 from 
				CustSettingGame as scs with (nolock)
				inner join CustSettingGame as acs  WITH(NOLOCK)
					ON	scs.custid = @srecommend  
						and scs.sporttype=acs.sporttype 
						AND scs.bettype=acs.bettype
				inner join customer as c  WITH(NOLOCK)
					ON	c.custid = acs.custid 
					AND c.roleid in (1,2)
					AND c.recommend = @recommend --get member and agent			
			where (acs.apositiontaking > scs.apositiontaking) AND scs.sporttype = 255
	)
	BEGIN	
		SELECT @ErrMsg = 'Error master ' + @Mastername + ', agent ' + @agentname + ': Agent or member exceeded new super position taking.',
			@ErrCode = 213				 

		return
	END

	--Check P2P :Game Comm
	--IF exists(
	--	SELECT TOP 1 1
	--	FROM dbo.P2PGROUPCOMM m WITH(NOLOCK)
	--		INNER JOIN dbo.P2PGROUPCOMM a WITH(NOLOCK)
	--			ON a.GroupID = M.GroupID
	--		WHERE  m.custid = @mrecommend AND A.custid = @recommend
	--				AND (m.adiscount < a.discount )
	--)
	--BEGIN
	--	SELECT @ErrMsg = 'Error master ' + @mastername + ', agent ' + @agentname + ': P2P''s commission of agent is is greater than P2P''s commission of new master .',
	--		@ErrCode = 214
	--	return
	--END

	-- Check Max Win Limit for DCS
	SELECT	@DCSSportType = 0

	SELECT TOP(1)	@DCSSportType = cwllaA.SportType
	FROM		dbo.CustWinLossLimit_Agent AS cwllaM WITH(NOLOCK)
	INNER JOIN	dbo.CustWinLossLimit_Agent AS cwllaA WITH(NOLOCK)
			ON	cwllaA.SportType = cwllaM.SportType
			AND	cwllaA.BetType = cwllaM.BetType
			AND	cwllaM.CustId = @mrecommend
			AND	cwllaA.CustId = @recommend
	WHERE	cwllaM.MaxWinLimit <> 0
		AND	(	cwllaM.MaxWinLimit < cwllaA.MaxWinLimit
			OR	cwllaA.MaxWinLimit = 0
		)

	IF	@DCSSportType <> 0
	BEGIN
		SELECT	TOP(1) @DCSSportName = p.ProductName
		FROM		dbo.ProductSettingDetail AS psd WITH(NOLOCK)
		INNER JOIN	DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK)
				ON	p.ProductID = psd.ProductID
		WHERE	psd.SportType = @DCSSportType

	    SELECT	@ErrMsg	= 'Error Master ' + @mastername + ', agent ' + @agentname 
						+ ': The master''s Max Win Limit for the product ' + @DCSSportName + ' is less than the agent''s Max Win Limit.'
			,	@ErrCode = 9121
			
		RETURN
	END

	-- Check Max Loss Limit for DCS
	SELECT	@DCSSportType = 0

	SELECT TOP(1)	@DCSSportType = cwllaA.SportType
	FROM		dbo.CustWinLossLimit_Agent AS cwllaM WITH(NOLOCK)
	INNER JOIN	dbo.CustWinLossLimit_Agent AS cwllaA WITH(NOLOCK)
			ON	cwllaA.SportType = cwllaM.SportType
			AND	cwllaA.BetType = cwllaM.BetType
			AND	cwllaM.CustId = @mrecommend
			AND	cwllaA.CustId = @recommend
	WHERE	cwllaM.MaxLossLimit <> 0
		AND	(	cwllaM.MaxLossLimit < cwllaA.MaxLossLimit
			OR	cwllaA.MaxLossLimit = 0
		)

	IF	@DCSSportType <> 0
	BEGIN
		SELECT	TOP(1) @DCSSportName = p.ProductName
		FROM		dbo.ProductSettingDetail AS psd WITH(NOLOCK)
		INNER JOIN	DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK)
				ON	p.ProductID = psd.ProductID
		WHERE	psd.SportType = @DCSSportType

	    SELECT	@ErrMsg	= 'Error Master ' + @mastername + ', agent ' + @agentname 
						+ ': The master''s Max Loss Limit for the product ' + @DCSSportName + ' is less than the agent''s Max Loss Limit.'
			,	@ErrCode = 9122
			
		RETURN
	END

END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCheckMoveAgent] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerCheckMoveAgent] TO [vnteam] AS [dbo]