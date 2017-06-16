ALTER PROCEDURE [dbo].[Acc_CustomerCheckMoveMaster]
	@supername	VARCHAR(40),
	@mastername VARCHAR(40),
	@userid		INT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Johnson
	Date: 2012-04-03
	Task : Check moving a master to another super
	DB: DBCUST/CustDB
	
	Revisions:
		- 20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).
		- 20120821@Dan: add virtual soccer, remove FI
		- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
		- 20131022@Elodie: Remove checking setting for Financial and Poker products [Redmine:#6480]
		- 20131024@Elodie: Add HR Fixed Odds [Redmine:#6505]
		- 20140314@Elodie: Add Keno product [Redmine:#13326]
		- 20140818@Logan:   Exclude disabled agents, members while checking constraints. [Redmine: #19763]
		- 20140828@Logan:   Add constraint for E-Sports status [Redmine: #20531]
		- 20150511@Kathy: Add Gold Deluxe product [Redmine:#34486]
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
		Max errorcode 210
	- @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun   DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()

	
	DECLARE @srecommend				INT, 
			@mrecommend				INT,
			@srecommend_old			INT, 
			@scurrency				TINYINT, 
			@mcurrency				TINYINT,
			@sdisable151_31			BIT,-- @sdisableHR -> @sdisable151_31 
			@mDisable151_31			BIT,-- @mdisableHR -> @mDisable151_31 			
			@sSyncCasino			BIT,
			@mSyncCasino			BIT,
			@sSyncBingo				BIT,
			@mSyncBingo				BIT,
			@sSyncLiveCasino		BIT,
			@mSyncLiveCasino		BIT,
			@sIsInternal			BIT,
			@mIsInternal			BIT,
			@sDisableOutright		BIT,
			@mDisableOutright		BIT,
			@sDisableCasino			BIT,
			@mDisableCasino			BIT,
			@sDisableLiveCasino		BIT,
			@mDisableLiveCasino 	BIT,
			@mDisable151_41			BIT,-- @mDisableOpenTote -> @mDisable151_41
			@sDisable151_41			BIT,-- @sDisableOpenTote -> @sDisable151_41
			@mDisable151_51			BIT,
			@sDisable151_51			BIT,
			@mDisable152_41			BIT,
			@sDisable152_41			BIT,
			@mDisable152_51			BIT,
			@sDisable152_51			BIT,
			@mDisable153_51			BIT,
			@sDisable153_51			BIT,
			@sDisableNumber			BIT,
			@mDisableNumber			BIT,
			@sDisableBingo			BIT,
			@mDisableBingo			BIT,
			@sClosed				BIT,	
			@mClosed				BIT,
			@sSuspended				BIT,	
			@mSuspended				BIT,
			--@sMaxTransferP2P		MONEY,
			--@mMaxTransferP2P		MONEY,
			--@sIsAutoResetP2P		BIT,
			--@mIsAutoResetP2P		BIT,
			--@sDisableP2P			BIT, 
			--@mDisableP2P			BIT, 
			--@sDisableFunP2P		BIT,
			--@mDisableFunP2P		BIT,
			@sDisableHRFixedOdds	BIT,
			@mDisableHRFixedOdds	BIT,
			@sGivenCredit			MONEY,
			@mGivenCredit			MONEY,
			@sUsedCredit			MONEY,
			@sHideVirtualSports		BIT, 
			@mHideVirtualSports		BIT,
			@sDisableEsports	    BIT,
			@mDisableEsports	    BIT,
			@sHideKeno				BIT, 
			@mHideKeno				BIT,
			@mHideGoldDeluxe		BIT,
			@sHideGoldDeluxe		BIT,
			@mDisableSuperLive		BIT,
			@mHideColossusBet		BIT,
			@sHideColossusBet		BIT,
			@sDisableSuperLive		BIT,
			@AdminUser				VARCHAR(50)
			, @DCSSportType			INT
			, @DCSSportName			NVARCHAR(50)

	SELECT @srecommend			= custid
	     , @scurrency			= currency
	     , @sdisable151_31		= DisableHorseracing
	     , @sSyncCasino		    = SyncCasino
	     , @sSyncBingo			= SyncBingo
	     , @sSyncLiveCasino	    = SyncLiveCasino
	     , @sDisableOutright	= DisableOutright
	     , @sDisableCasino		= DisableCasino
	     , @sDisableLiveCasino  = DisableLiveCasino
	     , @sDisable151_41		= DisableOpenTote
	     , @sDisable151_51		= Disable151_AU
	     , @sDisable152_41		= Disable152_UK
	     , @sDisable152_51		= Disable152_AU
	     , @sDisable153_51		= Disable153_AU
	     , @sDisableBingo		= DisableBingo
	     , @sDisableNumber		= DisableNumber
	     , @sClosed			    = closed
	     , @sSuspended			= reject
	     , @sDisableHRFixedOdds = DisableHRFixedOdds
	     , @sDisableEsports     = DisableEsports
	     , @sGivenCredit		= credit
	     , @sHideVirtualSports  = HideVirtualSports
	     , @sHideKeno			= HideKeno
	     , @sHideGoldDeluxe		= HideGoldDeluxe
	     , @sHideColossusBet	= HideColossusBet
		 , @sDisableSuperLive	= DisableSuperLive
	  FROM custinfo WITH(NOLOCK) 
	 WHERE username = @supername
	   AND roleid = 4

	SELECT @mrecommend			= custid
	     , @srecommend_old		= srecommend
	     , @mcurrency			= currency
	     , @mDisable151_31		= DisableHorseracing
	     , @mSyncCasino		    = SyncCasino
	     , @mSyncLiveCasino	    = SyncLiveCasino
	     , @mSyncBingo			= SyncBingo
	     , @mDisableOutright	= DisableOutright
	     , @mDisableCasino		= DisableCasino
	     , @mDisableLiveCasino  = DisableLiveCasino
	     , @mDisable151_41		= DisableOpenTote
	     , @mDisable151_51		= Disable151_AU
	     , @mDisable152_41		= Disable152_UK
	     , @mDisable152_51		= Disable152_AU
	     , @mDisable153_51		= Disable153_AU
	     , @mDisableBingo		= DisableBingo
	     , @mDisableNumber		= DisableNumber
	     , @mSuspended			= reject
	     , @mClosed			    = closed
	     , @mDisableHRFixedOdds = DisableHRFixedOdds
	     , @mDisableEsports     = DisableEsports
	     , @mGivenCredit		= credit
	     , @mHideVirtualSports  = HideVirtualSports
	     , @mHideKeno			= HideKeno 		
	     , @mHideGoldDeluxe		= HideGoldDeluxe
	     , @mHideColossusBet	= HideColossusBet
		 , @mDisableSuperLive	= DisableSuperLive
	  FROM custinfo WITH(NOLOCK)
	 WHERE username = @mastername
	   AND roleid = 3

	-- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
	SELECT @sUsedCredit = sum(credit) FROM custinfo WITH(NOLOCK) WHERE roleid = 3 AND srecommend = @srecommend
	IF ISNULL(@sGivenCredit,0) - ISNULL(@sUsedCredit,0) < ISNULL(@mGivenCredit,0)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': New super credit is insufficient to move this master.',
			@ErrCode = 100			 
		return
	END
	
	IF ISNULL(@srecommend, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super not found.',
			@ErrCode = 101					 
		RETURN
	END

	IF ISNULL(@mrecommend, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master not found.',
			@ErrCode = 102					 	
		RETURN
	END

	IF ISNULL(@srecommend_old, 0) = @srecommend
	BEGIN
		SELECT @ErrMsg = 'The master '+ @mastername +' already belongs to super '+ @supername +'.',
			@ErrCode = 103					 
		RETURN
	END

	--Check an account disabled or not 
	EXEC dbo.Acc_CustomerSelCheckEnable @username = @mastername, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT 
	IF @ErrCode <>0		RETURN 

	EXEC dbo.Acc_CustomerSelCheckEnable @username = @supername, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT 
	IF @ErrCode <>0		RETURN 


	IF @scurrency <> @mcurrency
	BEGIN
		SELECT @ErrMsg = 'Currency of super and master does not match.',
			@ErrCode = 104					 
		RETURN
	END

	--Check INTernal status
	SELECT @sIsInternal = IsInternal FROM CustSuper with (nolock) WHERE custid = @srecommend
	SELECT @mIsInternal = IsInternal FROM CustMaster with (nolock) WHERE custid = @mrecommend
	IF ISNULL(@sIsInternal, 0) = 1 AND ISNULL(@mIsInternal, 0) = 0
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move normal(betting) master to new internal super.',
			@ErrCode = 105					 
		RETURN
	END
	
	--20120726@Kiwi: Only IT Admin performs the moving for financial accounts (INTERNAL super/master/agent).

	SELECT @AdminUser = username FROM custinfo WITH (NOLOCK) WHERE custid = @userid
	
	
	IF ((ISNULL(@sIsInternal, 0) = 1 AND ISNULL(@mIsInternal, 0) = 1 AND (@AdminUser NOT LIKE 'dba%') AND (@AdminUser NOT LIKE 'pgm%') AND (@AdminUser NOT IN ('vndbateam','vnQaTeam'))))
	BEGIN 
			SELECT @ErrMsg = N'This function is not allowed to perform the moving for financial accounts. Please contact IT@nexcel.vn for assistance. Thanks.', 
					@ErrCode = 119
			RETURN
	END
		
	-- check is closed
	IF @sClosed = 1
	BEGIN
		SELECT @ErrMsg = 'Error occurs. Cannot move to closed super.',
			@ErrCode = 106					 
		RETURN
	END

	--Check Horse status:
	IF @sdisable151_31 = 1 AND @mDisable151_31 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled SA Racing but new super not enabled SA Racing.',
			@ErrCode = 107					 
		RETURN
	END

	--Check OpenTote
	IF @sDisable151_41 = 1 AND @mDisable151_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled UK/IRish Racing but new super not enabled UK/IRish Racing.',
			@ErrCode = 108				 
		RETURN
	END

	--Check Horse Racing for AU Tote
	IF @sDisable151_51 = 1 AND @mDisable151_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled Aust Racing but new super not enabled Aust Racing.',
			@ErrCode = 109			 
		RETURN
	END

	--Check Greyhound for UK Tote
	IF @sDisable152_41 = 1 AND @mDisable152_41 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled UK Greyhound but new super not enabled UK Greyhound.',
			@ErrCode = 110		 
		RETURN
	END

	--Check Greyhound for AU Tote
	IF @sDisable152_51 = 1 AND @mDisable152_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Aust Greyhound but new super not enabled Aust Greyhound.',
			@ErrCode = 111			 
		RETURN
	END

	--Check Harness for AU Tote
	IF @sDisable153_51 = 1 AND @mDisable153_51 = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master enabled Aust Harness but new super not enabled Aust Harness.',
			@ErrCode = 112			 
		RETURN
	END

	-- Check DCS Product's [disabled]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus s WITH(NOLOCK)ON s.CustID = @srecommend
		INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
	WHERE dbo.f_GetProductStatus(s.bitmapIsDisabled, stt.bitmapOrder) = 1
			AND dbo.f_GetProductStatus(m.bitmapIsDisabled, stt.bitmapOrder) = 0
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername 
					+ ': master enabled '
					+ @DCSSportName
					+ ' but new super not enabled '
					+ @DCSSportName
					+ '.',
			@ErrCode = 9111
		return
	END
	-- Check DCS Product's [hidden]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus s WITH(NOLOCK)ON s.CustID = @srecommend
		INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
	WHERE dbo.f_GetProductStatus(s.bitmapIsHidden, stt.bitmapOrder) = 1
			AND dbo.f_GetProductStatus(m.bitmapIsHidden, stt.bitmapOrder) = 0
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg = 'Master is offered '
					+ @DCSSportName
					+ ' but new super is not offered '
					+ @DCSSportName
					+ '.',
			@ErrCode = 9112
		return
	END
	
	-- Check DCS Product's [sync]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus s WITH(NOLOCK)ON s.CustID = @srecommend
		INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
	WHERE dbo.f_GetProductStatus(s.bitmapHasSynced, stt.bitmapOrder) = 0
			AND dbo.f_GetProductStatus(m.bitmapHasSynced, stt.bitmapOrder) = 1
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg	= 'Error super ' + @supername + ', master ' + @Mastername 
						+ ': Master has setting of ' + @DCSSportName + ' but new super doesn''t have setting of ' + @DCSSportName + '.',
			@ErrCode = 9113
		return
	END
	
	--Check Casino sync:
	IF @sSyncCasino = 0 AND @mSyncCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
			@ErrCode = 114					 
		RETURN
	END
	/*
	--Check Casino enable status
	IF @sDisableCasino = 1 AND (@mDisableCasino = 0)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enable Casino but new super is not enable Casino.',
			@ErrCode = 115
		RETURN
	END
	*/
	--Check Bingo sync
	IF @sSyncBingo = 0 AND @mSyncBingo = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Bingo but new super is not synchronized Bingo',
			@ErrCode = 115				 
		RETURN
	END

	--Check Casino sync:
	IF @sSyncLiveCasino = 0 AND @mSyncLiveCasino = 1
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is synchronized Casino but new super is not synchronized Casino.',
			@ErrCode = 116					 
		RETURN
	END

	--Check Bingo & Number status:
	IF @sdisableBingo = 1 AND @mdisableBingo = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Bingo but new super is not enabled Bingo.',
			@ErrCode = 117					 
		RETURN
	END


	IF @sdisableNumber = 1 AND @mdisableNumber = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Number Game but new super is not enabled Number Game.',
			@ErrCode = 118
		RETURN
	END
	
	IF @sdisableHRFixedOdds = 1 and @mdisableHRFixedOdds = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Horse Racing Fixed Odds but new super is not enabled Horse Racing Fixed Odds',
			@ErrCode = 118
		return
	END

    --E-Sports
	IF @sDisableEsports = 1 and @mDisableEsports = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled E-Sports but new super is not enabled E-Sports.'
		     , @ErrCode = 126
		RETURN
	END
	
	--Super Live
	IF @sDisableSuperLive = 1 and @mDisableSuperLive = 0
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is enabled Super Live but new super is not enabled Super Live.'
		     , @ErrCode = 127
		RETURN
	END

	--Check Virtual sport enable status
	IF @sHideVirtualSports = 1 and @mHideVirtualSports = 0
	BEGIN
		SELECT @ErrMsg = 'Master is offered Virtual Sports but new super is not offered Virtual Sports.',
			@ErrCode = 123					 
		return
	END	

	--Check Keno sport enable status
	IF @sHideKeno = 1 and @mHideKeno = 0
	BEGIN
		SELECT @ErrMsg = 'Master is offered Keno but new super is not offered Keno.',
			@ErrCode = 124	 
		return
	END
	--Check Horse,  Casino sync status:
	--no need to check for Horse
	/*IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 151)
		AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 151)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Horse Racing setting.',
			@ErrCode = 110					 
		RETURN
	END*/
	
	--Check Gold Deluxe sport enable status
	IF @sHideGoldDeluxe = 1 and @mHideGoldDeluxe = 0
	BEGIN
		SELECT @ErrMsg = 'Master is offered Gold Deluxe but new super is not offered Gold Deluxe.',
			@ErrCode = 125
		return
	END
	
	--Check Colossus Bet sport enable status
	IF @sHideColossusBet = 1 and @mHideColossusBet = 0
	BEGIN
		SELECT @ErrMsg = 'Master is offered Colossus Bets but new super is not offered Colossus Bets.',
			@ErrCode = 126
		return
	END


	--Check Number Game
	IF EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @mrecommend AND sporttype = 161)
		AND NOT EXISTS(SELECT 1 FROM custsetting3rd WITH (NOLOCK) WHERE custid = @srecommend AND sporttype = 161)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': super does not have Number Game setting.',
			@ErrCode = 201					 
		RETURN
	END

	--Check Casino Syn 
	--Remove check Casino Sync
	--IF exists(SELECT 1 from custinfo with (nolock) where custid = @mrecommend and SyncCasino = 1)
	--BEGIN
	--	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': master is already Casino-synchronized.',
	--		@ErrCode = 112					 
	--	return
	--END

	IF EXISTS (
			SELECT 1 
			FROM custsetting AS scs WITH (NOLOCK)
				INNER JOIN custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
			WHERE 
				(scs.bettype IN (1,2,3,7,8) AND ((scs.groupa<mcs.groupa) OR (scs.groupb<mcs.groupb) 
				OR (scs.groupc<mcs.groupc) OR (scs.groupd<mcs.groupd)))
				OR (scs.bettype NOT IN (1,2,3,7,8) AND scs.sdiscount<mcs.adiscount)
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Super''s commission for Sportbook is less than master''s commission.',
			@ErrCode = 202					 
		RETURN
	END

	--Check commission for DCS products
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustDiscount3rd_Agent s WITH (NOLOCK)
			INNER JOIN dbo.CustDiscount3rd_Agent m WITH (NOLOCK)
				ON s.SportType = m.sporttype  
					AND s.BetType = m.bettype
					AND m.CustID = @mrecommend 
		WHERE s.CustID =  @srecommend AND s.Discount < m.Discount)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Super''s commission is less than master''s commission.',
			@ErrCode = 9114				 
		RETURN
	END
	
	--check commission for 3rd party
	IF EXISTS (
			SELECT 1 
			FROM custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend 
															AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype 
			WHERE scs.sdiscount<mcs.adiscount AND scs.sporttype <> 201
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Super''s commission is less than master''s commission.',
			@ErrCode = 203				 
		RETURN
	END

	--Check commission for live casino 
	IF EXISTS(
			SELECT 1 
			FROM CustSettingGame AS scs WITH(NOLOCK)
				INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype
			WHERE scs.custid = @srecommend AND scs.sporttype = 162 AND scs.bettype = 1101
				 AND scs.sdiscount < mcs.adiscount
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s commission for Live Casino is less than master''s commission.',
				@ErrCode = 204
		RETURN	
	END

	--Check commission for Keno
	IF EXISTS(
			SELECT 1 
			FROM CustSettingGame AS scs WITH(NOLOCK)
				INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND scs.sporttype = mcs.sporttype AND scs.bettype = mcs.bettype
			WHERE scs.custid = @srecommend AND scs.sporttype = 202 AND scs.bettype between 1501 and 1599
				 AND scs.sdiscount < mcs.adiscount
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s commission for Keno is less than master''s commission.',
				@ErrCode = 204
		RETURN	
	END

	--Check commission for Gold Deluxe
	IF EXISTS(
			SELECT	1 
			FROM	CustSettingGame AS scs WITH(NOLOCK)
				INNER JOIN CustSettingGame mcs WITH(NOLOCK) 
					ON	mcs.custid = @mrecommend 
						AND scs.sporttype = mcs.sporttype 
						AND scs.bettype = mcs.bettype
			WHERE	scs.custid = @srecommend 
					AND scs.sporttype = 255 
					AND scs.bettype = 1701
					AND scs.sdiscount < mcs.adiscount
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s commission for Gold Deluxe is less than master''s commission.',
				@ErrCode = 204
		RETURN	
	END
	
	--Check commission for Colossus Bet
	IF EXISTS(
			SELECT	1 
			FROM	AgentCommRate  scs WITH(NOLOCK)
				JOIN AgentCommRate mcs WITH(NOLOCK) 
					ON	mcs.custid = @mrecommend 
						AND scs.sporttype = mcs.sporttype 
						AND scs.bettype = mcs.bettype
			WHERE	scs.custid = @srecommend 
					AND scs.sporttype = 204 
					AND scs.bettype = 18001
					AND scs.CommRate < mcs.CommRate
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s commission for Colossus Bets is less than master''s commission.',
				@ErrCode = 210
		RETURN	
	END
	
	--Check Cash-In Share for Colossus Bet
	IF EXISTS(
			SELECT	1 
			FROM	AgentCommRate  scs WITH(NOLOCK)
				JOIN AgentCommRate mcs WITH(NOLOCK) 
					ON	mcs.custid = @mrecommend 
						AND scs.sporttype = mcs.sporttype 
						AND scs.bettype = mcs.bettype
			WHERE	scs.custid = @srecommend 
					AND scs.sporttype = 204 
					AND scs.bettype = 18002
					AND scs.CommRate < mcs.CommRate
	)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s Cash-In Share for Colossus Bets is less than master''s Cash-In Share.',
				@ErrCode = 211
		RETURN	
	END
	
	--Check Myanmar Odds
	DECLARE @IsMyanmarOdds_source BIT = 0
	DECLARE @IsMyanmarOdds_destination BIT = 0
	
	SET @IsMyanmarOdds_destination =  dbo.fn_IsMyanmarOdds (@srecommend)

	SET @IsMyanmarOdds_source = dbo.fn_IsMyanmarOdds (@srecommend_old)

	
	IF @IsMyanmarOdds_source <> @IsMyanmarOdds_destination
	BEGIN
		
		SELECT @ErrMsg = 'Cannot move customer ' + @mastername + ' since amongs its new and old sites, one has % Odds.',
				@ErrCode = 212
		RETURN	
	END	
	
	IF @IsMyanmarOdds_source = 1
	BEGIN
		IF EXISTS(
				SELECT	1 
				FROM	AgentCommRate  scs WITH(NOLOCK)
					JOIN AgentCommRate mcs WITH(NOLOCK) 
						ON	mcs.custid = @mrecommend 
							AND scs.sporttype = mcs.sporttype 
							AND scs.bettype = mcs.bettype
				WHERE	scs.custid = @srecommend 
						AND scs.sporttype = 1 
						AND scs.bettype = 301
						AND scs.CommRate < mcs.CommRate
		)
		BEGIN
			SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @mastername + ': Super''s commission for Myanmar Odds is less than master''s commission.',
					@ErrCode = 213
			RETURN	
		END
	END

	--Check Position Taking
		--n4<=s3+m3<=s4		IF i3=0
		--m3<=s4 and u3<=s4	IF i3=1
		--u3+m3>=n4 IF i3=1
		--m3<=m4

	IF EXISTS (
			SELECT 1 FROM 
				custsetting AS scs WITH (NOLOCK)
				INNER JOIN custsetting AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
																AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
				INNER JOIN custoverride AS sco WITH (NOLOCK) ON scs.custid = sco.custid AND scs.sporttype = sco.sporttype AND scs.bettype = sco.bettype
			WHERE	
			--n4<=s3+m3<=s4	IF i3=0
			(
				((mcs.isautopositiontaking=0) AND ((mcs.spositiontaking + mcs.mpositiontaking < sco.minpositiontaking) OR (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)))
				OR
				((mcs.isautolivepositiontaking=0) AND (mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND ((mcs.slivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking) OR (mcs.slivepositiontaking + mcs.mlivepositiontaking > scs.slivepositiontaking)))
			)
			--m3<=s4 and u3<=s4	IF i3=1
			--u3+m3>=n4 IF i3=1
			OR
			(
				((mcs.isautopositiontaking=1) AND ((mcs.mpositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking + mcs.mpositiontaking < sco.minpositiontaking)))
				OR
				((mcs.isautolivepositiontaking=1) AND (mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND ((mcs.mlivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking)))
			)	
			--m3<=m4
			OR
			(
				(mcs.mpositiontaking > scs.mpositiontaking)
				OR
				((mcs.sporttype =1) AND (mcs.bettype IN (1,3,7,8)) AND (mcs.mlivepositiontaking > scs.mlivepositiontaking))
			)	
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 205				 
		RETURN
	END

	--Check Position Taking for DCS products
	--n4<=s3+m3<=s4		IF i3=0
	--m3<=s4 and u3<=s4	IF i3=1
	--u3+m3>=n4 IF i3=1
	--m3<=m4
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustPTSetting3rd_Agent scs WITH (NOLOCK)
			INNER JOIN dbo.CustPTSetting3rd_Agent mcs WITH (NOLOCK)
				ON scs.SportType = mcs.sporttype  
					AND scs.BetType = mcs.bettype
					AND scs.IsLive = mcs.IsLive
					AND mcs.CustID = @mrecommend 
		WHERE scs.CustID =  @srecommend 
			AND
			(
				--n4<=s3+m3<=s4	IF i3=0
				((mcs.IsAutoSuperPT=0) AND ((mcs.SuperPT + mcs.MasterPT < scs.MinPT) OR (mcs.SuperPT + mcs.MasterPT > scs.SuperPT)))
				--m3<=s4 and u3<=s4	IF i3=1
				--u3+m3>=n4 IF i3=1
				OR
				((mcs.IsAutoSuperPT=1) AND ((mcs.MasterPT > scs.SuperPT) OR (mcs.AutoSuperPT > scs.SuperPT) OR (mcs.AutoSuperPT + mcs.MasterPT < scs.MinPT)))	
				--m3<=m4
				OR
				(mcs.MasterPT > scs.MasterPT)	
			)
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 9115				 
		RETURN
	END
	
	--Check Position Taking for 3rd party
		--n4<=s3+m3<=s4		IF i3=0
		--m3<=s4 and u3<=s4	IF i3=1
		--u3+m3>=n4 IF i3=1
		--m3<=m4

	IF EXISTS (
			SELECT 1 FROM 
				custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN custsetting3rd AS mcs WITH (NOLOCK) ON scs.custid = @srecommend AND mcs.custid = @mrecommend
																AND scs.sporttype=mcs.sporttype AND scs.bettype=mcs.bettype
				INNER JOIN custoverride3rd AS sco WITH (NOLOCK) ON scs.custid = sco.custid AND scs.sporttype = sco.sporttype AND scs.bettype = sco.bettype
			WHERE
			--n4<=s3+m3<=s4	IF i3=0
			(
				(scs.sporttype <> 201 AND (mcs.isautopositiontaking=0) AND ((mcs.spositiontaking + mcs.mpositiontaking < sco.minpositiontaking) OR (mcs.spositiontaking + mcs.mpositiontaking > scs.spositiontaking)))
				OR
				((mcs.isautolivepositiontaking=0) AND (mcs.sporttype =161) AND (mcs.bettype IN (85,86,87,89,90)) AND ((mcs.slivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking) OR (mcs.slivepositiontaking + mcs.mlivepositiontaking > scs.slivepositiontaking)))
			)
			--m3<=s4 and u3<=s4	IF i3=1
			--u3+m3>=n4 IF i3=1
			OR
			(
				(scs.sporttype <> 201 AND (mcs.isautopositiontaking=1) AND ((mcs.mpositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking > scs.spositiontaking) OR (mcs.autopositiontaking + mcs.mpositiontaking < sco.minpositiontaking)))
				OR
				((mcs.isautolivepositiontaking=1) AND (mcs.sporttype =161) AND (mcs.bettype IN (85,86,87,89,90)) AND ((mcs.mlivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking > scs.slivepositiontaking) OR (mcs.autolivepositiontaking + mcs.mlivepositiontaking < sco.minlivepositiontaking)))
			)	
			--m3<=m4
			OR
			(
				(mcs.mpositiontaking > scs.mpositiontaking AND scs.sporttype <> 201)
				OR
				((mcs.sporttype =161) AND (mcs.bettype IN (85,86,87,89,90)) AND (mcs.mlivepositiontaking > scs.mlivepositiontaking))
			)		
				
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 206				 
		RETURN
	END

	--Check Position Taking for Live Casino
		--n4<=s3+m3<=s4		IF i3=0
		--m3<=s4 and u3<=s4	IF i3=1
		--u3+m3>=n4 IF i3=1
	IF @mSyncLiveCasino = 1 AND @sSyncLiveCasino = 1 AND EXISTS (
		SELECT 1
		FROM CustSettingGame scs WITH(NOLOCK) 
			INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = scs.sporttype AND mcs.bettype = scs.bettype 
			INNER JOIN CustOverrideGame sco WITH(NOLOCK) ON sco.custid = @srecommend AND sco.sporttype = scs.sporttype AND sco.bettype = scs.bettype
		WHERE scs.custid = @srecommend AND scs.sporttype = 162 AND scs.bettype = 1101	
		AND (
		--n4<=s3+m3<=s4	IF i3=0
		(mcs.isautopositiontaking = 0 AND ((mcs.mpositiontaking + mcs.spositiontaking < sco.minpositiontaking) OR (mcs.mpositiontaking + mcs.spositiontaking > scs.spositiontaking)))
		OR --m3<=s4 and u3<=s4	IF i3=1
		(mcs.isautopositiontaking = 1 AND (mcs.mpositiontaking > scs.spositiontaking OR mcs.autopositiontaking > scs.spositiontaking OR mcs.mpositiontaking + mcs.autopositiontaking < sco.minpositiontaking))	 
		)	
	)	
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 207				 
		RETURN
	END

	--Check Position Taking for Keno
		--n4<=s3+m3<=s4		IF i3=0
		--m3<=s4 and u3<=s4	IF i3=1
		--u3+m3>=n4 IF i3=1
	IF EXISTS (
		SELECT 1
		FROM CustSettingGame scs WITH(NOLOCK) 
			INNER JOIN CustSettingGame mcs WITH(NOLOCK) ON mcs.custid = @mrecommend AND mcs.sporttype = scs.sporttype AND mcs.bettype = scs.bettype 
			INNER JOIN CustOverrideGame sco WITH(NOLOCK) ON sco.custid = @srecommend AND sco.sporttype = scs.sporttype AND sco.bettype = scs.bettype
		WHERE scs.custid = @srecommend AND scs.sporttype = 202 AND scs.bettype between 1501 and 1599
		AND (
		--n4<=s3+m3<=s4	IF i3=0
		(mcs.isautopositiontaking = 0 AND ((mcs.mpositiontaking + mcs.spositiontaking < sco.minpositiontaking) OR (mcs.mpositiontaking + mcs.spositiontaking > scs.spositiontaking)))
		OR --m3<=s4 and u3<=s4	IF i3=1
		(mcs.isautopositiontaking = 1 AND (mcs.mpositiontaking > scs.spositiontaking OR mcs.autopositiontaking > scs.spositiontaking OR mcs.mpositiontaking + mcs.autopositiontaking < sco.minpositiontaking))	 
		)	
	)	
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 207				 
		RETURN
	END
	
	--Check Position Taking for Gold Deluxe
		--n4<=s3+m3<=s4		IF i3=0
		--m3<=s4 and u3<=s4	IF i3=1
		--u3+m3>=n4 IF i3=1
	IF EXISTS (
		SELECT	1
		FROM	CustSettingGame scs WITH(NOLOCK) 
			INNER JOIN CustSettingGame mcs WITH(NOLOCK) 
				ON	mcs.custid = @mrecommend 
					AND mcs.sporttype = scs.sporttype 
					AND mcs.bettype = scs.bettype 
			INNER JOIN CustOverrideGame sco WITH(NOLOCK) 
				ON	sco.custid = @srecommend 
					AND sco.sporttype = scs.sporttype 
					AND sco.bettype = scs.bettype
		WHERE	scs.custid = @srecommend 
				AND scs.sporttype = 255 
				AND scs.bettype = 1701
				AND (
				--n4<=s3+m3<=s4	IF i3=0
				(mcs.isautopositiontaking = 0 AND ((mcs.mpositiontaking + mcs.spositiontaking < sco.minpositiontaking) OR (mcs.mpositiontaking + mcs.spositiontaking > scs.spositiontaking)))
				OR --m3<=s4 and u3<=s4	IF i3=1
				(mcs.isautopositiontaking = 1 AND (mcs.mpositiontaking > scs.spositiontaking OR mcs.autopositiontaking > scs.spositiontaking OR mcs.mpositiontaking + mcs.autopositiontaking < sco.minpositiontaking))	 
				)	
	)	
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Master exceeded new super position taking.',
			@ErrCode = 207				 
		RETURN
	END
	
	--Check Position Taking	
		--all a2<=a4
		--all a1<=a4
	IF EXISTS (
			SELECT 1 FROM 
				custsetting AS scs WITH (NOLOCK)
				INNER JOIN custsetting AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
																AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
				INNER JOIN custInfo c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) AND c.Enabled = 1
														AND c.mrecommend = @mrecommend --get member and agent			
			WHERE
			--all a<=a4
			(
				(acs.apositiontaking > scs.apositiontaking)
				OR
				((acs.sporttype =1) AND (acs.bettype IN (1,3,7,8)) AND (acs.alivepositiontaking > scs.alivepositiontaking))
			)		
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 208				 
		RETURN
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
		WHERE c.mrecommend = @mrecommend AND c.RoleID = 2 AND a.AgentPT > s.AgentPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 91116				 
		RETURN
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
		WHERE c.mrecommend = @mrecommend  AND c.RoleID = 1 AND ISNULL(mem.AgentPT,memg.AgentPT) > s.AgentPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 91117				 
		RETURN
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
		WHERE c.mrecommend = @mrecommend  AND c.RoleID = 1 
			AND ISNULL(mem.IsAutoSuperPT,memg.IsAutoSuperPT) = 1
			AND ISNULL(mem.AutoSuperPT,memg.AutoSuperPT) > s.SuperPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 91118				 
		RETURN
	END
	
	--Check Position Taking	for 3rd party
		--all a2<=a4
		--all a1<=a4
	IF EXISTS (
			SELECT 1 FROM 
				custsetting3rd AS scs WITH (NOLOCK)
				INNER JOIN custsetting3rd AS acs WITH (NOLOCK) ON scs.custid = @srecommend  
																AND scs.sporttype=acs.sporttype AND scs.bettype=acs.bettype
				INNER JOIN custInfo c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) AND c.Enabled = 1
														AND c.mrecommend = @mrecommend --get member and agent			
			WHERE 
			(	(acs.apositiontaking > scs.apositiontaking AND scs.sporttype <> 201)
				OR
				((acs.sporttype =161) AND (acs.bettype IN (85,86,87,89,90)) AND (acs.alivepositiontaking > scs.alivepositiontaking))
			)
	)
	BEGIN
		
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 209					 
		RETURN
	END

	--Check Position Taking	for Keno
		--all a2<=a4
		--all a1<=a4
	IF exists (
			SELECT 1 from 
				CustSettingGame as scs with (nolock)
				inner join CustSettingGame as acs with (nolock) on scs.custid = @srecommend  
																and scs.sporttype=acs.sporttype and scs.bettype=acs.bettype
				INNER JOIN custInfo c WITH (NOLOCK) ON c.custid = acs.custid AND c.roleid IN (1,2) AND c.Enabled = 1
														and c.mrecommend = @mrecommend --get member and agent			
			where (acs.apositiontaking > scs.apositiontaking) AND scs.sporttype = 202	
	)
	BEGIN	
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 213				 

		return
	END

	--Check Position Taking	for Gold Deluxe
		--all a2<=a4
		--all a1<=a4
	IF exists (
			SELECT	1 
			FROM CustSettingGame as scs with (nolock)
				inner join CustSettingGame as acs with (nolock) 
					ON	scs.custid = @srecommend  
						and scs.sporttype = acs.sporttype 
						AND scs.bettype = acs.bettype
				INNER JOIN custInfo c WITH (NOLOCK) 
					ON	c.custid = acs.custid 
						AND c.roleid IN (1,2) 
						AND c.Enabled = 1
						and c.mrecommend = @mrecommend --get member and agent			
			where	(acs.apositiontaking > scs.apositiontaking) 
					AND scs.sporttype = 255
	)
	BEGIN	
		SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': Agent or member of existing master exceeded new super position taking.',
			@ErrCode = 213				 

		return
	END
	
	----Check P2P :Game Comm
	--IF exists(
	--	SELECT TOP 1 1
	--	FROM dbo.P2PGROUPCOMM s WITH(NOLOCK)
	--		INNER JOIN dbo.P2PGROUPCOMM m WITH(NOLOCK)
	--			ON m.GroupID = s.GroupID
	--		WHERE  s.custid = @srecommend AND m.custid = @mrecommend
	--				AND (s.sdiscount < m.adiscount )
	--)
	--BEGIN
	--	SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': P2P''s commission of master is greater than P2P''s commission of new super.',
	--		@ErrCode = 210
	--	return
	--END
	

	-- Check Max Win Limit for DCS
	SELECT	@DCSSportType = 0

	SELECT TOP(1)	@DCSSportType = cwllaM.SportType
	FROM		dbo.CustWinLossLimit_Agent AS cwllaS WITH(NOLOCK)
	INNER JOIN	dbo.CustWinLossLimit_Agent AS cwllaM WITH(NOLOCK)
			ON	cwllaM.SportType = cwllaS.SportType
			AND	cwllaM.BetType = cwllaS.BetType
			AND	cwllaS.CustId = @srecommend
			AND	cwllaM.CustId = @mrecommend
	WHERE	cwllaS.MaxWinLimit <> 0
		AND	(	cwllaS.MaxWinLimit < cwllaM.MaxWinLimit
			OR	cwllaM.MaxWinLimit = 0
		)

	IF	@DCSSportType <> 0
	BEGIN
		SELECT	TOP(1) @DCSSportName = p.ProductName
		FROM		dbo.ProductSettingDetail AS psd WITH(NOLOCK)
		INNER JOIN	DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK)
				ON	p.ProductID = psd.ProductID
		WHERE	psd.SportType = @DCSSportType

	    SELECT	@ErrMsg	= 'Error Super ' + @supername + ', master ' + @mastername 
						+ ': The super''s Max Win Limit for the product ' + @DCSSportName + ' is less than the master''s Max Win Limit.'
			,	@ErrCode = 9119

		RETURN
	END

	-- Check Max Loss Limit for DCS
	SELECT	@DCSSportType = 0

	SELECT TOP(1)	@DCSSportType = cwllaM.SportType
	FROM		dbo.CustWinLossLimit_Agent AS cwllaS WITH(NOLOCK)
	INNER JOIN	dbo.CustWinLossLimit_Agent AS cwllaM WITH(NOLOCK)
			ON	cwllaM.SportType = cwllaS.SportType
			AND	cwllaM.BetType = cwllaS.BetType
			AND	cwllaS.CustId = @srecommend
			AND	cwllaM.CustId = @mrecommend
	WHERE	cwllaS.MaxLossLimit <> 0
		AND	(	cwllaS.MaxLossLimit < cwllaM.MaxLossLimit
			OR	cwllaM.MaxLossLimit = 0
		)

	IF	@DCSSportType <> 0
	BEGIN
		SELECT	TOP(1) @DCSSportName = p.ProductName
		FROM		dbo.ProductSettingDetail AS psd WITH(NOLOCK)
		INNER JOIN	DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK)
				ON	p.ProductID = psd.ProductID
		WHERE	psd.SportType = @DCSSportType

	    SELECT	@ErrMsg	= 'Error Super ' + @supername + ', master ' + @mastername 
						+ ': The super''s Max Loss Limit for the product ' + @DCSSportName + ' is less than the master''s Max Loss Limit.'
			,	@ErrCode = 9120

		RETURN
	END


END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCheckMoveMaster] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerCheckMoveMaster] TO [vnteam] AS [dbo]
GO