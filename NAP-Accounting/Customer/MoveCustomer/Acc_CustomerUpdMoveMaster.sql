SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUpdMoveMaster]
    @supername    VARCHAR(40),
    @mastername VARCHAR(40),
    @userid        INT,
    @IP            VARCHAR(15)='',
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
Created: 
Task : Move a master to another super
DB: DBCust/CustDB
Original:

Revisions:
    - 20090525@Daniel: add check contraints for Horse & Finance
    - 20090528@Daniel: remove groupe, groupf when checking commission
    - 20090917@Phuc: Write log to dblog    
    - 20090923@Shifu: Remove check master synchronized casino constrain
    - 20090924@Jamie:  Not allowing moving master see if the total tickets under master exceed 20000
    - 20091008@Kiwi: Remove WriteLog_UserLog
    - 20091102@Kiwi: Remove RaisError and change to check total tickets FROM db02 to db052
    - 20091104@Jamie: Remove the input param @update out 
    - 20091107@Daniel: use @temp table to cache custids for updating.
    - 20091110@Daniel: Add check internal contraint
    - 20091112@Jamie: Check DisableOutright before moving
    - 200911224@Ken: Use loop to update in case number of tickets is huge
    - 20091205@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
    - 20091222@Kiwi: Apply Execution Replication (use dbo.Acc_ExecRep_00)
    - 20100114@Kiwi: Call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
    - 20100115@Jamie: Remove checking SyncCasino 
    - 20100205@Jamie: Update the Casino status of all lines Master when Super disabled
    - 20100208@Lewin: Change LogSP data format
    - 20100512@Henry: Check DisableOpenTote before moving
    - 20100911@Henry: Check Number Game + Bingo before moving
    - 20101019@Henry: Record execution time
    - 20110321@Johnson: Check Greyhound and Harness
    - 20110413@Lukas: check closed/suspended
    - 20110801@Johnson: - remove bettype dead ball over/under of number game
                        - add more bettype for nubmer game Warrior,  Next combo and Number Group
    - 20111020@Tom:Add check P2P Game: Status, game setting, commission.
    - 20120224@Johnson: - Separate checking and moving account
                        - Check live casino setting
    - 20120821@Dan: add virtual soccer, remove FI
    - 20121002@Johnson: check double comm losing status
    - 20130218@Dan: Change linked server DB03 to DBPOLICY, DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
    - 20130307@Elodie: Add Virtual HR
    - 20131108@Elodie: Splitting bodb02 into CustDB (Roll back updates on custinfo,customer table in main SP)              
    - 20131126@Kathy: Add Virtual Greyhounds/Motor Racing (182, 184) [Redmine:#7234]
    - 20131203@Johnson:- Correct comm setting for downlines after moving customers
                - Apply execrep Acc_CustSetting_04/Acc_CustSetting3rd_04 instead of calling SPs Acc_CustomerUpdMaster_MinMaxPositiontaking/Acc_CustomerUpdMasterHR_MinMaxPositiontaking/..
    - 20140314@Elodie: Add Keno product [Redmine:#13326]
    - 20140403@Kathy: Add Virtual Speedway (183), Virtual Virtual Cycling (185)    [Redmine:#14142]
    - 20140611@Elodie: Implement separate setting pages for Keno [Redmine:#13156]
    - 20140818@Logan:   Exclude disabled agents, members while updating [Redmine:#19631]
	- 20141204@Johnson: Add new country Korea [bettype = 1514] for Keno [Redmine: #26647]
	- 20150511@Kathy: Add Gold Deluxe product [Redmine:#34486]
	- 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerCheckMoveMaster, Acc_CustomerSelCheckAllowedDownlines to DBCUST.CustDB) [Redmine:#36216]
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20151030@Dominic: Add MuayThai product [Redmine: #46732]
	- 20160205@Billy:	Apply for AllBet product - [Redmine: #51590]
	- 20160218@Dominic: Not allow to move a IMBC customer to MBC line and vice versa [Redmine: #50221]
	- 20160426@Winnie: fix  Bug #56653 [Move account: IsHidden of move master is changed to 0]
	- 20160426@Winnie: fix  Bug #62755 [NAP - IsDailyAutoReset of downline is changed to 0 after moving downline although both downline and upline has IsDailyAutoReset=1]
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    Max errorcode 136
• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON;

    DECLARE @startRun DATETIME;
    DECLARE @endRun DATETIME;
    DECLARE @duration INT;
    SET @startRun = getdate();

    --Check permission for account site: @phuc20080213
    EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT;
    IF @ErrCode <> 0
        RETURN;

    DECLARE @srecommend            INT, 
            @mrecommend            INT,
            @srecommend_old        INT,
            @sDisableOutright    BIT,
            @mDisableOutright    BIT,
            @sDisableCasino        BIT,
            @mDisableCasino        BIT,
            @sDisableLiveCasino    BIT,
            @mDisableLiveCasino BIT,
            @sDoubleCommLosing    BIT,
            @mDoubleCommLosing  BIT,
            @sSuspended            BIT,    
            @mSuspended            BIT,
            --@sMaxTransferP2P    MONEY,
            --@mMaxTransferP2P    MONEY,
            --@sIsAutoResetP2P    BIT,
            --@mIsAutoResetP2P    BIT,
            --@sDisableP2P        BIT, 
            --@mDisableP2P        BIT, 
            --@sDisableFunP2P        BIT,
            --@mDisableFunP2P        BIT,
            @sDisableVirtualSports        BIT,
            @mDisableVirtualSports        BIT,            
            @sHideKeno                    BIT,
            @mHideKeno                    BIT,
            @mHideGoldDeluxe		BIT,
            @sHideGoldDeluxe		BIT,
            @sDisableGoldDeluxe		BIT,
            @mDisableGoldDeluxe		BIT,
            @mHideColossusBet		BIT,
            @sHideColossusBet		BIT,
            @sDisableColossusBet	BIT,
            @mDisableColossusBet	BIT;        

    SELECT    @srecommend            = custid,         
            @sDisableOutright    = DisableOutright,
            @sDisableCasino        = DisableCasino,
            @sDisableLiveCasino = DisableLiveCasino,
            @sDoubleCommLosing  = DoubleCommLosing,    
            --@sMaxTransferP2P    = MaxTransferP2P, 
            --@sIsAutoResetP2P    = IsAutoResetP2P, 
            --@sDisableP2P        = DisableP2P, 
            --@sDisableFunP2P        = DisableFunP2P,
            @sDisableVirtualSports    = DisableVirtualSports,
            @sHideKeno                = HideKeno,
			@sDisableGoldDeluxe		= DisableGoldDeluxe,
			@sHideGoldDeluxe	= HideGoldDeluxe,
			@sDisableColossusBet = DisableColossusBet,
			@sHideColossusBet	= HideColossusBet
            
      FROM    custinfo WITH(NOLOCK) 
    WHERE    username = @supername AND roleid = 4;

    SELECT    @mrecommend            = custid,
            @srecommend_old        = srecommend,         
            @mDisableOutright    = DisableOutright,
            @mDisableCasino        = DisableCasino,
            @mDisableLiveCasino = DisableLiveCasino,
            @mDoubleCommLosing    = DoubleCommLosing,
            --@mMaxTransferP2P    = MaxTransferP2P, 
            --@mIsAutoResetP2P    = IsAutoResetP2P, 
            --@mDisableP2P        = DisableP2P, 
            --@mDisableFunP2P        = DisableFunP2P,
            @mDisableVirtualSports    = DisableVirtualSports,
            @mHideKeno                = HideKeno,
			@mDisableGoldDeluxe		= DisableGoldDeluxe,
			@mHideGoldDeluxe	= HideGoldDeluxe,
			@mDisableColossusBet = DisableColossusBet,
			@mHideColossusBet	= HideColossusBet            
      FROM    custinfo WITH(NOLOCK) 
    WHERE    username = @mastername AND roleid = 3;

	-- 20160218@Dominic: Not allow to move a IMBC customer to MBC line and vice versa
	DECLARE @_SiteSuper VARCHAR(10),@_SiteMaster VARCHAR(10)
	
	SELECT @_SiteSuper = site
	FROM dbo.Customer WITH(NOLOCK)
	WHERE CustID = @srecommend
	
	SELECT @_SiteMaster = site
	FROM dbo.Customer WITH(NOLOCK)
	WHERE CustID = @mrecommend
	
	IF (@_SiteSuper = 'IMBC' OR @_SiteMaster = 'IMBC') AND @_SiteSuper <> @_SiteMaster
	BEGIN
		SELECT @ErrMsg = 'Not allow to move customer between MBC and IMBC sites!',@ErrCode = 911								
		RETURN	
	END

    --Check Allowed downlines 
     EXEC dbo.Acc_CustomerSelCheckAllowedDownlines 
        @custid=@mrecommend,
        @roleid=3,
        @isExecRep=0,
        @isUpdatePT = 1,
        @Sporttype = 1,
        @Language='E',
        @ErrMsg=@ErrMsg output,
        @ErrCode=@ErrCode output;
     IF @ErrCode <> 0 
      RETURN;
      
    EXEC dbo.Acc_CustomerCheckMoveMaster
        @supername = @supername
      , @mastername = @mastername
      , @userid = @userid
      , @ErrCode = @ErrCode OUTPUT
      , @ErrMsg = @ErrMsg OUTPUT;

    IF @ErrCode > 0
        RETURN;

    --Declare @temp table to contain customer info before update.
    CREATE TABLE #CustInfo (CustID INT);

    INSERT INTO #CustInfo
    SELECT custid
    FROM custinfo (NOLOCK)
    WHERE mrecommend = @mrecommend;


    ----P2PGAMESETTING table
    --UPDATE G_P
    --SET stakelevel1 = CASE WHEN s.stakelevel1 = 1 AND G_P.stakelevel1 = 1 THEN 1 ELSE 0 END,
    --    stakelevel2 = CASE WHEN s.stakelevel2 = 1 AND G_P.stakelevel2 = 1 THEN 1 ELSE 0 END,
    --    stakelevel3 = CASE WHEN s.stakelevel3 = 1 AND G_P.stakelevel3 = 1 THEN 1 ELSE 0 END,
    --    stakelevel4 = CASE WHEN s.stakelevel4 = 1 AND G_P.stakelevel4 = 1 THEN 1 ELSE 0 END,
    --    stakelevel5 = CASE WHEN s.stakelevel5 = 1 AND G_P.stakelevel5 = 1 THEN 1 ELSE 0 END
    --FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
    --    INNER JOIN 
    --        ( SELECT * FROM dbo.P2PGameSetting s WITH(NOLOCK) WHERE custid = @srecommend) s
    --            ON G_P.BETTYPE = s.BETTYPE
    --WHERE G_P.custid IN (SELECT custid FROM @CustInfo)

    --IF @@ERROR <> 0 
    --    BEGIN        
    --        SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (P2PGameSetting).',
    --                    @ErrCode = 300
    --        RETURN
    --    END

    --IF EXISTS (
    --    SELECT TOP 1 1 FROM 
    --    (SELECT * FROM dbo.P2PGameSetting m WITH(NOLOCK) WHERE m.custid = @mrecommend)  m
    --    INNER JOIN
    --        (SELECT * FROM dbo.P2PGameSetting s WITH(NOLOCK) WHERE s.custid = @srecommend)   s
    --                ON s.BETTYPE = m.BETTYPE
    --    WHERE (m.stakelevel2 = 0 AND m.stakelevel3 = 0 AND m.stakelevel4 = 0 AND m.stakelevel5 = 0 )
    --    AND (s.stakelevel2 = 1 OR s.stakelevel3 = 1 OR s.stakelevel4 = 1 OR s.stakelevel5 = 1 )
    --)
    --BEGIN
    --    UPDATE G_P
    --    SET stakelevel1 = CASE WHEN s.stakelevel1 = 1 THEN 1 ELSE 0 END,
    --        stakelevel2 = CASE WHEN s.stakelevel2 = 1 THEN 1 ELSE 0 END,
    --        stakelevel3 = CASE WHEN s.stakelevel2 = 0 AND s.stakelevel3 = 1 THEN 1 ELSE 0 END,
    --        stakelevel4 = CASE WHEN s.stakelevel2 = 0 AND s.stakelevel3 = 0 AND s.stakelevel4 = 1 THEN 1 ELSE 0 END,
    --        stakelevel5 = CASE WHEN s.stakelevel2 = 0 AND s.stakelevel3 = 0 AND s.stakelevel4 = 0 AND s.stakelevel5 = 1 THEN 1 ELSE 0 END
    --    FROM P2PGameSetting G_P WITH (ROWLOCK, UPDLOCK)
    --        INNER JOIN 
    --            ( SELECT * FROM dbo.P2PGameSetting s WITH(NOLOCK) WHERE custid = @srecommend) s
    --                ON G_P.BETTYPE = s.BETTYPE
    --    WHERE G_P.custid = @mrecommend AND G_P.stakelevel2 = 0 AND G_P.stakelevel3 = 0 AND G_P.stakelevel4 = 0 AND G_P.stakelevel5 = 0
        
    --    IF @@ERROR <> 0 
    --    BEGIN        
    --            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (P2PGameSetting).',
    --                    @ErrCode = 301
    --        RETURN
    --    END    
    --END

    --if (@sDisableP2P = 1 and @mDisableP2P = 0) 
    --    OR (@sIsAutoResetP2P = 0 and @mIsAutoResetP2P = 1)
    --    OR (@sDisableFunP2P = 1 and @mDisableFunP2P = 0)
    --    OR (@sMaxTransferP2P < @mMaxTransferP2P)
    --    OR (@sDoubleCommLosing = 0 AND @mDoubleCommLosing = 1)
    --BEGIN
    --    UPDATE    Custinfo WITH (UPDLOCK,ROWLOCK)
    --    SET        DisableP2P = CASE WHEN @sDisableP2P = 1 THEN 1 ELSE DisableP2P END,
    --            DisableFunP2P = CASE WHEN @sDisableFunP2P  = 1 THEN 1 ELSE DisableFunP2P END,
    --            IsAutoResetP2P = CASE WHEN @sIsAutoResetP2P = 0 THEN 0 ELSE IsAutoResetP2P END,
    --            MaxTransferP2P = CASE WHEN @sMaxTransferP2P < MaxTransferP2P THEN @sMaxTransferP2P ELSE MaxTransferP2P END,
    --            DoubleCommLosing = CASE WHEN @sDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
    --    WHERE    custid IN(SELECT CustID FROM @CustInfo)
    --    IF @@ERROR <>0
    --    BEGIN
    --        SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
    --                @ErrCode = 302
    --        RETURN 
    --    END
    --END

    ----P2PGroupComm table
    --UPDATE G_C 
    --SET sdiscount = s.sdiscount
    --FROM P2PGroupComm G_C WITH (ROWLOCK, UPDLOCK)
    --    INNER JOIN 
    --        ( SELECT * FROM dbo.P2PGROUPCOMM s WITH(NOLOCK) WHERE custid = @srecommend) s
    --        ON G_C.GroupID = s.GroupID
    --WHERE G_C.custid IN (SELECT custid FROM @CustInfo)

    --IF @@ERROR <> 0 
    --BEGIN    
    --    SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (P2PGroupComm).',
    --                @ErrCode = 303
    --    RETURN
    --END

    if (@sDoubleCommLosing = 0 and @mDoubleCommLosing = 1)
    BEGIN
        UPDATE    Custinfo WITH (UPDLOCK,ROWLOCK)
           SET        DoubleCommLosing = CASE WHEN @sDoubleCommLosing = 0 THEN 0 ELSE DoubleCommLosing END
        WHERE    custid IN(SELECT CustID FROM #CustInfo);
        IF @@ERROR <>0
        BEGIN
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 303;
            RETURN; 
        END;
    END;

    --customer table
    UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend 
    WHERE custid IN (SELECT CustID FROM #CustInfo);

    IF @@ERROR <> 0 
    BEGIN
        --ROLLBACK TRANSACTION MANUALLY
        UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;
        
        SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (customer).',
            @ErrCode = 304;                     
        RETURN;
    END;

    --custinfo table

    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend 
    WHERE custid IN (SELECT CustID FROM #CustInfo);

    IF @@ERROR <> 0 
    BEGIN
         --ROLLBACK TRANSACTION MANUALLY
        UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;
        
        UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;
        
        SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
            @ErrCode = 305;                 
        RETURN;
    END;

    --- update suspended status
    IF @sSuspended = 1 AND @mSuspended = 0
    BEGIN
        UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
           SET    reject = 1 
        WHERE    custid IN(SELECT CustID FROM #CustInfo);
        IF @@ERROR <>0
        BEGIN
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 306;
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
	--						INNER JOIN dbo.CustProductStatus s WITH(NOLOCK)ON s.CustID = @srecommend
	--						INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
	--					WHERE dbo.f_GetProductStatus(s.bitmapIsDisabled, stt.bitmapOrder) = 1
	--							AND dbo.f_GetProductStatus(m.bitmapIsDisabled, stt.bitmapOrder) = 0
		
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
	--		SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
 --                   @ErrCode = 9111;
 --           RETURN;
	--	END;
	--END;

	--SET @xmlStrHidden =(
	--			SELECT (
	--					SELECT stt.bitmapOrder	AS '@b'
	--						, 0	AS '@s'
	--					FROM dbo.ProductStatusProfile stt WITH(NOLOCK)
	--						INNER JOIN dbo.CustProductStatus s WITH(NOLOCK)ON s.CustID = @srecommend
	--						INNER JOIN dbo.CustProductStatus m WITH(NOLOCK)ON m.CustID = @mrecommend
	--					WHERE dbo.f_GetProductStatus(s.bitmapIsHidden, stt.bitmapOrder) = 0
	--							AND dbo.f_GetProductStatus(m.bitmapIsHidden, stt.bitmapOrder) = 1
		
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
	--		SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
 --                   @ErrCode = 9112;
 --           RETURN; 
	--	END;
	--END;

    IF @sDisableOutright = 1 AND (@sDisableOutright <> @mDisableOutright)
    BEGIN

        UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
           SET    DisableOutright = 1 
        WHERE    custid IN(SELECT CustID FROM #CustInfo);
        
        IF @@ERROR <>0
        BEGIN
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 307;
            RETURN;
        END;

    END;

    IF @sDisableCasino = 1 AND (@sDisableCasino <> @mDisableCasino)
    BEGIN

        UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
           SET    DisableCasino = 1 
        WHERE    custid IN(SELECT CustID FROM #CustInfo);
        IF @@ERROR <>0
        BEGIN
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 308;
            RETURN;
        END;

    END;

    IF @sDisableLiveCasino = 1 AND @sDisableLiveCasino <> @mDisableLiveCasino
    BEGIN
        UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
           SET DisableLiveCasino = 1
        WHERE custid IN (SELECT custid FROM #CustInfo);
        
        IF @@ERROR <>0 
        BEGIN
            SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 309;
            RETURN;
        END;
    END;

    -- VS
    IF @sDisableVirtualSports = 1 AND (@sDisableVirtualSports <> @mDisableVirtualSports)
    BEGIN
        UPDATE    Custinfo WITH (UPDLOCK,ROWLOCK)
           SET        DisableVirtualSports = 1 
        WHERE    custid IN(SELECT CustID FROM #CustInfo);
        IF @@ERROR <>0
        BEGIN
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 310;
            RETURN; 
        END;
    END;

    -- Keno
    IF @sHideKeno = 0 AND (@sHideKeno <> @mHideKeno)
    BEGIN
        UPDATE    Custinfo WITH (UPDLOCK,ROWLOCK)
           SET        HideKeno = 0
        WHERE    custid IN(SELECT CustID FROM #CustInfo);
        IF @@ERROR <>0
        BEGIN
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 311;
            RETURN; 
        END;
    END;
    
	 IF @sDisableGoldDeluxe = 1 AND @sDisableGoldDeluxe <> @mDisableGoldDeluxe
    BEGIN
        UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
           SET DisableGoldDeluxe = 1
        WHERE custid IN (SELECT custid FROM #CustInfo);
        
        IF @@ERROR <>0 
        BEGIN
            SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 309;
            RETURN;
        END;
    END;

	IF @sDisableColossusBet = 1 AND @sDisableColossusBet <> @mDisableColossusBet 
    BEGIN
        UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
           SET DisableColossusBet = 1
        WHERE custid IN (SELECT custid FROM #CustInfo);
        
        IF @@ERROR <>0 
        BEGIN
            SELECT @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 310;
            RETURN;
        END;
    END;


    UPDATE    mcg WITH (UPDLOCK,ROWLOCK)
       SET        mcg.IsDisabled = 1 
      FROM CustGameType scg WITH(NOLOCK) 
INNER JOIN CustGameType mcg ON scg.CustID = @srecommend AND mcg.GameTypeID = scg.GameTypeID
    WHERE    mcg.custid IN(SELECT CustID FROM #CustInfo) AND scg.IsDisabled = 1 AND mcg.IsDisabled = 0;
    IF @@ERROR <>0
    BEGIN
        SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                @ErrCode = 312;
        RETURN;
    END;
    /*
    IF @sDisableBingo = 1 AND (@sDisableBingo <> @mDisableBingo)
    BEGIN

        UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
           SET    DisableBingo = 1 
        WHERE    custid IN(SELECT CustID FROM @CustInfo)
        IF @@ERROR <>0
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 132
        RETURN

    END

    IF @sDisableNumber = 1 AND (@sDisableNumber <> @mDisableNumber)
    BEGIN

        UPDATE Custinfo WITH (UPDLOCK, ROWLOCK)
           SET    DisableNumber = 1 
        WHERE    custid IN(SELECT CustID FROM @CustInfo)
        IF @@ERROR <>0
            SELECT    @ErrMsg = 'Error super ' + @supername + ', master ' + @Mastername + ': update unsuccessfully (custinfo).',
                    @ErrCode = 133
        RETURN

    END
    */

    --Apply ExeReplication
    -- call Acc_ExecRep_00 two times to update coming bets that not replicated to subcriptions servers yet.
    EXEC DBTXN.bodb02.dbo.Acc_ExecRep_00 
        @custid = 0,
        @recommend = 0,
        @recommend_old = 0,
        @mrecommend = @mrecommend,
        @mrecommend_old = 0,
        @srecommend = @srecommend,
        @srecommend_old = @srecommend_old,
        @roleid = 3,
        @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT;
    IF @ErrCode <> 0
    BEGIN            
        -- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)                  
        --ROLLBACK TRANSACTION MANUALLY
        UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;
        
        UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;                     
        RETURN;
    END;    

    EXEC DBTXN.bodb02.dbo.Acc_ExecRep_00 
        @custid = 0,
        @recommend = 0,
        @recommend_old = 0,
        @mrecommend = @mrecommend,
        @mrecommend_old = 0,
        @srecommend = @srecommend,
        @srecommend_old = @srecommend_old,
        @roleid = 3,
        @ErrCode = @ErrCode OUTPUT,
        @ErrMsg = @ErrMsg OUTPUT;
    IF @ErrCode <> 0
    BEGIN            
        -- 20130808@Elodie: Splitting DBTXN into DBCUST (Roll back updates on custinfo,customer table in main SP)                  
        --ROLLBACK TRANSACTION MANUALLY
        UPDATE customer WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;
        
        UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET srecommend = @srecommend_old
        WHERE mrecommend = @mrecommend;                     
        RETURN;
    END;

    --Check & update n4<=s1+m1+a1<=l4
    ---EXEC dbo.Acc_CustomerUpdMaster_MinMaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustSetting_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'number';
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
				@MasterID = @mrecommend
				,@SuperID = @srecommend
				,@RoleID = 3
				,@SportBettypeXML = @SportBettypeXML;

    /*
    EXEC dbo.Acc_CustomerUpdMasterHR_MinMaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustomerUpdMasterLiveCS_MaxPositiontaking @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustomerUpdMasterVS_MinMaxPositiontaking @sporttype = 180, @bettype = 1201, @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustomerUpdMasterVS_MinMaxPositiontaking @sporttype = 181, @bettype = 1231, @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustomerUpdMasterVS_MinMaxPositiontaking @sporttype = 182, @bettype = 1231, @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustomerUpdMasterVS_MinMaxPositiontaking @sporttype = 184, @bettype = 1231, @mrecommend = @mrecommend, @srecommend = @srecommend
    EXEC dbo.Acc_CustomerUpdMasterVS_MinMaxPositiontaking @sporttype = 186, @bettype = 1220, @mrecommend = @mrecommend, @srecommend = @srecommend
    */
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'horse';    
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 180, @bettype = 1201;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 181, @bettype = 1231;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 182, @bettype = 1231;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 183, @bettype = 1231;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 184, @bettype = 1231;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 185, @bettype = 1231;
    EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 186, @bettype = 1220;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'LiveCasino';
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1501;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1511;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1503;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1504;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1505;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1513;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1507;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1508;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1509;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'Keno', @sporttype = 202, @bettype = 1514;
    EXEC dbo.Acc_CustSetting3rd_04 @custid = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'GoldDeluxe', @sporttype = 255, @bettype = 1701;

    --when separate code we must update db07.bodb02.dbo.custsetting 
    UPDATE cs
       SET cs.sdiscount = scs.sdiscount 
      FROM custsetting cs WITH(ROWLOCK, UPDLOCK)
INNER JOIN custInfo c WITH(NOLOCK) ON cs.custid = c.custid
                                  AND c.Enabled = 1
INNER JOIN custsetting scs WITH(NOLOCK) ON scs.custid = @srecommend
                                       AND cs.sporttype = scs.sporttype
                                       AND cs.bettype = scs.bettype
     WHERE cs.custid IN (SELECT custid
                           FROM #CustInfo
                        )
       AND ISNULL(cs.sdiscount, 0) < scs.adiscount;
       

	UPDATE cs
	SET cs.SuperDiscount = scs.Discount
	FROM dbo.CustDiscount3rd_Member cs 
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON ci.CustID = cs.CustID
		INNER JOIN dbo.CustDiscount3rd_Agent scs WITH(NOLOCK) 
			ON scs.custid = @srecommend 
				AND scs.sporttype = cs.sporttype
				AND scs.bettype = cs.bettype
	WHERE ci.mrecommend = @mrecommend AND ci.RoleID = 1
		AND ISNULL(cs.SuperDiscount, 0) < scs.Discount;
	
	
    UPDATE cs
       SET cs.sdiscount = scs.sdiscount
      FROM custsetting3rd cs WITH(ROWLOCK, UPDLOCK)
INNER JOIN custInfo c WITH(NOLOCK) ON cs.custid = c.custid
                                  AND c.Enabled = 1
INNER JOIN custsetting3rd scs WITH(NOLOCK) ON scs.custid = @srecommend
                                          AND cs.sporttype = scs.sporttype
                                          AND cs.bettype = scs.bettype
     WHERE cs.custid IN (SELECT custid
                           FROM #CustInfo
                        )
       AND ISNULL(cs.sdiscount, 0) < scs.sdiscount;


    UPDATE cs
       SET cs.sdiscount = scs.sdiscount
      FROM CustSettingGame cs WITH(ROWLOCK, UPDLOCK)
INNER JOIN custInfo c WITH(NOLOCK) ON cs.custid = c.custid
                                  AND c.Enabled = 1
INNER JOIN CustSettingGame scs WITH(NOLOCK) ON scs.custid = @srecommend
                                           AND cs.sporttype = scs.sporttype
                                           AND cs.bettype = scs.bettype
    WHERE cs.custid IN (SELECT custid
                           FROM #CustInfo
                       )
      AND ISNULL(cs.sdiscount, 0) < scs.sdiscount;

	-- For Colossus Bet
	DECLARE @sdiscountColossusBet_18001 DECIMAL (9,8) = 0;
	DECLARE @sdiscountColossusBet_18002 DECIMAL (9,8) = 0;
	
	SET @sdiscountColossusBet_18001 = (SELECT Commrate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 204 AND Bettype = 18001);
	SET @sdiscountColossusBet_18002 = (SELECT Commrate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 204 AND Bettype = 18002);
	UPDATE C
			SET  sdiscount = @sdiscountColossusBet_18001
		FROM CustCommRate C WITH(ROWLOCK, UPDLOCK)
			JOIN custInfo CI WITH (NOLOCK) ON C.CustId = CI.custid			 
		WHERE CI.srecommend =@srecommend AND CI.roleid = 1
			 AND C.Sporttype = 204 AND C.Bettype = 18001;
	
	UPDATE C
			SET  sdiscount = @sdiscountColossusBet_18002
		FROM CustCommRate C WITH(ROWLOCK, UPDLOCK)
			JOIN custInfo CI WITH (NOLOCK) ON C.CustId = CI.custid			 
		WHERE CI.srecommend =@srecommend AND CI.roleid = 1
			 AND C.Sporttype = 204 AND C.Bettype = 18002;
			 
		
	-- For Myanmar Odds
	DECLARE @IsMyanmarOdds BIT = 0;
	DECLARE @sdiscountMyanmarOdds DECIMAL (9,8) = 0;
	SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@srecommend);
	
	IF @IsMyanmarOdds = 1
	BEGIN
		SET @sdiscountMyanmarOdds = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @srecommend AND Sporttype = 1 AND Bettype = 301);
		
		UPDATE C
			SET  sdiscount = @sdiscountMyanmarOdds
		FROM CustCommRate C WITH(ROWLOCK, UPDLOCK)
			JOIN custInfo CI WITH (NOLOCK) ON C.CustId = CI.custid			 
		WHERE CI.srecommend =@srecommend AND CI.roleid = 1
			 AND C.Sporttype = 1 AND C.Bettype = 301;
	END;
	
	-- Update Stake Level for moved master
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
	WHERE	cslaOld.CustID = @srecommend_old
		AND	cslaNew.CustID = @srecommend;
	
	INSERT INTO	#UpdateStakeLevelList
		(	CustID    , UplineCustID  , RoleID   , BetType      , StakeLevelList      , StakeLevelList_new, StakeLevelList_upline)
	SELECT	tci.custid, ci.srecommend , ci.roleid, cslaM.BetType, cslaM.StakeLevelList, fsls.String       , cslaS.StakeLevelList
	FROM		#CustInfo AS tci
	INNER JOIN	dbo.custInfo AS ci WITH (NOLOCK)
			ON	ci.custid = tci.custid
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaM WITH (NOLOCK)
			ON	tci.CustID = cslaM.custid
	INNER JOIN	dbo.CustStakeLevel_Agent AS cslaS WITH (NOLOCK)
			ON	cslaS.SportType = cslaM.SportType
			AND	cslaS.BetType = cslaM.BetType
			AND	cslaS.CustID = ci.srecommend
	INNER JOIN	@removedStakeLevel AS rsl
			ON	rsl.SportType = cslaM.SportType
			AND	rsl.BetType = cslaM.BetType
	CROSS APPLY	dbo.f_StakeLevelcorrectString(cslaM.StakeLevelList, rsl.StakeLevelList) AS fsls
	WHERE	ci.roleid = 3;

	INSERT INTO	#UpdateStakeLevelList
		(	CustID    , UplineCustID , RoleID   , BetType     , StakeLevelList     , StakeLevelList_new, StakeLevelList_upline)
	SELECT	tci.custid, ci.mrecommend, ci.roleid, csla.BetType, csla.StakeLevelList, fsls.String       , CASE WHEN usll.StakeLevelList_new = '' THEN usll.StakeLevelList_upline ELSE usll.StakeLevelList_new END
	FROM		#CustInfo AS tci
	INNER JOIN	dbo.custInfo AS ci WITH (NOLOCK)
			ON	ci.custid = tci.custid
	INNER JOIN	dbo.CustStakeLevel_Agent AS csla WITH (NOLOCK)
			ON	csla.CustID = ci.custid
	INNER JOIN	#UpdateStakeLevelList AS usll WITH (NOLOCK)
			ON	usll.CustID = ci.mrecommend
			AND	usll.BetType = csla.BetType
	INNER JOIN	@removedStakeLevel AS rsl
			ON	rsl.SportType = csla.SportType
			AND	rsl.BetType = csla.BetType
	CROSS APPLY	dbo.f_StakeLevelcorrectString(csla.StakeLevelList, rsl.StakeLevelList) AS fsls
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
		SELECT TOP(1) ISNULL(CONVERT(VARCHAR(20), sl.StakeLevelID), '') AS LowestStakeLevel
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
						@CustID			= @mrecommend
					,	@RoleID			= 3
					,	@StakeLevel		= @StakeLevelExecRep;
			
			IF	@StopRow = @MaxRow
				BREAK;

			SELECT	@StartRow = @StopRow + 1;
			SELECT	@StopRow = 1 + @StopRow + @Threshold;

			IF	@StopRow >= @MaxRow
				SELECT	@StopRow = @MaxRow;

		END;
	END;

	-- Update Daily Auto Reset Win Loss Limit for moved master
	CREATE TABLE #WinLossLimit_tmp (SportType SMALLINT, BetType INT)
	
	INSERT INTO #WinLossLimit_tmp (SportType,BetType)
	SELECT SportType,BetType
	FROM dbo.CustWinLossLimit_Agent AS s WITH (NOLOCK) 
	WHERE s.Custid=@srecommend AND IsAutoReset=0
	
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

    DECLARE @LogSPData VARCHAR(8000);

    SELECT @LogSPData = '<Acc_CustomerUpdMoveMaster  MasterName="' + @mastername
                      + '" OldSuperId="' + CONVERT(VARCHAR(20), @srecommend_old)
                      + '" NewSuperName="' + @supername
                      + '" NewSuperId="' + CONVERT(VARCHAR(20), @srecommend)
                      + '" UserId="' + COALESCE(CAST(@userid AS VARCHAR(20)), SPACE(1))
                      + '" IP="' + @IP + '" />';


    SET @endRun = GETDATE();
    SET @duration  = DATEDIFF(MILLISECOND, @startRun, @endRun);

    BEGIN TRY
        EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
            @UserID = @UserID,
            @CustID = @mrecommend,
            @ActionID = 607,
            @TrackingValue = @LogSPData,
            @duration = @duration;
    END TRY
    BEGIN CATCH
        SELECT  @LogSPData = '<Acc_CustomerUpdMoveMaster  MasterName="' + @mastername 
            + '" OldSuperId="' + CONVERT(VARCHAR(20), @srecommend_old) 
            + '" NewSuperName="' + @supername 
            + '" NewSuperId="' + CONVERT(VARCHAR(20), @srecommend) 
            + '" UserId="' + COALESCE(CAST(@userid AS VARCHAR(20)), SPACE(1)) 
            + '" IP="' + @IP + 
            + '" ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + 
            + '" ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1)) + '" />';
            
        EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
            @UserID = @UserID,
            @CustID = @mrecommend,
            @ActionID = 607,
            @TrackingValue = @LogSPData,
            @duration = @duration;
    END CATCH;
    DROP TABLE #CustInfo;
END;





GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMaster] TO [bodbAdminNet] AS [dbo];
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMoveMaster] TO [vnteam] AS [dbo];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMoveMaster] TO [vnteam] AS [dbo];