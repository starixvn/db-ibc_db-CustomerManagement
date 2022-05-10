/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet" viewers="" isFunction="0"></info>*/
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
	- 20170601@Elodie: Remove Inspired Virtual Sport [Redmine: #77274]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]  
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20190814@Johnson: dont touch on cn88 customers [redmine:#116691]
	- 20190830@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]

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
    EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT;
    IF @ErrCode <> 0
        RETURN;

    DECLARE @srecommend            INT, 
            @mrecommend            INT,
            @srecommend_old        INT,
            @sDisableOutright    BIT,
            @mDisableOutright    BIT,
                      
            @sDoubleCommLosing    BIT,
            @mDoubleCommLosing  BIT,
            @sSuspended            BIT,    
            @mSuspended            BIT,
      
            @sHideKeno                    BIT,
            @mHideKeno                    BIT  

    SELECT    @srecommend            = custid,         
            @sDisableOutright    = DisableOutright,
            @sDoubleCommLosing  = DoubleCommLosing,
            @sHideKeno                = HideKeno
	FROM    custinfo WITH(NOLOCK) 
    WHERE    username = @supername AND roleid = 4;

    SELECT    @mrecommend            = custid,
            @srecommend_old        = srecommend,         
            @mDisableOutright    = DisableOutright,
            @mDoubleCommLosing    = DoubleCommLosing,
            @mHideKeno                = HideKeno         
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
	
	IF (@_SiteSuper = 'cn88' OR @_SiteMaster = 'cn88')
	BEGIN
		SELECT @ErrMsg = 'Not allow to move customer of CN88 sites!',@ErrCode = 912							
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
   
 
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 180, @bettype = 1201;
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 181, @bettype = 1231;
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 182, @bettype = 1231;
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 183, @bettype = 1231;
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 184, @bettype = 1231;
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 185, @bettype = 1231;
    --EXEC dbo.Acc_CustSetting3rd_04 @mrecommend = @mrecommend, @srecommend = @srecommend, @roleid = 3, @mode = 'virtual-sports', @sporttype = 186, @bettype = 1220;

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