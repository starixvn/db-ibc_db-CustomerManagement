ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveMember]
	@agentname     VARCHAR(40)
  , @membername    VARCHAR(40)
  , @userid        INT
  , @IP	           VARCHAR(15) = ''
  ,	@ReturnErrCode BIT = 0
  , @ErrCode       INT = 0 OUTPUT
  , @ErrMsg        NVARCHAR(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a member to another agent
DB: DBCUST/CustDB
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
	- 20110317@Johnson: check for Greyhound AND Harness
	- 20110413@Lukas: check closed/suspended
	- 20110801@Johnson: - remove bettype dead ball over/under of number game
						- add more bettype for nubmer game Warrior,  Next combo AND Number Group
	- 20110907@Sophia: Change Linked Server FROM DB052 to DB053	
	- 20110930@Johnson: Add more groups under Won currency.
	- 20111020@Tom:Add check P2P Game: Status, game setting, commission.
	- 20120322@Johnson: Check live casino
	- 20120821@Dan: add virtual soccer, remove FI
	- 20120928@Johnson: check double comm losing status 
	- 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
	- 20130307@Elodie: Add Virtual HR
	- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
	- 20131022@Elodie: Remove checking setting for Financial AND Poker products [Redmine:#6480]
	- 20131024@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20131108@Elodie: Splitting bodb02 INTo CustDB (Roll back updates on custinfo,customer table in main SP)  			
	- 20140314@Elodie: Add Keno product [Redmine:#13326]
	- 20140403@Kathy: Add Virtual Speedway (183), Virtual Virtual Cycling (185)	[Redmine:#14142]
						- Add Virtual Greyhounds/ Motor Racing (182,184)
	- 20140611@Elodie: Implement separate setting pages for Keno [Redmine:#13156]
	- 20140828@Logan:   Add constraint for Esports status [Redmine: #20531]
	- 20141204@Johnson: Add new country Korea [bettype = 1514] for Keno [Redmine:#26647]
	- 20150511@Kathy: Add Gold Deluxe product [Redmine:#34486]
	- 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
	- 20150707@Elodie: Add Super Live product [Redmine: #35776]	
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]	
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20151016@Helen: Data Type Error - [Redmine - 45677] 
	- 20151030@Dominic: Add MuayThai product [Redmine: #46732]
	- 20160205@Billy:	Apply for AllBet product - [Redmine: #51590]
	- 20160218@Dominic: Not allow to move a IMBC customer to MBC line and vice versa [Redmine: #50221]
	- 20160330@Elodie: Update code to correct commission for DCS product of member
	- 20160426@Winnie: fix  Bug #56653 [Move account: IsHidden of move master is changed to 0]  & #56802[[NAP] Move member: HideGoldDeluxe of moved member is changed to 0]
	- 20160819@Winnie: fix  Bug #62755 [NAP - IsDailyAutoReset of downline is changed to 0 after moving downline although both downline and upline has IsDailyAutoReset=1]
	
Param's Explanation:
- @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error. 
	Max errorcode:	133
- @ErrMsg: Error description.
Note: Check Disable status between Agent AND Member 
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @startRun DATETIME
    DECLARE @endRun   DATETIME
    DECLARE @duration INT
    SET @startRun = GETDATE()

    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
        @custid = @UserID
      , @funcname = '[OtherCust]'
      , @ErrCode = @ErrCode OUTPUT
      , @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode <> 0
	    RETURN
    --end

    DECLARE @srecommend				INT
          , @mrecommend				INT
          , @recommend				INT
          , @acurrency				TINYINT
          , @srecommend_old 		INT
          , @mrecommend_old 		INT
          , @recommend_old			INT
          , @currency_old			TINYINT
          ,	@custid					INT
          , @adisable151_31			BIT
          , @disable151_31			BIT
          , @aDisableOutright		BIT
          , @DisableOutright		BIT
          , @aSyncCasino			BIT
          , @SyncCasino				BIT
          , @aSyncLiveCasino		BIT
          , @SyncLiveCasino 		BIT
          , @aSyncBingo				BIT
          , @SyncBingo				BIT
          , @aDisable151_41			BIT
          , @Disable151_41			BIT
          , @aDisable151_51			BIT
          , @Disable151_51			BIT
          , @aDisable152_41			BIT
          , @Disable152_41			BIT
          , @aDisable152_51			BIT
          , @Disable152_51			BIT
          , @aDisable153_51			BIT
          , @Disable153_51			BIT
          , @aDisableBingo			BIT
          , @DisableBingo			BIT
          , @aDisableNumber			BIT
          , @DisableNumber			BIT
          , @aClosed				BIT
          , @Closed					BIT
          , @aSuspended				BIT
          , @Suspended				BIT
          , @aHideVirtualSports 	BIT
          , @HideVirtualSports		BIT
          , @aDisableVirtualSports	BIT
          , @DisableVirtualSports	BIT
          , @aDisableHRFixedOdds	BIT
          , @DisableHRFixedOdds		BIT
          , @aDoubleCommLosing		BIT
          , @DoubleCommLosing		BIT
          , @aHideKeno				BIT
          , @HideKeno				BIT
          , @aDisableEsports	    BIT
          , @DisableEsports		    BIT
          , @aGivenCredit			MONEY
          , @GivenCredit			MONEY
          , @aUsedCredit			MONEY
          , @aDisableGoldDeluxe		BIT
          , @DisableGoldDeluxe		BIT
          , @aHideGoldDeluxe		BIT
          , @HideGoldDeluxe			BIT
          , @aDisableColossusBet	BIT
          , @DisableColossusBet		BIT
          , @aHideColossusBet		BIT
          , @HideColossusBet		BIT
		  , @aDisableSuperLive		BIT
          , @DisableSuperLive		BIT
          , @DCSSportType			INT
	      , @DCSSportName			NVARCHAR(50)
	      , @xml XML

    SELECT @srecommend	          = srecommend
         , @mrecommend		      = mrecommend
         , @recommend		      = recommend
         , @acurrency		      = currency
         , @adisable151_31	      = DisableHorseracing
         , @aDisableOutright      = DisableOutright
         , @aSyncCasino		      = syncCasino
         , @aSyncLiveCasino	      = SyncLiveCasino
         , @aSyncBingo		      = syncBingo
         , @aDisable151_41	      = DisableOpenTote
         , @aDisable151_51	      = Disable151_AU
         , @aDisable152_41	      = Disable152_UK
         , @aDisable152_51	      = Disable152_AU
         , @aDisable153_51	      = Disable153_AU
         , @aDisableBingo	      = DisableBingo
         , @aDoubleCommLosing     = DoubleCommLosing
         , @aDisableNumber	      = DisableNumber
         , @aClosed			      = closed
         , @aSuspended		      = reject
         , @aDisableVirtualSports = DisableVirtualSports
         , @aHideVirtualSports	  = HideVirtualSports
         , @aDisableHRFixedOdds	  = DisableHRFixedOdds
         , @aHideKeno			  = HideKeno
         , @aDisableEsports       = DisableEsports
         , @aGivenCredit		  = credit	
         , @aDisableGoldDeluxe	  = DisableGoldDeluxe
         , @aHideGoldDeluxe		  = HideGoldDeluxe
         , @aDisableColossusBet	  = DisableColossusBet
         , @aHideColossusBet	  = HideColossusBet
		 , @aDisableSuperLive	  = DisableSuperLive
      FROM custinfo WITH(NOLOCK)
     WHERE username = @agentname
       AND roleid = 2

    SELECT @custid				 = custid
         , @recommend_old		 = recommend
         , @srecommend_old		 = srecommend
         , @mrecommend_old		 = mrecommend
         , @currency_old		 = currency
         , @disable151_31		 = DisableHorseracing
         , @DisableOutright		 = DisableOutright
         , @SyncCasino			 = SyncCasino
         , @SyncLiveCasino		 = SyncLiveCasino
         , @SyncBingo			 = SyncBingo
         , @Disable151_41		 = DisableOpenTote
         , @Disable151_51		 = Disable151_AU
         , @Disable152_41		 = Disable152_UK
         , @Disable152_51		 = Disable152_AU
         , @Disable153_51		 = Disable153_AU
         , @DisableBingo		 = DisableBingo
         , @DisableNumber		 = DisableNumber
         , @DoubleCommLosing	 = DoubleCommLosing
         , @Closed				 = closed
         , @Suspended			 = reject
         , @DisableVirtualSports = DisableVirtualSports
         , @HideVirtualSports	 = HideVirtualSports
         , @DisableHRFixedOdds	 = DisableHRFixedOdds
         , @HideKeno			 = HideKeno
         , @DisableEsports       = DisableEsports
         , @GivenCredit			 = credit
         , @DisableGoldDeluxe	 = DisableGoldDeluxe 
         , @HideGoldDeluxe		 = HideGoldDeluxe
         , @DisableColossusBet	 = DisableColossusBet 
         , @HideColossusBet		 = HideColossusBet
		 , @DisableSuperLive	 = DisableSuperLive
      FROM custinfo WITH(NOLOCK)
     WHERE username = @membername
       AND roleid = 1

	-- 20160218@Dominic: Not allow to move a IMBC customer to MBC line and vice versa
	DECLARE @_SiteAgent_old VARCHAR(10),@_SiteAgent VARCHAR(10)
	
	SELECT @_SiteAgent_old = site
	FROM dbo.Customer WITH(NOLOCK)
	WHERE CustID = @recommend_old
	
	SELECT @_SiteAgent = site
	FROM dbo.Customer WITH(NOLOCK)
	WHERE CustID = @recommend
	
	IF (@_SiteAgent_old = 'IMBC' OR @_SiteAgent = 'IMBC') AND @_SiteAgent_old <> @_SiteAgent
	BEGIN
		SELECT @ErrMsg = 'Not allow to move customer between MBC and IMBC sites!',@ErrCode = 911								
		RETURN	
	END
	
    -- 20130920@Elodie: Add constraint to avoid the insufficient Given Credit of any new super/master/agent being moving to.
    SELECT @aUsedCredit = SUM(credit)
      FROM custinfo WITH(NOLOCK)
     WHERE roleid = 1
       AND recommend = @recommend

    IF ISNULL(@aGivenCredit, 0) - ISNULL(@aUsedCredit, 0) < ISNULL(@GivenCredit, 0)
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': New agent credit is insufficient to move this member.'
	         , @ErrCode = 100
	    RETURN
    END

    IF ISNULL(@recommend, 0) = 0
    BEGIN
	    SELECT @ErrMsg = 'Error agent ' + @agentname + ': agent not found.'
	         , @ErrCode = 101

	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
    END

    IF ISNULL(@recommend_old, 0) = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent not found.',
		    @ErrCode = 102					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
    END

    IF ISNULL(@recommend, 0) = @recommend_old
    BEGIN
	    SELECT @ErrMsg = 'Error occurs. The member ' + @membername + ' already belongs to agent ' + @agentname + '.'
	         , @ErrCode = 103					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
    END
    --check an account disabled or not 
    EXEC dbo.Acc_CustomerSelCheckEnable
        @username = @membername
      , @ErrCode = @ErrCode OUTPUT
      , @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode <> 0
        RETURN

    EXEC dbo.Acc_CustomerSelCheckEnable
        @username = @agentname
      , @ErrCode = @ErrCode OUTPUT
      , @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode <> 0
        RETURN

    IF @currency_old <> @acurrency
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': currency of new agent AND member does not match.'
	         , @ErrCode = 104					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
    END

    ----------------------------------
    -- check is closed
    IF @aClosed = 1
    BEGIN
	    SELECT @ErrMsg = 'Error occurs. Cannot move to closed agent.',
		    @ErrCode = 105
	    RETURN
    END

    --Check Horse  enable status:
    IF @adisable151_31 = 1 AND @disable151_31 = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled SA Racing but new agent is not enabled SA Racing.',
		    @ErrCode = 106					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
    END

    --Check OpenTote
    IF @aDisable151_41 = 1 AND @Disable151_41 = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled UK/IRish Racing but new agent is not enabled UK/IRish Racing.',
		    @ErrCode = 107				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check Horse Racing for AU Tote
    IF @aDisable151_51 = 1 AND @Disable151_51 = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Racing but new agent is not enabled Aust Racing.',
		    @ErrCode = 108
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check Greyhound for UK Tote
    IF @aDisable152_41 = 1 AND @Disable152_41 = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled UK Greyhound but new agent is not enabled UK Greyhound.',
		    @ErrCode = 109				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check Greyhound for AU Tote
    IF @aDisable152_51 = 1 AND @Disable152_51 = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Greyhound but new agent is not enabled Aust Greyhound.',
		    @ErrCode = 110				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check Harness for AU Tote
    IF @aDisable153_51 = 1 AND @Disable153_51 = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Aust Harness but new agent is not enabled Aust Harness.',
		    @ErrCode = 111				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check VS enable status:
    IF @aHideVirtualSports = 1 AND @HideVirtualSports = 0
    BEGIN
	    SELECT @ErrMsg = 'Member is offered Virtual Sports but new agent is not offered Virtual Sports.',
		    @ErrCode = 112					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check Keno enable status:
    IF @aHideKeno = 1 AND @HideKeno = 0
    BEGIN
	    SELECT @ErrMsg = 'Member is offered Keno but new agent is not offered Keno.',
		    @ErrCode = 119					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END
    
    --Check Gold Deluxe enable status:
    IF @aHideGoldDeluxe = 1 AND @HideGoldDeluxe = 0
    BEGIN
	    SELECT @ErrMsg = 'Member is offered Gole Deluxe but new agent is not offered Gold Deluxe.',
		    @ErrCode = 120					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

	-- Check DCS Product's [disabled]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
		INNER JOIN dbo.CustProductStatus p WITH(NOLOCK)ON p.CustID = @custid
	WHERE dbo.f_GetProductStatus(a.bitmapIsDisabled, stt.bitmapOrder) = 1
			AND dbo.f_GetProductStatus(p.bitmapIsDisabled, stt.bitmapOrder) = 0
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled '
				+ @DCSSportName
				+ ' but new agent is not enabled '
				+ @DCSSportName
				+ '.',
		    @ErrCode = 9111				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
	END
	
	-- Check DCS Product's [hidden]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
		INNER JOIN dbo.CustProductStatus p WITH(NOLOCK)ON p.CustID = @custid
	WHERE dbo.f_GetProductStatus(a.bitmapIsHidden, stt.bitmapOrder) = 1
			AND dbo.f_GetProductStatus(p.bitmapIsHidden, stt.bitmapOrder) = 0
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		 SELECT @ErrMsg = 'Member is offered '
				+ @DCSSportName
				+ ' but new agent is not offered '
				+ @DCSSportName
				+ '.',
		    @ErrCode = 9112				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
	END
	
	-- Check DCS Product's [sync]
	SELECT top 1 @DCSSportType = stt.SportType
	FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
		INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
		INNER JOIN dbo.CustProductStatus p WITH(NOLOCK)ON p.CustID = @custid
	WHERE dbo.f_GetProductStatus(a.bitmapHasSynced, stt.bitmapOrder) = 0
			AND dbo.f_GetProductStatus(p.bitmapHasSynced, stt.bitmapOrder) = 1
	
	IF @DCSSportType <> 0
	BEGIN
		SELECT @DCSSportName = sportname
		FROM DBPRO.bodb02.dbo.sports WITH(NOLOCK)
		WHERE Sporttype = @DCSSportType
		
		SELECT @ErrMsg	= 'Error agent ' + @agentname + ', member ' + @membername
						+ ': Member has setting of ' + @DCSSportName + ' but new agent doesn''t have setting of ' + @DCSSportName + '.',
			@ErrCode = 9113
		return
	END

	-- Check Max Win Limit for DCS
	SELECT	@DCSSportType = 0

	SELECT TOP(1)	@DCSSportType = cwllm.SportType
	FROM		dbo.CustWinLossLimit_Agent AS cwllaA WITH(NOLOCK)
	INNER JOIN	dbo.CustWinLossLimit_Member AS cwllm WITH(NOLOCK)
			ON	cwllm.SportType = cwllaA.SportType
			AND	cwllm.BetType = cwllaA.BetType
			AND	cwllaA.CustId = @recommend
			AND	cwllm.CustId = @custid
	WHERE	cwllaA.MaxWinLimit <> 0
		AND	(	cwllaA.MaxWinLimit < cwllm.MaxWinLimit
			OR	cwllm.MaxWinLimit = 0
		)

	IF	@DCSSportType <> 0
	BEGIN
		SELECT	TOP(1) @DCSSportName = p.ProductName
		FROM		dbo.ProductSettingDetail AS psd WITH(NOLOCK)
		INNER JOIN	DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK)
				ON	p.ProductID = psd.ProductID
		WHERE	psd.SportType = @DCSSportType

	    SELECT	@ErrMsg	= 'Error Agent ' + @agentname + ', member ' + @membername 
						+ ': The agent''s Max Win Limit for the product ' + @DCSSportName + ' is less than the member''s Max Win Limit.'
			,	@ErrCode = 9119

		RETURN
	END

	-- Check Max Loss Limit for DCS
	SELECT	@DCSSportType = 0

	SELECT TOP(1)	@DCSSportType = cwllm.SportType
	FROM		dbo.CustWinLossLimit_Agent AS cwllaA WITH(NOLOCK)
	INNER JOIN	dbo.CustWinLossLimit_Member AS cwllm WITH(NOLOCK)
			ON	cwllm.SportType = cwllaA.SportType
			AND	cwllm.BetType = cwllaA.BetType
			AND	cwllaA.CustId = @recommend
			AND	cwllm.CustId = @custid
	WHERE	cwllaA.MaxLossLimit <> 0
		AND	(	cwllaA.MaxLossLimit < cwllm.MaxLossLimit
			OR	cwllm.MaxLossLimit = 0
		)

	IF	@DCSSportType <> 0
	BEGIN
		SELECT	TOP(1) @DCSSportName = p.ProductName
		FROM		dbo.ProductSettingDetail AS psd WITH(NOLOCK)
		INNER JOIN	DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK)
				ON	p.ProductID = psd.ProductID
		WHERE	psd.SportType = @DCSSportType

	    SELECT	@ErrMsg	= 'Error Agent ' + @agentname + ', member ' + @membername 
						+ ': The agent''s Max Loss Limit for the product ' + @DCSSportName + ' is less than the member''s Max Loss Limit.'
			,	@ErrCode = 9120

		RETURN
	END

	--Check Gold Deluxe
    IF @aDisableGoldDeluxe = 1 AND @DisableGoldDeluxe = 0
    BEGIN
		UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
           SET DisableGoldDeluxe = 1
        WHERE custid  = @custid
        
        IF @@ERROR <>0 
        BEGIN
            SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 309
            RETURN
        END
    END

	--Check Colossus Bet enable status
    IF @aHideColossusBet = 1 AND @HideColossusBet = 0
    BEGIN
	    SELECT @ErrMsg = 'Member is offered Colossus Bets but new agent is not offered Colossus Bets.',
		    @ErrCode = 121					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

	--Check Colossus Bet
    IF @aDisableColossusBet = 1 AND @DisableColossusBet = 0
    BEGIN
		UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
           SET DisableColossusBet = 1
        WHERE custid  = @custid
        
        IF @@ERROR <>0 
        BEGIN
            SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 310
            RETURN
        END
    END


    --Check CS SyncCasino between Agent AND Member 
    IF @aSyncCasino = 0 AND @SyncCasino = 1 
    BEGIN
	    SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': member is synchronized Casino but new agent is not synchronized Casino.',
		    @ErrCode = 113	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return	
    END 

    --Check SyncBingo between Agent AND Member 
    IF @aSyncBingo = 0 AND @SyncBingo = 1 
    BEGIN
	    SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': member is synchronized Bingo but new agent is not synchronized Bingo.',
		    @ErrCode = 114	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return	
    END 

    --Check Bingo & Number enable status:
    IF @adisableBingo = 1 AND @disableBingo = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Bingo but new agent is not enabled Bingo.',
		    @ErrCode = 115					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    IF @adisableNumber = 1 AND @disableNumber = 0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Number Game but new agent is not enabled Number Game.',
		    @ErrCode = 116
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    IF @adisableHRFixedOdds = 1 AND @disableHRFixedOdds = 0
	BEGIN
		SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Horse Racing Fixed Odds but new agent is not enabled Horse Racing Fixed Odds'
		     , @ErrCode = 118
		RETURN
    END

    --E-Sports
    IF @aDisableEsports = 1 AND @DisableEsports = 0
	BEGIN
		SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled E-Sports but new agent is not enabled E-Sports.'
		     , @ErrCode = 120
		RETURN
    END
	
	--Super Live
    IF @aDisableSuperLive = 1 AND @DisableSuperLive = 0
	BEGIN
		SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is enabled Super Live but new agent is not enabled Super Live.'
		     , @ErrCode = 121
		RETURN
    END
	    	
    IF @aSyncLiveCasino = 0 AND @SyncLiveCasino = 1
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is synchronized Live Casino but new agent is not synchronized Live Casino.'
	         , @ErrCode = 117
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
    END

    ----------------------------------
    --Check Horse, Casino sync status:
    IF exists(SELECT 1 FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND sporttype = 151)
	    AND not exists(SELECT 1 FROM custsetting3rd WITH(NOLOCK) WHERE custid = @recommend AND sporttype = 151)
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Horse Racing setting.',
		    @ErrCode = 201					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --number game
    IF exists(SELECT 1 FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND sporttype = 161)
	    AND not exists(SELECT 1 FROM custsetting3rd WITH(NOLOCK) WHERE custid = @recommend AND sporttype = 161)
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Number Game setting.',
		    @ErrCode = 202				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    IF exists(SELECT 1 FROM custinfo WITH(NOLOCK) WHERE custid = @custid AND SyncCasino = 1)
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already Casino-synchronized.',
		    @ErrCode = 203					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --bingo
    IF exists(SELECT 1 FROM custinfo WITH(NOLOCK) WHERE custid = @custid AND SyncBingo = 1)
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already Bingo-synchronized.',
		    @ErrCode = 204					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END
    --live casino
    IF EXISTS (SELECT 1 FROM CustInfo WITH(NOLOCK) WHERE custid = @custid AND SyncLiveCasino = 1)
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': member is already live Casino-synchronized.',
		    @ErrCode = 205					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --VS
    IF exists(SELECT 1 FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND sporttype = 180)
	    AND not exists(SELECT 1 FROM custsetting3rd WITH(NOLOCK) WHERE custid = @recommend AND sporttype = 180)

    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': agent does not have Virtual Sports setting.',
		    @ErrCode = 206					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check identical auto master position taking
    IF exists (
	    SELECT 1 FROM 
		    custsetting as acs_old WITH(NOLOCK)
		    inner join custsetting as acs_new WITH(NOLOCK) on acs_old.sporttype=acs_new.sporttype AND acs_old.bettype=acs_new.bettype						
	    where
		    acs_old.custid = @recommend_old AND  acs_new.custid = @recommend
		    and(	acs_old.isautompositiontaking <> acs_new.isautompositiontaking
				    or acs_old.isautolivempositiontaking <> acs_new.isautolivempositiontaking
		    )
    )
    BEGIN
    	
	    SELECT @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		    @ErrCode = 300					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END
    
    --Check for DCS products
    IF exists (
	    SELECT 1 FROM 
		    dbo.CustPTSetting3rd_Agent acs_old WITH(NOLOCK)
		    INNER JOIN dbo.CustPTSetting3rd_Agent acs_new WITH(NOLOCK) 
				ON acs_old.sporttype=acs_new.sporttype 
					AND acs_old.bettype=acs_new.bettype
					AND acs_old.IsLive=acs_new.IsLive
					AND acs_new.custid = @recommend							
	    where
		    acs_old.custid = @recommend_old  
		    AND acs_old.IsAutoMasterPT <> acs_new.IsAutoMasterPT
    )
    BEGIN
    	
	    SELECT @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		    @ErrCode = 9114					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END
    

    --Check identical auto master position taking 3rd
    IF exists (
	    SELECT 1 FROM 
		    custsetting3rd as acs_old WITH(NOLOCK)
		    inner join custsetting3rd as acs_new WITH(NOLOCK) on acs_old.sporttype=acs_new.sporttype AND acs_old.bettype=acs_new.bettype						
	    WHERE 
		    acs_old.custid = @recommend_old AND  acs_new.custid = @recommend
		    and	( (acs_old.isautompositiontaking <> acs_new.isautompositiontaking AND acs_new.sporttype <> 201)
			    or acs_old.isautolivempositiontaking <> acs_new.isautolivempositiontaking
		    )
    )
    BEGIN
    	
	    SELECT @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		    @ErrCode = 301					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

    --Check identical auto master position taking for live casino, keno, Gold Deluxe
    IF EXISTS (
		    SELECT 1
		    FROM CustSettingGame acs_old WITH(NOLOCK) 
			    INNER JOIN CustSettingGame acs_new WITH(NOLOCK) ON acs_new.custid = @recommend AND acs_new.sporttype = acs_old.sporttype AND acs_new.bettype = acs_old.bettype
		    WHERE acs_old.custid = @recommend_old AND acs_old.sporttype in (162,202, 255) AND (acs_old.bettype = 1101 OR acs_old.bettype between 1501 AND 1599 OR acs_old.Bettype = 1701)
			    AND acs_old.isautompositiontaking <> acs_new.isautompositiontaking
	    )
    BEGIN
	    SELECT @ErrMsg = 'Error agent ' + @agentname + ': Auto Mater Position Taking of new agent is not matched with old agent.',
		    @ErrCode = 302					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END

	 -- Check Myanmar odds
	DECLARE @IsMyanmarOdds_source BIT = 0
	DECLARE @IsMyanmarOdds_destination BIT = 0
	
	SET @IsMyanmarOdds_destination = dbo.fn_IsMyanmarOdds (@srecommend)
	SET @IsMyanmarOdds_source = dbo.fn_IsMyanmarOdds (@srecommend_old)
	
	IF @IsMyanmarOdds_source <> @IsMyanmarOdds_destination
	BEGIN
		SELECT @ErrMsg = 'Cannot move customer ' + @agentname + ' since amongs its new and old sites, one has % Odds.',
					@ErrCode = 218
		RETURN	
	END	
	
	DECLARE @playerDiscount_Source_MO DECIMAL(9,8) = 0
	DECLARE @discount_Destination_MO DECIMAL(9,8) = 0
	DECLARE @adiscount_Destination_MO DECIMAL(9,8) = 0
	DECLARE @sdiscount_Destination_MO DECIMAL(9,8) = 0
	
	IF @IsMyanmarOdds_source = 1
	BEGIN
		
		SET @discount_Destination_MO = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @recommend AND Sporttype = 1 AND Bettype = 301 )	
		SET @playerDiscount_Source_MO = (SELECT playerdiscount FROM CustCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 301)	
						
		IF @discount_Destination_MO < @playerDiscount_Source_MO 
		BEGIN
			SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': Master''s commission for Mysanmar Odds is less than moved member''s commision.',
					@ErrCode = 219
			RETURN	
		END
	END

	--Check Position Taking for DCS products --all us1<=s4 if is1 = 1
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustPTSetting3rd_Agent scs WITH (NOLOCK)
			LEFT JOIN dbo.CustPTSetting3rd_Member mem WITH (NOLOCK)
				ON scs.SportType = mem.sporttype  
					AND scs.BetType = mem.bettype
					AND scs.IsLive = mem.IsLive
					AND mem.CustID = @custid 
			LEFT JOIN dbo.CustPTGroupSetting3rd_Member memg WITH (NOLOCK)
				ON scs.SportType = memg.sporttype  
					AND scs.BetType = memg.bettype
					AND scs.IsLive = memg.IsLive
					AND memg.AgentID = @recommend_old 
		WHERE scs.CustID  = @srecommend
			AND ISNULL(mem.IsAutoSuperPT,memg.IsAutoSuperPT) = 1
			AND ISNULL(mem.AutoSuperPT,memg.AutoSuperPT) > scs.SuperPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': Member exceeded new super position taking.',
			@ErrCode = 9115			 
		
		 IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
	END
	
	--Check Position Taking for DCS products --all um1<=m3 if im1 = 1
	IF EXISTS (SELECT TOP 1 1
		FROM dbo.CustPTSetting3rd_Agent mcs WITH (NOLOCK)
			LEFT JOIN dbo.CustPTSetting3rd_Member mem WITH (NOLOCK)
				ON mcs.SportType = mem.sporttype  
					AND mcs.BetType = mem.bettype
					AND mcs.IsLive = mem.IsLive
					AND mem.CustID = @custid 
			LEFT JOIN dbo.CustPTGroupSetting3rd_Member memg WITH (NOLOCK)
				ON mcs.SportType = memg.sporttype  
					AND mcs.BetType = memg.bettype
					AND mcs.IsLive = memg.IsLive
					AND memg.AgentID = @recommend_old 
		WHERE mcs.CustID  = @mrecommend
			AND ISNULL(mem.IsAutoMasterPT,memg.IsAutoMasterPT) = 1
			AND ISNULL(mem.AutoMasterPT,memg.AutoMasterPT) > mcs.MasterPT
		)
	BEGIN
		SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': Member exceeded new master position taking.',
			@ErrCode = 9118			 
		
		 IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    RETURN
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
    --	SELECT @ErrMsg = 'Error agent ' + @agentname + ', member ' + @membername + ': P2P''s commission of member is greater than P2P''s commission of new agent .',
    --		@ErrCode = 303
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

	    --@v201apositiontaking_2 SMALLMONEY,
	    --@v201apositiontaking_3 SMALLMONEY,
    	
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
	    
	    @v154apositiontaking_20 SMALLMONEY,
    	
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
	    @v162apositiontaking_1101 SMALLMONEY, 
	    --VS
	    @v180apositiontaking_1201 SMALLMONEY,
	    @v181apositiontaking_1231 SMALLMONEY,
	    @v182apositiontaking_1231 SMALLMONEY,
	    @v183apositiontaking_1231 SMALLMONEY,
	    @v184apositiontaking_1231 SMALLMONEY,
	    @v185apositiontaking_1231 SMALLMONEY,
	    @v186apositiontaking_1220 SMALLMONEY,

	    --Keno
	    @v202apositiontaking_1501 SMALLMONEY,
	    @v202apositiontaking_1511 SMALLMONEY,
	    @v202apositiontaking_1503 SMALLMONEY,
	    @v202apositiontaking_1504 SMALLMONEY,
	    @v202apositiontaking_1505 SMALLMONEY,
	    @v202apositiontaking_1513 SMALLMONEY,
	    @v202apositiontaking_1507 SMALLMONEY,
	    @v202apositiontaking_1508 SMALLMONEY,
	    @v202apositiontaking_1509 SMALLMONEY,
	    @v202apositiontaking_1514 SMALLMONEY,
	    
	    -- Gold Deluxe
	    @v255apositiontaking_1701 SMALLMONEY,
	    @PTXML						XML, --DCS
	    @IsGrouped				BIT 
	    
	SELECT @IsGrouped = IsGrouped
	FROM dbo.CustSettingMode3rd WITH(NOLOCK)
	WHERE CustID = @custid
	
	IF ISNULL(@IsGrouped,0) = 1
	BEGIN
		INSERT INTO dbo.CustPTSetting3rd_Member  
		SELECT  
			@CustID,  
			grpt.SportType,  
			grpt.BetType,  
			grpt.IsLive,  
			grpt.SuperPT,  
			grpt.MasterPT,  
			grpt.AgentPT,  
			grpt.IsAutoMasterPT,  
			grpt.AutoMasterPT,  
			grpt.IsAutoSuperPT,  
			grpt.AutoSuperPT  
		FROM dbo.CustPTGroupSetting3rd_Member grpt WITH(NOLOCK)  
			LEFT JOIN dbo.CustPTSetting3rd_Member mempt  
			ON mempt.CustID = @CustID  
			AND grpt.SportType=mempt.SportType  
			AND grpt.BetType=mempt.BetType  
			AND grpt.IsLive=mempt.IsLive  
		WHERE grpt.AgentID=@recommend_old AND mempt.CustID IS NULL  
		
		UPDATE dbo.CustSettingMode3rd WITH(ROWLOCK,UPDLOCK)  
		SET IsGrouped = 0  
		WHERE CustID = @CustID  
	END
       
	--GET a1 of DCS Products
	SET @xml = (
			SELECT (
					SELECT SportType	AS '@SportType'
						, BetType		AS '@BetType'
						, IsLive		AS '@IsLive'
						, AgentPT		AS '@AgentPT'
					FROM dbo.CustPTSetting3rd_Member WITH(NOLOCK)
					WHERE custid = @custid
					FOR XML PATH('PT')
						, TYPE
					)
			FOR XML PATH('ROOT')
				, TYPE
			)


    SELECT @apositiontaking_1 = apositiontaking, @alivepositiontaking_1 = alivepositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=1
    SELECT @apositiontaking_3 = apositiontaking, @alivepositiontaking_3 = alivepositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=1
    SELECT @apositiontaking_7 = apositiontaking, @alivepositiontaking_7 = alivepositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=1
    SELECT @apositiontaking_8 = apositiontaking, @alivepositiontaking_8 = alivepositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=1
    SELECT @apositiontaking_2 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=1
    SELECT @apositiontaking_4 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=4 AND sporttype=1
    SELECT @apositiontaking_5 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=5 AND sporttype=1
    SELECT @apositiontaking_6 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=6 AND sporttype=1
    SELECT @apositiontaking_9 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=1
    SELECT @apositiontaking_10 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=10 AND sporttype=1

    SELECT @v2apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=2
    SELECT @v2apositiontaking_2 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=2
    SELECT @v2apositiontaking_3 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=2
    SELECT @v2apositiontaking_7 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=7 AND sporttype=2
    SELECT @v2apositiontaking_8 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=8 AND sporttype=2
    --SELECT @v2apositiontaking_9 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=2
    SELECT @v2apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=2

    SELECT @v3apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=3
    SELECT @v3apositiontaking_2 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=3
    SELECT @v3apositiontaking_3 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=3
    SELECT @v3apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=3

    SELECT @v5apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=5
    SELECT @v5apositiontaking_2 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=5
    SELECT @v5apositiontaking_3 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=5
    SELECT @v5apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=5

    SELECT @v8apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=8
    SELECT @v8apositiontaking_3 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=8
    SELECT @v8apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=8

    SELECT @v10apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=10
    SELECT @v10apositiontaking_2 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=10
    SELECT @v10apositiontaking_3 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=10
    SELECT @v10apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=10

    SELECT @v11apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=11
    SELECT @v11apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=11

    SELECT @v99apositiontaking_1 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=1 AND sporttype=99
    SELECT @v99apositiontaking_2 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=99
    SELECT @v99apositiontaking_3 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=99
    SELECT @v99apositiontaking_9 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=9 AND sporttype=99
    SELECT @v99apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=99
    
    SELECT @v154apositiontaking_20 = apositiontaking FROM custsetting WITH(NOLOCK) WHERE custid = @custid AND bettype=20 AND sporttype=154

    --SELECT @v201apositiontaking_2 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=2 AND sporttype=201
    --SELECT @v201apositiontaking_3 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=3 AND sporttype=201

    SELECT @v151apositiontaking_31 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=31 AND sporttype=151
    SELECT @v151apositiontaking_32 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=32 AND sporttype=151
    SELECT @v151apositiontaking_41 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=151
    SELECT @v151apositiontaking_42 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=151
    SELECT @v151apositiontaking_51 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=151
    SELECT @v151apositiontaking_52 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=151
    SELECT @v152apositiontaking_41 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=41 AND sporttype=152
    SELECT @v152apositiontaking_42 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=42 AND sporttype=152
    SELECT @v152apositiontaking_51 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=152
    SELECT @v152apositiontaking_52 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=152
    SELECT @v153apositiontaking_51 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=51 AND sporttype=153
    SELECT @v153apositiontaking_52 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=52 AND sporttype=153
    

    SELECT @v161apositiontaking_81 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=81 AND sporttype=161
    SELECT @v161apositiontaking_83 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=83 AND sporttype=161
    --SELECT @v161apositiontaking_85 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=85 AND sporttype=161
    SELECT @v161apositiontaking_86 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=86 AND sporttype=161
    SELECT @v161apositiontaking_88 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=88 AND sporttype=161

    SELECT @v161alivepositiontaking_85 = alivepositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=85 AND sporttype=161
    SELECT @v161alivepositiontaking_86 = alivepositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=86 AND sporttype=161
    SELECT @v161alivepositiontaking_87 = alivepositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=87 AND sporttype=161
    SELECT @v161alivepositiontaking_89 = alivepositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=89 AND sporttype=161
    SELECT @v161alivepositiontaking_90 = alivepositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=90 AND sporttype=161

    SELECT @v162apositiontaking_1101 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 162 AND bettype = 1101

    SELECT @v180apositiontaking_1201 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1201 AND sporttype=180
    SELECT @v181apositiontaking_1231 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1231 AND sporttype=181
    SELECT @v182apositiontaking_1231 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1231 AND sporttype=182
    SELECT @v183apositiontaking_1231 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1231 AND sporttype=183
    SELECT @v184apositiontaking_1231 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1231 AND sporttype=184
    SELECT @v185apositiontaking_1231 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1231 AND sporttype=185
    SELECT @v186apositiontaking_1220 = apositiontaking FROM custsetting3rd WITH(NOLOCK) WHERE custid = @custid AND bettype=1220 AND sporttype=186

    --Keno
    SELECT @v202apositiontaking_1501 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1501
    SELECT @v202apositiontaking_1511 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1511
    SELECT @v202apositiontaking_1503 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1503
    SELECT @v202apositiontaking_1504 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1504
    SELECT @v202apositiontaking_1505 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1505
    SELECT @v202apositiontaking_1513 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1513
    SELECT @v202apositiontaking_1507 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1507
    SELECT @v202apositiontaking_1508 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1508
    SELECT @v202apositiontaking_1509 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1509
    SELECT @v202apositiontaking_1514 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 202 AND bettype = 1514
    
    -- Gold Deluxe
    SELECT @v255apositiontaking_1701 = apositiontaking FROM CustSettingGame WITH(NOLOCK) WHERE custid = @custid AND sporttype = 255 AND bettype = 1701

    print  'Move member '+@membername+' FROM agent id '+convert(VARCHAR(20), @recommend_old)+' to agent '+@agentname+' (id ' + convert(VARCHAR(20), @recommend)+')'

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
    --					@ErrCode = 500
    --		RETURN
    --	END

    --IF (@aDisableP2P = 1 AND @DisableP2P = 0) 
    --	OR (@aIsAutoResetP2P = 0 AND @IsAutoResetP2P = 1)
    --	OR (@aDisableFunP2P = 1 AND @DisableFunP2P = 0)
    --	OR (@aMaxTransferP2P < @MaxTransferP2P)
    --	OR (@aDisableVirtualSports = 1 AND @DisableVirtualSports = 0)
    --	OR (@aDoubleCommLosing = 0 AND @DoubleCommLosing = 1)
    --BEGIN
    --	UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
    --	SET		DisableP2P = CASE WHEN @aDisableP2P = 1 THEN 1 ELSE DisableP2P END,
    --			DisableFunP2P = CASE WHEN @aIsAutoResetP2P = 1 THEN 1 ELSE DisableFunP2P END,
    --			IsAutoResetP2P = CASE WHEN @aDisableFunP2P = 0 THEN 0 ELSE IsAutoResetP2P END,
    --			MaxTransferP2P = CASE WHEN @aMaxTransferP2P < MaxTransferP2P THEN @aMaxTransferP2P ELSE MaxTransferP2P END,
    --			DisableVirtualSports = CASE WHEN @aDisableVirtualSports = 1 THEN 1 ELSE DisableVirtualSports END ,
    --			DoubleCommLosing = CASE WHEN @aDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
    --	WHERE	custid = @CustID
    --	IF @@ERROR <>0
    --	BEGIN
    --		Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
    --				@ErrCode = 501
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
    --				@ErrCode = 502
    --	RETURN
    --END

    IF (@aDoubleCommLosing = 0 AND @DoubleCommLosing = 1)
    BEGIN
	    UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	    SET		DoubleCommLosing = CASE WHEN @aDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
	    WHERE	custid = @CustID
	    IF @@ERROR <>0
	    BEGIN
		    Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				    @ErrCode = 501
		    RETURN 
	    END
    END

    --customer table
    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend, mrecommend = @mrecommend,
											    recommend = @recommend
    WHERE custid = @custid
    IF @@Error <> 0 
    BEGIN
    	
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid

	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (customer).',
		    @ErrCode = 503				 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
    	
	    return
    END

    --custinfo table
    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend, mrecommend = @mrecommend,
											    recommend = @recommend
    WHERE custid = @custid
    IF @@Error <> 0 
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid

	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		    @ErrCode = 504					 
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
    	
	    return
    END

    EXEC dbo.Acc_CustomerUpdMember_PositionTaking 
	    @custid = @custid,
	    @apositiontaking_1 = @apositiontaking_1,
	    @apositiontaking_2 = @apositiontaking_2,
	    @apositiontaking_3 = @apositiontaking_3,
	    @apositiontaking_4 = @apositiontaking_4,
	    @apositiontaking_5 = @apositiontaking_5,
	    @apositiontaking_6 = @apositiontaking_6,
	    @apositiontaking_7 = @apositiontaking_7,
	    @apositiontaking_8 = @apositiontaking_8,
	    @apositiontaking_9 = @apositiontaking_9,
	    @apositiontaking_10 = @apositiontaking_10,
	    @alivepositiontaking_1 = @alivepositiontaking_1,
	    @alivepositiontaking_3 = @alivepositiontaking_3,
	    @alivepositiontaking_7 = @alivepositiontaking_7,
	    @alivepositiontaking_8 = @alivepositiontaking_8,
	    @v2apositiontaking_1 = @v2apositiontaking_1,
	    @v2apositiontaking_2 = @v2apositiontaking_2,
	    @v2apositiontaking_3 = @v2apositiontaking_3,
	    @v2apositiontaking_7 = @v2apositiontaking_7,
	    @v2apositiontaking_8 = @v2apositiontaking_8,
	    --@v2apositiontaking_9 = @v2apositiontaking_9,
	    @v2apositiontaking_20 = @v2apositiontaking_20,
	    @v3apositiontaking_1 = @v3apositiontaking_1,
	    @v3apositiontaking_2 = @v3apositiontaking_2,
	    @v3apositiontaking_3 = @v3apositiontaking_3,
	    @v3apositiontaking_20 = @v3apositiontaking_20,
	    @v5apositiontaking_1 = @v5apositiontaking_1,
	    @v5apositiontaking_2 = @v5apositiontaking_2,
	    @v5apositiontaking_3 = @v5apositiontaking_3,
	    @v5apositiontaking_20 = @v5apositiontaking_20,
	    @v8apositiontaking_1 = @v8apositiontaking_1,
	    @v8apositiontaking_3 = @v8apositiontaking_3,
	    @v8apositiontaking_20 = @v8apositiontaking_20,
	    @v10apositiontaking_1 = @v10apositiontaking_1,
	    @v10apositiontaking_2 = @v10apositiontaking_2,
	    @v10apositiontaking_3 = @v10apositiontaking_3,
	    @v10apositiontaking_20 = @v10apositiontaking_20,
	    @v11apositiontaking_1 = @v11apositiontaking_1,
	    @v11apositiontaking_20 = @v11apositiontaking_20,	
	    @v99apositiontaking_1 = @v99apositiontaking_1,
	    @v99apositiontaking_2 = @v99apositiontaking_2,
	    @v99apositiontaking_3 = @v99apositiontaking_3,
	    @v99apositiontaking_9 = @v99apositiontaking_9,
	    @v99apositiontaking_20 = @v99apositiontaking_20,
	    @v154apositiontaking_20 = @v154apositiontaking_20,
	    @v161apositiontaking_81 = @v161apositiontaking_81,   
	    @v161apositiontaking_83 = @v161apositiontaking_83,   
	    --@v161apositiontaking_85 = @v161apositiontaking_85,   
	    @v161apositiontaking_86 = @v161apositiontaking_86,   
	    @v161apositiontaking_88 = @v161apositiontaking_88,  
    	  
	    @v161alivepositiontaking_85 = @v161alivepositiontaking_85,  
	    @v161alivepositiontaking_86 = @v161alivepositiontaking_86, 
	    @v161alivepositiontaking_87 = @v161alivepositiontaking_87,
	    @v161alivepositiontaking_89 = @v161alivepositiontaking_89,  
	    @v161alivepositiontaking_90 = @v161alivepositiontaking_90,
    	
	    @UserID = @UserID,
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

	--Update a1 for DCS products
	IF CAST(@xml as NVARCHAR(MAX)) = '<ROOT/>'
	BEGIN
		 --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
	END
	ELSE
	BEGIN
		DECLARE @xmlVarchar NVARCHAR(MAX) = CAST(@xml AS NVARCHAR(MAX))
		EXEC [dbo].[Acc_CustSetting_AgentPTOnMemberUpd] 
			  @CustID			= @custid
			, @PT				= @xmlVarchar
			, @UserID			= @UserID
			, @ErrCode			= @ErrCode	OUTPUT
			, @ErrMsg			= @ErrMsg	OUTPUT
			
		IF @ErrCode > 0
		BEGIN
			--ROLLBACK TRANSACTION MANUALLY
			update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
													recommend = @recommend_old
			WHERE custid = @custid
	    	
			update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
													recommend = @recommend_old
			WHERE custid = @custid
	    	
			IF @ReturnErrCode = 0
				RAISERROR(@ErrMsg, 16, 1)	
			return
		END
	END
	
    EXEC dbo.Acc_CustomerUpdMemberHR_PositionTaking 
	    @custid = @custid,
	    @v151apositiontaking_31 = @v151apositiontaking_31,
	    @v151apositiontaking_32 = @v151apositiontaking_32,
	    @v151apositiontaking_41 = @v151apositiontaking_41,
	    @v151apositiontaking_42 = @v151apositiontaking_42,
	    @v151apositiontaking_51 = @v151apositiontaking_51,
	    @v151apositiontaking_52 = @v151apositiontaking_52,
	    @v152apositiontaking_41 = @v152apositiontaking_41,
	    @v152apositiontaking_42 = @v152apositiontaking_42,
	    @v152apositiontaking_51 = @v152apositiontaking_51,
	    @v152apositiontaking_52 = @v152apositiontaking_52,
	    @v153apositiontaking_51 = @v153apositiontaking_51,
	    @v153apositiontaking_52 = @v153apositiontaking_52,
	    @UserID = @UserID,
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg = @ErrMsg OUTPUT

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    EXEC dbo.Acc_CustomerUpdMemberLiveCS_Positiontaking
	    @custid  = @custid,
	    @v162apositiontaking_1101 = @v162apositiontaking_1101,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- VS
    DECLARE @ErrCode_1 VARCHAR(300)

    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 180,
	    @bettype = 1201 ,
	    @a1 = @v180apositiontaking_1201,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- Virtual HR
    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 181,
	    @bettype = 1231 ,
	    @a1 = @v181apositiontaking_1231,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- 182
    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 182,
	    @bettype = 1231 ,
	    @a1 = @v182apositiontaking_1231,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END


    -- 183
    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 183,
	    @bettype = 1231 ,
	    @a1 = @v183apositiontaking_1231,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- 184
    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 184,
	    @bettype = 1231 ,
	    @a1 = @v184apositiontaking_1231,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- 185
    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 185,
	    @bettype = 1231 ,
	    @a1 = @v185apositiontaking_1231,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- Virtual Tennis
    EXEC dbo.Acc_CustomerUpdMemberVS_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 186,
	    @bettype = 1220,
	    @a1 = @v186apositiontaking_1220,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode_1 OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF CHARINDEX('-101', @ErrCode_1) = 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    -- Keno
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1501,
	    @a1 = @v202apositiontaking_1501,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END

    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1511,
	    @a1 = @v202apositiontaking_1511,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1503,
	    @a1 = @v202apositiontaking_1503,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1504,
	    @a1 = @v202apositiontaking_1504,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1505,
	    @a1 = @v202apositiontaking_1505,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1513,
	    @a1 = @v202apositiontaking_1513,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1507,
	    @a1 = @v202apositiontaking_1507,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1508,
	    @a1 = @v202apositiontaking_1508,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1509,
	    @a1 = @v202apositiontaking_1509,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
	
	EXEC dbo.Acc_CustomerUpdMemberKeno_Positiontaking
	    @custid  = @custid,
	    @sporttype	= 202,
	    @bettype = 1514,
	    @a1 = @v202apositiontaking_1514,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
	    return
    END
    
      -- Gold Deluxe
        EXEC dbo.Acc_CustomerUpdMemberGoldDeluxe_Positiontaking
	    @custid  = @custid,
	    @v255apositiontaking_1701 = @v255apositiontaking_1701,
    	
	    @UserID	= @UserID,	
	    @ErrCode = @ErrCode OUTPUT,
	    @ErrMsg	 = @ErrMsg OUTPUT	

    IF @ErrCode > 0
    BEGIN
	    --ROLLBACK TRANSACTION MANUALLY
	    update customer with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    update custinfo with (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old, mrecommend = @mrecommend_old,
											    recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)	
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
		    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		    @ErrCode = 505
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
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
		    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		    @ErrCode = 506
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
	    END 
    END 

    --Keno
    IF @aHideKeno = 0 AND (@aHideKeno <> @HideKeno)
    BEGIN
	    UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	    SET		HideKeno = 0
	    WHERE	custid = @custid 
	    IF @@ERROR <>0
	    BEGIN
		    Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				    @ErrCode = 507
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    RETURN 
	    END
    END
    
     --Gold Deluxe
    --IF @aHideGoldDeluxe = 0 AND (@aHideGoldDeluxe <> @HideGoldDeluxe)
    --BEGIN
	   -- UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	   -- SET		HideGoldDeluxe = 0
	   -- WHERE	custid = @custid 
	   -- IF @@ERROR <>0
	   -- BEGIN
		  --  Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				--    @ErrCode = 507
		  --  IF @ReturnErrCode = 0
			 --   RAISERROR(@ErrMsg, 16, 1)
		  --  RETURN 
	   -- END
    --END
    
    --Gold Deluxe
    IF @aDisableGoldDeluxe = 0 AND (@aDisableGoldDeluxe <> @DisableGoldDeluxe)
    BEGIN
	    UPDATE	Custinfo WITH (UPDLOCK,ROWLOCK)
	    SET		DisableGoldDeluxe = 0
	    WHERE	custid = @custid 
	    IF @@ERROR <>0
	    BEGIN
		    Select	@ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
				    @ErrCode = 507
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    RETURN 
	    END
    END

	----Update productstus for DCS
	--DECLARE @xmlStrDisabled XML
	--DECLARE @xmlStrHidden XML

	--SET @xmlStrDisabled =(
	--			SELECT (
	--					SELECT stt.bitmapOrder	AS '@b'
	--						, 1	AS '@s'
	--					FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
	--						INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
	--						INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @custid
	--					WHERE dbo.f_GetProductStatus(m.bitmapIsDisabled, stt.bitmapOrder) = 0
	--							AND dbo.f_GetProductStatus(a.bitmapIsDisabled, stt.bitmapOrder) = 1
		
	--					FOR XML PATH('r')
	--						, TYPE
	--					)
	--			FOR XML PATH('root')
	--				, TYPE
	--			)

	--IF CONVERT(VARCHAR(MAX),@xmlStrDisabled) <> '<root/>'
	--BEGIN
	--	UPDATE CustProductStatus
	--		SET bitmapIsDisabled = (SELECT bitmap FROM dbo.f_GenerateProductStatus_multiple (bitmapIsDisabled, CONVERT(VARCHAR(MAX),@xmlStrDisabled)))	
	--	WHERE	custid = @custid
	--	IF @@ERROR <>0
	--	BEGIN
	--		SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': update unsuccessfully (custinfo).',
	--				@ErrCode = 9116
	--		RETURN 
	--	END
	--END

	--SET @xmlStrHidden =(
	--			SELECT (
	--					SELECT stt.bitmapOrder	AS '@b'
	--						, 0	AS '@s'
	--					FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
	--						INNER JOIN dbo.CustProductStatus a WITH(NOLOCK)ON a.CustID = @recommend
	--						INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @custid
	--					WHERE dbo.f_GetProductStatus(m.bitmapIsHidden, stt.bitmapOrder) = 1
	--							AND dbo.f_GetProductStatus(a.bitmapIsHidden, stt.bitmapOrder) = 0
		
	--					FOR XML PATH('r')
	--						, TYPE
	--					)
	--			FOR XML PATH('root')
	--				, TYPE
	--			)

	--IF CONVERT(VARCHAR(MAX),@xmlStrHidden) <> '<root/>'
	--BEGIN
	--	UPDATE CustProductStatus
	--		SET bitmapIsHidden = (SELECT bitmap FROM dbo.f_GenerateProductStatus_multiple (bitmapIsHidden, CONVERT(VARCHAR(MAX),@xmlStrHidden)))	
	--	WHERE	custid = @custid
	--	IF @@ERROR <>0
	--	BEGIN
	--		SELECT @ErrMsg = 'Error Agent ' + @agentname + ', member ' + @membername + ': update unsuccessfully (custinfo).',
	--				@ErrCode = 9117
	--		RETURN 
	--	END
	--END
	
    UPDATE	cg WITH (UPDLOCK,ROWLOCK)
    SET		cg.IsDisabled = 1 
    FROM CustGameType acg WITH(NOLOCK) 
	    INNER JOIN CustGameType cg ON acg.CustID = @recommend AND acg.GameTypeID = cg.GameTypeID
    WHERE	cg.custid = @custid AND acg.IsDisabled = 1 AND cg.IsDisabled = 0
    IF @@ERROR<>0
    BEGIN
	    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
	    @ErrCode = 508
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)
	    return
    END 
    
  

    /*
    --Bingo & Number Game
    IF @aDisableBingo = 1 AND (@aDisableBingo <> @DisableBingo)
    BEGIN 

	    UPDATE Custinfo WITH (UPDLOCK,ROWLOCK)
	    SET DisableBingo = 1 
	    WHERE custid = @custid 
	    IF @@ERROR<>0
	    BEGIN
		    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		    @ErrCode = 136
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
	    END 
    END 

    IF @aDisableNumber = 1 AND (@aDisableNumber <> @DisableNumber)
    BEGIN 

	    UPDATE Custinfo WITH (UPDLOCK,ROWLOCK)
	    SET DisableNumber = 1 
	    WHERE custid = @custid 
	    IF @@ERROR<>0
	    BEGIN
		    SELECT @ErrMsg = 'Error member ' + @membername + ', agent ' + @agentname + ': update unsuccessfully (custinfo).',
		    @ErrCode = 137
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
	    END 
    END 
    */

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
	    -- 20130808@Elodie: Splitting DBTXN INTo DBCUST (Roll back updates on custinfo,customer table in main SP)  				
	    --ROLLBACK TRANSACTION MANUALLY     
        UPDATE customer WITH (ROWLOCK, UPDLOCK) 
        SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	    WHERE custid = @custid
    	
	    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
	    SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)                  
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
	    -- 20130808@Elodie: Splitting DBTXN INTo DBCUST (Roll back updates on custinfo,customer table in main SP)  				
	    --ROLLBACK TRANSACTION MANUALLY     
        UPDATE customer WITH (ROWLOCK, UPDLOCK) 
        SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	    WHERE custid = @custid
    	
	    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) 
	    SET srecommend = @srecommend_old, mrecommend = @mrecommend_old, recommend = @recommend_old
	    WHERE custid = @custid
    	
	    IF @ReturnErrCode = 0
		    RAISERROR(@ErrMsg, 16, 1)                  
        RETURN
    END	

    --Update Member's Comm
    DECLARE	@ugroup VARCHAR(5)
    SELECT	@ugroup= ugroup FROM Customer WITH(NOLOCK) WHERE custid = @custid
    --super 
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		sdiscount = CASE WHEN scs.bettype IN (1,2,3,7,8) 
								    THEN( case	when @ugroup in ('a','hka','dea') then scs.groupa 
											    when @ugroup in ('b','hkb','deb') then scs.groupb  
											    when @ugroup in ('c','hkc','dec') then scs.groupc  
											    when @ugroup in ('d','hkd','ded') then scs.groupd
											    else scs.sdiscount end)
						     ELSE scs.sdiscount END 
    FROM	CustSetting scs WITH(NOLOCK)
		    INNER JOIN CustSetting cs ON scs.custid = @srecommend AND cs.custid = @custid 
										    AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
    WHERE	(scs.bettype in (1,2,3,7,8) 
			    and	cs.sdiscount > case	when @ugroup in ('a','hka','dea') then scs.groupa 
									    when @ugroup in ('b','hkb','deb') then scs.groupb  
									    when @ugroup in ('c','hkc','dec') then scs.groupc  
									    when @ugroup in ('d','hkd','ded') then scs.groupd
									    else scs.sdiscount end)
		    or (scs.bettype not in (1,2,3,7,8) AND scs.sdiscount< cs.sdiscount)

    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update super commission unsuccessfully.',
		    @ErrCode = 506					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

	--Correct commission for DCS products
	UPDATE cs
	SET cs.SuperDiscount = scs.Discount
	FROM dbo.CustDiscount3rd_Member cs 
		INNER JOIN dbo.CustDiscount3rd_Agent scs WITH(NOLOCK) 
			ON scs.custid = @srecommend 
				AND scs.sporttype = cs.sporttype
				AND scs.bettype = cs.bettype
	WHERE cs.custid = @custid
		AND ISNULL(cs.SuperDiscount, 0) > scs.Discount
	IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update super commission unsuccessfully.',
		    @ErrCode = 600			 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END
		
	UPDATE cs
	SET cs.MasterDiscount = mcs.Discount
	FROM dbo.CustDiscount3rd_Member cs 
		INNER JOIN dbo.CustDiscount3rd_Agent mcs WITH(NOLOCK) 
			ON mcs.custid = @mrecommend 
				AND mcs.sporttype = cs.sporttype
				AND mcs.bettype = cs.bettype
	WHERE cs.custid = @custid
		AND ISNULL(cs.MasterDiscount, 0) > mcs.Discount
	IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update master commission unsuccessfully.',
		    @ErrCode = 601					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END
		
	UPDATE cs
	SET cs.AgentDiscount = acs.Discount
	FROM dbo.CustDiscount3rd_Member cs 
		INNER JOIN dbo.CustDiscount3rd_Agent acs WITH(NOLOCK) 
			ON acs.custid = @recommend 
				AND acs.sporttype = cs.sporttype
				AND acs.bettype = cs.bettype
	WHERE cs.custid = @custid
		AND ISNULL(cs.AgentDiscount, 0) > acs.Discount
	IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update agent commission unsuccessfully.',
		    @ErrCode = 602					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

    --super 3rd

    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		sdiscount = scs.sdiscount
    FROM	CustSetting3rd scs WITH(NOLOCK)
		    INNER JOIN CustSetting3rd cs ON scs.custid = @srecommend AND cs.custid = @custid 
										    AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype 
    WHERE	scs.sdiscount< cs.sdiscount
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update super commission unsuccessfully.',
		    @ErrCode = 507				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END
    
    --live casino, Keno, gold deluxe

    UPDATE cs WITH(UPDLOCK,ROWLOCK)
    SET sdiscount = scs.sdiscount
    FROM CustSettingGame scs WITH(NOLOCK)
	    INNER JOIN CustSettingGame cs ON scs.custid = @srecommend AND scs.sporttype = cs.sporttype AND scs.bettype = cs.bettype
    WHERE cs.custid = @custid AND cs.sporttype in (162,202, 255) AND (cs.bettype = 1101 OR cs.bettype between 1501 AND 1599 OR cs.Bettype = 1701)
	    AND scs.sdiscount < cs.sdiscount

    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update super commission unsuccessfully.',
		    @ErrCode = 508				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

    --master
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		adiscount = CASE WHEN mcs.bettype IN (1,2,3,7,8) 
								    THEN (case	when @ugroup in ('a','hka','dea') then mcs.groupa 
											    when @ugroup in ('b','hkb','deb') then mcs.groupb  
											    when @ugroup in ('c','hkc','dec') then mcs.groupc  
											    when @ugroup in ('d','hkd','ded') then mcs.groupd
											    else mcs.adiscount end )
						      ELSE mcs.adiscount END 
    FROM	CustSetting mcs WITH(NOLOCK)
		    INNER JOIN CustSetting cs ON mcs.custid = @mrecommend AND cs.custid = @custid 
										    AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
    WHERE	(mcs.bettype in (1,2,3,7,8) 
			    and	cs.adiscount > case	when @ugroup in ('a','hka','dea') then mcs.groupa 
									    when @ugroup in ('b','hkb','deb') then mcs.groupb  
									    when @ugroup in ('c','hkc','dec') then mcs.groupc  
									    when @ugroup in ('d','hkd','ded') then mcs.groupd
									    else mcs.adiscount end)
		    or (mcs.bettype not in (1,2,3,7,8) AND mcs.adiscount< cs.adiscount)
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update master commission unsuccessfully.',
		    @ErrCode = 509					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

    --master 3rd
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		adiscount = mcs.adiscount 
    FROM	CustSetting3rd mcs WITH(NOLOCK)
		    INNER JOIN CustSetting3rd cs ON mcs.custid = @mrecommend AND cs.custid = @custid 
										    AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
    WHERE	mcs.adiscount< cs.adiscount
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update master commission unsuccessfully.',
		    @ErrCode = 510					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END
    --live casino, keno, gold deluxe
    UPDATE cs WITH(UPDLOCK,ROWLOCK) 
    SET adiscount = mcs.adiscount
    FROM CustSettingGame mcs WITH(NOLOCK) 
	    INNER JOIN CustSettingGame cs ON mcs.custid = @mrecommend AND mcs.sporttype = cs.sporttype AND mcs.bettype = cs.bettype 
    WHERE cs.custid = @custid AND cs.sporttype in (162,202, 255) AND (cs.bettype = 1101 OR cs.bettype between 1501 AND 1599 OR cs.Bettype = 1701)
	    AND mcs.adiscount < cs.adiscount

    IF @@ERROR <> 0
    BEGIN
	    SELECT @ErrMsg = 'update master commission unsuccessfully.',
		    @ErrCode = 511					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END
    --agent 
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		cs.discount = CASE	WHEN acs.bettype IN (1,2,3,7,8) 
									    THEN (case	when @ugroup in ('a','hka','dea') then acs.groupa 
												    when @ugroup in ('b','hkb','deb') then acs.groupb  
												    when @ugroup in ('c','hkc','dec') then acs.groupc  
												    when @ugroup in ('d','hkd','ded') then acs.groupd
												    else acs.discount end)
							    ELSE acs.discount END 
    FROM	CustSetting acs WITH(NOLOCK)
		    INNER JOIN CustSetting cs ON acs.custid = @recommend AND cs.custid = @custid 
										    AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
    WHERE	(acs.bettype in (1,2,3,7,8)  
			    and	cs.discount > case	when @ugroup in ('a','hka','dea') then acs.groupa 
									    when @ugroup in ('b','hkb','deb') then acs.groupb  
									    when @ugroup in ('c','hkc','dec') then acs.groupc  
									    when @ugroup in ('d','hkd','ded') then acs.groupd
									    else acs.discount end
		    )
		    or (acs.bettype not in (1,2,3,7,8) AND acs.discount< cs.discount)
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update agent commission unsuccessfully.',
		    @ErrCode = 512					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

    --agent 3rd
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		cs.discount = acs.discount
    FROM	CustSetting3rd acs WITH(NOLOCK)
		    INNER JOIN CustSetting3rd cs ON acs.custid = @recommend AND cs.custid = @custid 
										    AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
    WHERE	acs.discount< cs.discount
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update agent commission unsuccessfully.',
		    @ErrCode = 513					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

    --live casino, keno, gold deluxe
    UPDATE cs WITH(UPDLOCK,ROWLOCK) 
    SET cs.discount = acs.discount
    FROM CustSettingGame acs WITH(NOLOCK)
	    INNER JOIN CustSettingGame cs ON acs.custid = @recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
    WHERE cs.custid = @custid AND cs.sporttype in (162,202, 255) AND (cs.bettype = 1101 OR cs.bettype between 1501 AND 1599 OR cs.Bettype = 1701)
	    AND acs.discount < cs.discount

    IF @@ERROR <> 0
    BEGIN
	    SELECT @ErrMsg = 'update agent commission unsuccessfully.',
		    @ErrCode = 514					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END	
    	
    	
    --member 
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		playerdiscount = CASE	WHEN acs.bettype IN (1,2,3,7,8) 
									    THEN (case	when @ugroup in ('a','hka','dea') then acs.groupa 
												    when @ugroup in ('b','hkb','deb') then acs.groupb  
												    when @ugroup in ('c','hkc','dec') then acs.groupc  
												    when @ugroup in ('d','hkd','ded') then acs.groupd
												    else acs.discount end)
								    ELSE acs.discount END
    FROM	CustSetting acs WITH(NOLOCK)
		    INNER JOIN CustSetting cs ON acs.custid = @recommend AND cs.custid = @custid 
									     AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
    WHERE	(acs.bettype in (1,2,3,7,8) 
			    and	cs.playerdiscount > case	when @ugroup in ('a','hka','dea') then acs.groupa 
											    when @ugroup in ('b','hkb','deb') then acs.groupb  
											    when @ugroup in ('c','hkc','dec') then acs.groupc  
											    when @ugroup in ('d','hkd','ded') then acs.groupd
											    else acs.discount end)
		    OR (acs.bettype not in (1,2,3,7,8) AND acs.discount< cs.playerdiscount)
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update commission unsuccessfully.',
		    @ErrCode = 515					 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END
    --member 3rd
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		playerdiscount = acs.discount 
    FROM	CustSetting3rd acs WITH(NOLOCK)
		    INNER JOIN CustSetting3rd cs ON acs.custid = @recommend AND cs.custid = @custid 
									     AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 

    WHERE	acs.discount< cs.playerdiscount
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update commission unsuccessfully.',
		    @ErrCode = 516				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

	--member DCS product
    UPDATE	cs WITH (UPDLOCK,ROWLOCK)
    SET		playerdiscount = acs.discount 
    FROM	CustDiscount3rd_Agent acs WITH(NOLOCK)
		    INNER JOIN CustDiscount3rd_Member cs ON acs.custid = @recommend AND cs.custid = @custid 
									     AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 

    WHERE	acs.discount< cs.playerdiscount
	IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update commission unsuccessfully.',
		    @ErrCode = 603				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

    --live casino , keno, gold deluxe
    UPDATE cs WITH(UPDLOCK,ROWLOCK)
    SET playerdiscount = acs.discount
    FROM CustSettingGame acs WITH(NOLOCK) 
	    INNER JOIN CustSettingGame cs ON acs.custid = @recommend AND acs.sporttype = cs.sporttype AND acs.bettype = cs.bettype 
    WHERE cs.custid = @custid AND cs.sporttype in (162,202, 255) AND (cs.bettype = 1101 OR cs.bettype between 1501 AND 1599 OR cs.Bettype = 1701)
	    AND acs.discount < cs.playerdiscount

    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update commission unsuccessfully.',
		    @ErrCode = 517				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

	-- For ColossusBet
	DECLARE @adiscount_Destination_18001 DECIMAL (9,8) = 0
	DECLARE @adiscount_Destination_18002 DECIMAL (9,8) = 0
	
	DECLARE @sdiscount_Destination_18001 DECIMAL (9,8) = 0
	DECLARE @sdiscount_Destination_18002 DECIMAL (9,8) = 0
	
	DECLARE @discount_Destination_18001 DECIMAL (9,8) = 0
	DECLARE @discount_Destination_18002 DECIMAL (9,8) = 0
	
	SET @discount_Destination_18001 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @recommend AND Sporttype = 204 AND Bettype = 18001 )	
	SET @discount_Destination_18002 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @recommend AND Sporttype = 204 AND Bettype = 18002 )	
	
	SET @adiscount_Destination_18001 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 204 AND Bettype = 18001)
	SET @sdiscount_Destination_18001 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 204 AND Bettype = 18001)
	
	SET @adiscount_Destination_18002 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 204 AND Bettype = 18002)
	SET @sdiscount_Destination_18002 = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 204 AND Bettype = 18002)
	
	
	UPDATE CustCommRate WITH(UPDLOCK,ROWLOCK)
		SET  sdiscount = @sdiscount_Destination_18001
			,adiscount = @adiscount_Destination_18001
			,discount = @discount_Destination_18001
	WHERE CustId = @custid	
		 AND Sporttype = 204 AND Bettype = 18001
	
	UPDATE CustCommRate WITH(UPDLOCK,ROWLOCK)
		SET  sdiscount = @sdiscount_Destination_18002
			,adiscount = @adiscount_Destination_18002
			,discount = @discount_Destination_18002
	WHERE CustId = @custid	
		 AND Sporttype = 204 AND Bettype = 18002	
		
    IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update commission unsuccessfully.',
		    @ErrCode = 518				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

	
	-- For Myanmar Odds
	IF @IsMyanmarOdds_source = 1
	BEGIN
		SET @adiscount_Destination_MO = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @mrecommend AND Sporttype = 1 AND Bettype = 301)
		
		SET @sdiscount_Destination_MO = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 1 AND Bettype = 301)
		
		UPDATE CustCommRate
			SET  sdiscount = @sdiscount_Destination_MO
				,adiscount = @adiscount_Destination_MO
				,discount = @discount_Destination_MO
		WHERE CustId = @custid	
			 AND Sporttype = 1 AND Bettype = 301
		
	END
	IF @@ERROR<>0
    BEGIN
		    SELECT @ErrMsg = 'update commission unsuccessfully.',
		    @ErrCode = 519				 
		    IF @ReturnErrCode = 0
			    RAISERROR(@ErrMsg, 16, 1)
		    return
    END

	
	-- Update Stake Level for moved member
	DECLARE	@updateStakeLevel	TABLE (
									SportType				SMALLINT
								,	BetType					INT
								,	StakeLevelList			VARCHAR(200)
								,	StakeLevelList_new		VARCHAR(200)
								,	StakeLevelList_upline	VARCHAR(200)
								);
	
	INSERT INTO	@updateStakeLevel
		(	SportType     , BetType     , StakeLevelList     , StakeLevelList_new, StakeLevelList_upline)
	SELECT	csla.SportType, csla.BetType, cslm.StakeLevelList, ''                , csla.StakeLevelList
	FROM		dbo.CustStakeLevel_Agent AS csla WITH (NOLOCK)
	INNER JOIN	dbo.CustStakeLevel_Member AS cslm WITH (NOLOCK)
			ON	cslm.SportType = csla.SportType
			AND	cslm.BetType = csla.BetType
			AND	csla.CustID = @recommend
			AND	cslm.CustID = @custid
	
	UPDATE	usl
	SET	usl.StakeLevelList_new = fsls.String
	FROM		@updateStakeLevel AS usl
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaOld WITH (NOLOCK)
			ON	cslaOld.SportType = usl.SportType
			AND	cslaOld.BetType = usl.BetType
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaNew WITH (NOLOCK)
			ON	cslaNew.SportType = cslaOld.SportType
			AND	cslaNew.BetType = cslaOld.BetType
			AND	cslaNew.CustID = @recommend
			AND	cslaOld.CustID = @recommend_old
	CROSS APPLY	dbo.f_StakeLevelcorrectString(cslaOld.StakeLevelList, cslaNew.StakeLevelList) AS fslsRemoved
	CROSS APPLY dbo.f_StakeLevelcorrectString(usl.StakeLevelList, fslsRemoved.String) AS fsls

	UPDATE	usl
	SET	usl.StakeLevelList_new = sr.LowestStakeLevel
	FROM	@updateStakeLevel AS usl
	CROSS APPLY	(
		SELECT TOP(1) ISNULL(CONVERT(VARCHAR(200), sl.StakeLevelID), '') AS LowestStakeLevel
		FROM (
			SELECT	CAST(val AS INT) AS val
			FROM	dbo.strSplit(usl.StakeLevelList_Upline, ',')
		) AS ss
		INNER JOIN	dbo.StakeLevel AS sl WITH(NOLOCK)
				ON	ss.val = sl.StakeLevelID
		ORDER BY	sl.MaxStake, sl.MinStake, sl.GameGroupID
	) sr
	WHERE	usl.StakeLevelList_new = ''

	UPDATE	cslm WITH (ROWLOCK, UPDLOCK)
	SET	cslm.StakeLevelList = usl.StakeLevelList_new
	FROM	dbo.CustStakeLevel_Member AS cslm
	INNER JOIN	@updateStakeLevel AS usl
			ON	usl.SportType = cslm.SportType
			AND	usl.BetType = cslm.BetType
	WHERE	cslm.CustID = @custid

	-- Update Daily Auto Reset Win Loss Limit for moved member	
	
		UPDATE	cwlla
		SET	cwlla.IsAutoReset = 0
		FROM		#CustInfo AS ci
		INNER JOIN	dbo.CustWinLossLimit_Member AS cwlla WITH (ROWLOCK, UPDLOCK)
		ON	cwlla.CustId = ci.custid 
		INNER JOIN CustWinLossLimit_Agent s
		ON s.Custid=@recommend AND cwlla.sporttype=s.sporttype AND cwlla.bettype=s.bettype
		WHERE s.IsAutoReset=0	AND 	cwlla.IsAutoReset = 1


    DECLARE @LogSPData VARCHAR(8000)
    SELECT  @LogSPData = '<Acc_CustomerUpdMoveMember  MemberName="' + @membername + '" OldAgentId="'
                + CONVERT(VARCHAR(20), @recommend_old) + '" NewAgentName="' + @agentname+ '" '
                + 'NewAgentId="' + CONVERT(VARCHAR(20), @recommend) + '" '  
			    +'userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + '" '
			    +'ReturnErrCode="' + COALESCE(CAST(@ReturnErrCode AS VARCHAR(50)), SPACE(1)) + '" '
			    +'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
			    +'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'

    SET @endRun = getdate()
    SET @duration  = datediff (millisecond,@startRun,@endRun)

    BEGIN TRY
    /*615	Acc_CustomerUpdMoveMember	Move member to new Agent*/
        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID,
		    @CustID = @custid,
            @ActionID = 615, 
		    @TrackingValue = @LogSPData,
		    @duration = @duration
    END TRY
    BEGIN CATCH
	    SELECT  @LogSPData = '<Acc_CustomerUpdMoveMember  MemberName="' + @membername + '" OldAgentId="'
                + CONVERT(VARCHAR(20), @recommend_old) + '" NewAgentName="' + @agentname+ '" '
                + 'NewAgentId="' + CONVERT(VARCHAR(20), @recommend) + '" '  
			    +'userid="' + COALESCE(CAST(@userid AS VARCHAR(50)), SPACE(1)) + '" '
			    +'ReturnErrCode="' + COALESCE(CAST(@ReturnErrCode AS VARCHAR(50)), SPACE(1)) + '" '
			    +'ErrCode="' + COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)),SPACE(1)) + '" ' 
			    +'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" />'
        EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		    @UserID = @UserID,
		    @CustID = @custid,
            @ActionID = 615, 
		    @TrackingValue = @LogSPData,
		    @duration = @duration	
    END CATCH
END
GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMember] TO [vnteam]
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveMember] TO [vnteam]
GO 
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMember] TO [bodbAdminNet]
GO 
