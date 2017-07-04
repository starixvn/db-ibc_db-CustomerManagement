/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelAllInfo]
	@username VARCHAR(50),
	@uplineid INT = -1,
	@isInternalAgent BIT = 0
AS
/*
Created: 20090122@nqminh
Task : Select all customer information for agent account!
DB: DBAGE/bodb02
Original:

Revisions:
    - 20090122@[Reviewer]: [Description of revision]    
	- 20090506@[Simon]: Calculate outstanding.
	- 20100429@Terry: Get status for Open Tote
	- 20100710@Simon: Remove firstname + ' ' + lastname = @username
	- 20100918@Jacob: Add column DisableBingo, SyncBingo, uplineDisableBingo
	- 20100924@Terry: Add column DisabledNumber, UplineDisabledNumber
	- 20101224@Johnson: Apply new arrange of bettype
	- 20110119@Simon: Select one more column upLineEnabledMa to disabled upline exactly.
	- 20110317@Lukas: move HR's status to another SP
	- 20110623@Sophia: Do not allow search by nickname 
	- 20110721@Sophia: Add parameter @isInternalAgent
	- 20110823@Sophia: Count Negative stake as positive turnover
	- 20111018@Tom: 1. Add P2P Transfer (23101)/Outstanding (23102)
					2. Remove variable @ABSDate ('2011-09-01')	
	- 20120206@Sophia: Get DisableLiveCasino, SyncLiveCasino for Live Casino
	- 20120815@Sophia: Get DisableVirtualSports, HideVirtualSports
	- 20120926@Sophia: Get DoubleCommLosing
	- 20121110@viet: get custinfo data base on uplineid instead of username only, to reduce scan
	- 20130522@Johnson: get Poker held funds on member level and disableP2P status (pending)
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20140303@Kathy: - get HideKeno column [Redmine:#12691]
					  - modify formula of Outstanding amount to be calculated based on table Bettrans and TransLog [Redmine:#11550]
    - 20140822@Logan:   Add status for Esports [Redmine: #20661]			  
	- 20150422@Elodie: Add Gold Deluxe product [Redmine:#34486]
	- 20150612@Kathy: Migrate custDB to new server DBCust(Get credit from DBCust.CustDB) [Redmine:#36216]
	- 20150803@Elodie: Get DisableDownlinesGoldDeluxe field [Redmine:#38741]
	- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
	- 20150825@Helen: Colossus Bet - [Redmine: #41264]
	- 20151014@Helen: Customer Setting for Sportsbook 2- [Redmine: #44604]
	- 20151214@Percy: Do not check ticket running of Cock Fighting at bettrans table, because of the translog [Redmine: #48601]
	- 20160112@Percy: Expand new bettype for RNG Casino [Redmine: #48283]
	- 20160128@Percy: Support new sport Cricket [Redmine: #50027]
	- 20160204@Percy: Support new product AllBet [Redmine: #50605]
	- 20160413@Percy: Support Voidbridge single wallet [Redmine: #55259]
	- 20161028@Percy: Support Fishing World [RedmineID: #65731]
	- 20170421@Helen: Enable Downline FishingWorld checkbox is ticked & disabled control although Member is disabled [RedmineID: #74421]
	- 20170517@Winnie: Apply color for closed accounts  - [Redmine:74494]
	- 20170703@Percy: Hotfix formula today/yesterday balance when getting data from bettrans [RedmineID: #79236]
Param's Explanation:
• @username: username of customer that need to be viewed.   
• @uplineId: the ID of the upline.
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @custid INT, @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @UsedCredit MONEY, @Mem_MaxCredit MONEY
    DECLARE @todaySuperCash MONEY,
			@todayMasterCash MONEY,
			@todayAgentCash MONEY,
			@todayCustCash MONEY,		
			@ClosedReason TINYINT
    DECLARE @today DATE
	DECLARE @yesterday DATE

	DECLARE @netPosition MONEY = 0 -- for member

    /*DECLARE @ABSDate DATETIME
    SET @ABSDate = '2011-09-01'	*/

    SELECT @today = CONVERT(DATE, GETDATE())
		 , @yesterday = DATEADD(DD, -1, @today)
		 , @username = RTRIM(LTRIM(@username))

    SELECT @custid = custid
         , @roleid = roleid
         , @srecommend = srecommend
         , @mrecommend = mrecommend
         , @recommend = recommend
      FROM custinfo WITH(NOLOCK)
     WHERE username = @username 
	   AND (srecommend = @uplineid
	        OR mrecommend = @uplineid
	        OR recommend = @uplineid
	       )


    ------20110623: Do not allow search by nickname
    ------20110721: If @isInternal = 1 then searching by nickname, else do not allow
    IF (@custid IS NULL) AND @isInternalAgent = 1
    BEGIN
	    SELECT @custid = custid , @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
        FROM customer WITH (NOLOCK)
        WHERE username2 = @username
	       AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)
		    --- AND custid = @uplineid
    END
    --end


    --Check valid access!
    IF (@custid IS NULL) RETURN
    IF (@recommend <> @uplineid AND @mrecommend <> @uplineid AND @srecommend <> @uplineid) RETURN

    	
    --Downline/Upline status 
    DECLARE @upLineDisableFI BIT
          , @upLineDisableCS BIT

          , @uplineDisableBingo    BIT
          , @uplineDisabledNumber  BIT
          , @upLineDisableOutright BIT

          , @upLineClosed    BIT
          , @upLineSuspend   BIT
          , @upLineEnabled   BIT
          , @upLineEnabledMa BIT

          , @uplineDisableVirtualSports BIT
          , @uplineDoubleCommLosing     BIT
          , @uplineDisableHRFixedOdds   BIT
          , @uplineDisableEsports       BIT
		  , @uplineDisableGoldDeluxe	BIT
		  , @HasDownline				BIT = 0
		  , @DisableDownlinesGoldDeluxe	BIT = 0
		  , @uplineDisableColossusBet	BIT
		  , @DisableDownlinesColossusBet BIT = 0
		  

    DECLARE @DisableAutoMPT BIT
    		
    DECLARE @Credit_MAg_Min MONEY, @Credit_MAg_Max MONEY, 
		    @Credit_Ag_Min MONEY , @Credit_Ag_Max MONEY, 
		    @Credit_Mem_Min MONEY, @Credit_Mem_Max MONEY

    DECLARE @TotalMemberActive INT, @TotalMemberClosed INT, @TotalMemberSuspended INT,
		    @TotalAgentActive INT, @TotalAgentClosed INT, @TotalAgentSuspended INT		
    		
        
    IF @roleID=1 --for member
    BEGIN	
	    --Upline
	    DECLARE @Credit_AllOtherMember MONEY, @Credit_Ag MONEY, @MaxCredit_Mem MONEY, @Credit_Ag_Bal MONEY
    		
	    SELECT @upLineEnabled = ISNULL(Enabled, 0)
	         , @upLineSuspend = ISNULL(reject, 0)
	         , @upLineClosed = ISNULL(closed, 0)
	         , @upLineDisableOutright = ISNULL(DisableOutright, 0)
	         , @uplineDisableFI = ISNULL(DisableFinancial, 0)
	         , @uplineDisableCS = ISNULL(DisableCasino, 0)
	         , @uplineDisableBingo = ISNULL(DisableBingo, 0)
	         , @uplineDisabledNumber = ISNULL(DisableNumber, 0)
	         , @uplineDisableVirtualSports = ISNULL(DisableVirtualSports, 0)
	         , @uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
	         , @uplineDisableHRFixedOdds = ISNULL(DisableHRFixedOdds, 0)
	         , @uplineDisableEsports = ISNULL(DisableEsports, 0)
			 , @uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)
			 , @uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
	         , @Credit_Ag = ISNULL(credit, 0)
	      FROM custinfo WITH(NOLOCK)
	     WHERE custID = @recommend	

	    SELECT @upLineEnabledMa = ISNULL(Enabled,0)
	      FROM custinfo WITH(NOLOCK)
	     WHERE custID = @mrecommend

	    --Member itself
	    SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci WITH (NOLOCK) WHERE recommend = @recommend AND RoleID = 1 AND CustID <> @CustID
    	
	    SELECT @MaxCredit_Mem = ISNULL(maxcredit,0) FROM DBCUST.CustDB.dbo.CustAgent WITH(NOLOCK) WHERE CustID = @recommend
    	
	    SELECT @Credit_Ag_Bal = ISNULL(@Credit_Ag,0) - ISNULL(@Credit_AllOtherMember,0)
	    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	    SELECT @Credit_Mem_Max = CASE WHEN @MaxCredit_Mem =0 THEN @Credit_Ag_Bal
								      WHEN @MaxCredit_Mem > @Credit_Ag_Bal THEN @Credit_Ag_Bal 
								      ELSE @MaxCredit_Mem 
							     END 
		-- Net Balance
		SELECT @netPosition = ISNULL(SUM(Credit - Debit), 0) FROM DBTXN.bodb02.dbo.BalNetPosition WITH (NOLOCK) WHERE custid = @custid
    END 
    ELSE IF @roleID = 2 --for agent
    BEGIN
	    DECLARE @Credit_AllOtherAgent MONEY, @Credit_MAg MONEY
	    --Upline
	    SELECT @upLineEnabled = ISNULL(Enabled, 0)
	         , @upLineSuspend = ISNULL(reject, 0)
	         , @upLineClosed = ISNULL(closed, 0)			
	         , @upLineDisableOutright = ISNULL(DisableOutright, 0)
	         , @uplineDisableFI = ISNULL(DisableFinancial, 0)
	         , @uplineDisableCS = ISNULL(DisableCasino, 0)
	         , @uplineDisableBingo = ISNULL(DisableBingo, 0)
	         , @uplineDisabledNumber = ISNULL(DisableNumber, 0)
	         , @uplineDisableVirtualSports = ISNULL(DisableVirtualSports, 0)
	         , @uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
	         , @uplineDisableHRFixedOdds = ISNULL(DisableHRFixedOdds, 0)
		     , @uplineDisableEsports = ISNULL(DisableEsports, 0)
			 , @uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)
			 , @uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
		     , @Credit_MAg = ISNULL(credit, 0)
	      FROM custinfo WITH(NOLOCK)
	     WHERE custID = @mrecommend		

		 SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE recommend = @custid AND roleid = 1

		 SELECT TOP 1 @DisableDownlinesGoldDeluxe = 1 FROM dbo.custInfo WITH(NOLOCK) WHERE recommend = @custid AND roleid = 1 AND DisableGoldDeluxe = 1
		 
		 SELECT TOP 1 @DisableDownlinesColossusBet = 1 FROM dbo.custInfo WITH(NOLOCK) WHERE recommend = @custid AND roleid = 1 AND DisableColossusBet = 1

	    --Agent Itself		
	    SELECT @Credit_AllOtherAgent = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci WITH(NOLOCK) WHERE mrecommend = @mrecommend AND RoleID = 2 AND Custid <> @custID
    	
	    SELECT @Credit_Ag_Max = ISNULL(@Credit_MAg,0) - ISNULL(@Credit_AllOtherAgent,0)	
	    SELECT @Credit_Ag_Min = ISNULL(SUM(credit),0), 
		       @TotalMemberActive = ISNULL(SUM(CASE WHEN Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
		       @TotalMemberClosed = ISNULL(SUM(CASE WHEN Closed = 1 THEN 1 ELSE 0 END), 0),
		       @TotalMemberSuspended = ISNULL(SUM(CASE WHEN ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0) 
	    FROM custinfo (NOLOCK) 
	    WHERE recommend = @custID AND RoleID=1
    		
	    SELECT @Credit_Mem_Min = ISNULL(MAX(credit),0) FROM DBCUST.CustDB.dbo.custinfo with(NOLOCK)
	    WHERE recommend = @CustID AND Roleid=1
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    DECLARE @Credit_AllOtherMaster MONEY, @Credit_SAg MONEY
	    --Upline
	    SELECT @upLineEnabled = ISNULL(Enabled, 0)
	         , @upLineSuspend = ISNULL(reject, 0)
	         , @upLineClosed = ISNULL(closed, 0)
	         , @upLineDisableOutright = ISNULL(DisableOutright, 0)
	         , @uplineDisableFI = ISNULL(DisableFinancial, 0)
	         , @uplineDisableCS = ISNULL(DisableCasino, 0)
	         , @uplineDisableBingo = ISNULL(DisableBingo, 0)
	         , @uplineDisabledNumber = ISNULL(DisableNumber, 0)
	         , @uplineDisableVirtualSports = ISNULL(DisableVirtualSports, 0)
	         , @uplineDoubleCommLosing = ISNULL(DoubleCommLosing, 0)
	         , @uplineDisableHRFixedOdds = ISNULL(DisableHRFixedOdds, 0)
		     , @uplineDisableEsports = ISNULL(DisableEsports, 0)
			 , @uplineDisableGoldDeluxe = ISNULL(DisableGoldDeluxe, 0)
			 , @uplineDisableColossusBet = ISNULL(DisableColossusBet, 0)
			 , @Credit_SAg = ISNULL(credit, 0)
	      FROM custinfo WITH(NOLOCK)
	     WHERE custID = @srecommend

		 
		 SELECT TOP 1 @HasDownline = 1 FROM dbo.custInfo c WITH (NOLOCK) WHERE mrecommend = @custid AND roleid = 2
		 SELECT TOP 1 @DisableDownlinesGoldDeluxe = 1 FROM dbo.custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableGoldDeluxe = 1
		 SELECT TOP 1 @DisableDownlinesColossusBet = 1 FROM dbo.custInfo WITH(NOLOCK) WHERE mrecommend = @custid AND DisableColossusBet = 1
		
	    --Master Itself
	    SELECT @Credit_AllOtherMaster = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci (NOLOCK) WHERE srecommend = @Srecommend AND RoleID = 3 AND custid <> @CustId
	    SELECT @Credit_MAg_Max = ISNULL(@Credit_SAg,0) - ISNULL(@Credit_AllOtherMaster,0)	
    	
	    SELECT @Credit_MAg_Min = ISNULL(SUM(CASE WHEN RoleID=2 THEN credit ELSE 0 END),0),
		       @TotalAgentActive = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
		       @TotalAgentClosed = ISNULL(SUM(CASE WHEN RoleID = 2 AND Closed = 1 THEN 1 ELSE 0 END), 0),
		       @TotalAgentSuspended = ISNULL(SUM(CASE WHEN RoleID = 2 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0),			
		       @TotalMemberActive = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 0 and ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
		       @TotalMemberClosed = ISNULL(SUM(CASE WHEN RoleID = 1 AND Closed = 1 THEN 1 ELSE 0 END), 0),
		       @TotalMemberSuspended = ISNULL(SUM(CASE WHEN RoleID = 1 AND ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0)
	    FROM custinfo (NOLOCK) 
	    WHERE mrecommend = @custID	
    	
	    SELECT @DisableAutoMPT=DisableAutoMPT FROM CustMaster (NOLOCK) WHERE CustID = @custID
    	
	    /* => Need to check member line as below ???
	    select @Credit_MAg_Min = max(c.credit)
	    from
	    (
		    Select isnull(sum(credit), 0) as credit	from custinfo with (NOLOCK) where mrecommend = @custID and roleid in (1, 2)
		    group by mrecommend, roleid
	    ) c
	    */

    END
	ELSE IF @roleID = 4 --for super
	BEGIN
		SELECT TOP 1 @DisableDownlinesGoldDeluxe = 1 FROM dbo.custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableGoldDeluxe = 1
		SELECT TOP 1 @DisableDownlinesColossusBet = 1 FROM dbo.custInfo WITH(NOLOCK) WHERE srecommend = @custid AND DisableColossusBet = 1
		
	END

    -------------------------------------------------------------------------
    --Updater Info
    DECLARE @TransferOption VARCHAR(8)
    EXEC DBCUST.CustDB.dbo.Acc_CustomerSelTransferOption @uplineid, @TransferOption OUTPUT
    SELECT closed, -- redundant value		
	    reject AS suspended, -- redundant value
	    DisableOutright, -- redundant value
	    DisableFinancial, -- redundant value
	    DisableCasino, -- redundant value
	    DisableBingo, -- redundant value
	    DisableNumber, -- redundant value 
	    @TransferOption AS [TransferOption]
    FROM custinfo WITH (NOLOCK) 	
    WHERE custid = @uplineId

	IF @roleid=1
		SELECT @ClosedReason=ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE Custid=@custid
	ELSE
	BEGIN
		SELECT @ClosedReason=ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo WITH(NOLOCK) WHERE Custid=@custid	
	END
    --General info
    SELECT c.custid, ci.roleid, 
        c.username, c.username2, c.firstname, c.lastname, 	
	    c.phone, c.mobilephone, c.fax, 		
	    lastlogged, 
	    iplogin AS lastloginip, 
	    pwdexpiry, 
	    ci.credit,
		@netPosition AS netPosition,
	    c.currency,	
    	
	    ci.enabled, ci.closed,
		ISNULL(@ClosedReason,0) AS ClosedReason,
		 ci.reject AS suspended,
	    DisableOutright,
	    ci.DisableFinancial,
	    ci.DisableNumber,
	    @DisableAutoMPT as [DisableAutoMPT],	
    	
	    ISNULL(@upLineSuspend,0) AS [uplineSuspend],
	    ISNULL(@upLineClosed,0) AS [upLineClosed],
		
	    ISNULL(@upLineEnabled,0) AS [uplineEnabled],
	    ISNULL(@upLineEnabledMa,0) AS [upLineEnabledMa],
	    ISNULL(@upLineDisableOutright,0) AS [upLineDisableOutright],	
	    ISNULL(@uplineDisableFI,0) AS [uplineDisableFI],	
	    ISNULL(@uplineDisableCS,0) AS [uplineDisableCS],	
	    ISNULL(@uplineDisableBingo,0) AS [uplineDisableBingo],	
	    ISNULL(@uplineDisabledNumber,0) AS [uplineDisableNumber],	
	    ISNULL(@uplineDisableVirtualSports,0) AS [uplineDisableVirtualSports],	
	    ISNULL(@uplineDoubleCommLosing,0) as [uplineDoubleCommLosing],
	    ISNULL(@uplineDisableHRFixedOdds,0) AS [uplineDisableHRFixedOdds],
	    ISNULL(@uplineDisableEsports, 0) AS uplineDisableEsports,
		ISNULL(@uplineDisableGoldDeluxe, 0) AS uplineDisableGoldDeluxe,
		ISNULL(@uplineDisableColossusBet, 0) AS uplineDisableColossusBet,
    	@HasDownline AS HasDownline,
		@DisableDownlinesGoldDeluxe AS DisableDownlinesGoldDeluxe,
		@DisableDownlinesColossusBet AS DisableDownlinesColossusBet,
				
	    @Credit_MAg_Min AS [MasterCredit_Min],
	    @Credit_MAg_Max AS [MasterCredit_Max],
	    @Credit_Ag_Min AS [AgentCredit_Min],
	    @Credit_Ag_Max AS [AgentCredit_Max],
	    @Credit_Mem_Min AS [MemMaxCredit_Min],
	    @Credit_Mem_Max AS [MemMaxCredit_Max],
    	
	    @TotalAgentActive AS [TotalAgActive], 
	    @TotalAgentClosed AS [TotalAgClosed], 
	    @TotalAgentSuspended AS [TotalAgSuspended],	
	    @TotalMemberActive AS [TotalMemActive], 
	    @TotalMemberClosed AS [TotalMemClosed], 
	    @TotalMemberSuspended AS [TotalMemSuspended],
    	
	    ci.synccasino,
	    ci.disablecasino,
	    ci.syncbingo,
	    ci.disablebingo,
	    c.creatdate AS createdate,
	    ci.DisableLiveCasino,
	    ci.SyncLiveCasino,
	    ci.DisableVirtualSports,
	    ci.HideVirtualSports,
	    ci.DoubleCommLosing,
	    --ci.DisableP2P, 
	    ci.DisableHRFixedOdds,
	    ci.HideKeno,
	    ci.DisableEsports,
		ISNULL(ci.DisableGoldDeluxe,1) AS DisableGoldDeluxe,
		ISNULL(ci.HideGoldDeluxe,1) AS HideGoldDeluxe,
		ISNULL(ci.DisableColossusBet,1) AS DisableColossusBet,
		ISNULL(ci.HideColossusBet,1) AS HideColossusBet
		
    FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid
    -------------------------------------------------------------------------
    --Agency Info
    SELECT CASE WHEN c.roleid = 1 THEN c.custid ELSE NULL END AS memberID,
	    CASE WHEN c.roleid = 1 THEN c.username ELSE NULL END AS memberName,	
	    a.custid AS agentID,
	    a.username AS agentName,	
	    m.custid AS masterID,
	    m.username AS masterName,
	    s.custid AS superID,
	    s.username AS superName
    FROM custinfo c WITH (NOLOCK)
	    LEFT JOIN custinfo a WITH (NOLOCK) ON c.recommend = a.custid
	    LEFT JOIN custinfo m WITH (NOLOCK) ON c.mrecommend = m.custid
	    LEFT JOIN custinfo s WITH (NOLOCK) ON c.srecommend = s.custid
    WHERE
	    c.custid = @custid
    -------------------------------------------------------------------------
	-- SportBettypeMatrix
	DECLARE @isTest BIT
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #SportBettype (ProductID INT, bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (ProductID, bettype, RefTable)
	SELECT ProductID, bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0,0,0,2,'','',@isTest)

    --Balance Info
    IF @roleid = 1
    BEGIN
	    --  Balance calculated with the correct date @Phuong20080925	
	    SELECT @todayCustCash = ISNULL(SUM(winlost-actual_stake + playercomm),0)
	    FROM bettrans WITH (NOLOCK)
	    WHERE custid = @custid AND ruben = 1 AND bettype <= 19000 --AND bettype NOT BETWEEN 2101 AND 2499 AND bettype NOT BETWEEN 4001 AND 7999
			AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN (0,3))
		    AND CONVERT(DATE, winlostdate) = @today

		SELECT @todayCustCash = @todayCustCash + ISNULL(SUM(winlost-actual_stake + playercomm),0)
		FROM bettransRNG WITH (NOLOCK)
		WHERE custid = @custid AND statusID NOT IN (0, 1) --AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
			AND CONVERT(DATE, winlostdate) = @today

		SELECT @todayCustCash = @todayCustCash + ISNULL(SUM(winlost-actual_stake + playercomm),0)
		FROM bettransLC WITH (NOLOCK)
		WHERE custid = @custid AND statusID NOT IN (0, 1) --AND gameID BETWEEN 2401 AND 2499
			AND CONVERT(DATE, winlostdate) = @today
    	
	    ;with Balance
	    AS ( 				
		    SELECT 
			    SUM(CASE WHEN ruben=1 THEN winlost-actual_stake+playercomm ELSE 0 END) Cash,
			    SUM(CASE WHEN ruben=0 THEN ABS(actual_stake) ELSE 0 END) outstanding, 
			    SUM(CASE WHEN bettype = 23002 AND ruben=0 THEN actual_stake ELSE 0 END) csOutstanding,
			    SUM(CASE WHEN bettype = 23202 AND ruben=0 THEN actual_stake ELSE 0 END) BingoOutstanding,
			    SUM(CASE WHEN bettype = 23102 AND ruben=0 THEN actual_stake ELSE 0 END) P2POutstanding,
			    SUM(CASE WHEN bettype = 23001 AND ruben=0 THEN actual_stake ELSE 0 END) csTransfer,
			    SUM(CASE WHEN bettype = 23201 AND ruben=0 THEN actual_stake ELSE 0 END) BingoTransfer,
			    SUM(CASE WHEN bettype = 23101 AND ruben=0 THEN actual_stake ELSE 0 END) P2PTransfer,
			    MAX(transdate) lastTxn 
		    FROM bettrans WITH(NOLOCK) 
		    WHERE custid = @custid
				AND (
						(bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable <> 0) AND ruben =0)
						OR ruben <> 0
					)
				AND (
						(CONVERT(DATE, winlostdate) >= @yesterday AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN (0,3)))
						OR CONVERT(DATE, winlostdate) < @yesterday
					)
		    UNION ALL
		    SELECT 0 Cash,
			    SUM(ABS(actual_stake)) outstanding, 
			    0 csOutstanding,
			    0 BingoOutstanding,
			    0 P2POutstanding,
			    0 csTransfer,
			    0 BingoTransfer,
			    0 P2PTransfer,
			    MAX(transdate) lastTxn
		    FROM translog with(NOLOCK)
		    WHERE statusid = 0
				AND custid = @custid
			UNION ALL
			SELECT
				SUM(CASE WHEN statusID NOT IN (0, 1) THEN winlost-actual_stake+playercomm ELSE 0 END) Cash,
			    SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END) outstanding, 
			    0 csOutstanding,
			    0 BingoOutstanding,
			    0 P2POutstanding,
			    0 csTransfer,
			    0 BingoTransfer,
			    0 P2PTransfer,
			    MAX(transdate) lastTxn
			FROM bettransRNG WITH(NOLOCK)
			WHERE custid = @custid
				--AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
				AND (
						(statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
						OR statusID IN (0, 1)
					)
			UNION ALL
			SELECT
				SUM(CASE WHEN statusID NOT IN (0, 1) THEN winlost-actual_stake+playercomm ELSE 0 END) Cash,
			    SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END) outstanding, 
			    0 csOutstanding,
			    0 BingoOutstanding,
			    0 P2POutstanding,
			    0 csTransfer,
			    0 BingoTransfer,
			    0 P2PTransfer,
			    MAX(transdate) lastTxn
			FROM bettransLC WITH(NOLOCK)
			WHERE custid = @custid
				--AND gameID BETWEEN 2401 AND 2499
				AND (
						(statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
						OR statusID IN (0, 1)
					)
	    )
	    SELECT	SUM(ISNULL(Balance.Cash,0)) Cash,
			    SUM(ISNULL(Balance.Cash,0)) - @todayCustCash yesterday_Cash,
			    SUM(ISNULL(Balance.outstanding,0)) outstanding,
			    SUM(ISNULL(Balance.csOutstanding,0)) csOutstanding,
			    SUM(ISNULL(Balance.BingoOutstanding,0)) BingoOutstanding,
			    SUM(ISNULL(Balance.P2POutstanding,0)) P2POutstanding,
			    SUM(ISNULL(Balance.csTransfer,0)) csTransfer,
			    SUM(ISNULL(Balance.BingoTransfer,0)) BingoTransfer,
			    SUM(ISNULL(Balance.P2PTransfer,0)) P2PTransfer,
			    MAX(Balance.lastTxn) lastTxn
	    FROM Balance
    END 
    ELSE IF @roleid = 2
    BEGIN
	    SELECT @UsedCredit = SUM(credit)  
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK) 
	    WHERE roleid=1 
		     AND recommend = @custid
    		 
	    --Maxcredit 
	    SELECT @Mem_MaxCredit = ISNULL(maxcredit,0) FROM DBCUST.CustDB.dbo.CustAgent WITH (NOLOCK) 
	    WHERE  custid=@CustID 

	    SELECT 	@todayAgentCash = ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash  = ISNULL(SUM(winlost-actual_stake+playercomm),0)
	    FROM bettrans WITH (NOLOCK)
	    WHERE  recommend = @custid AND ruben = 1 AND bettype <= 19000 --AND bettype NOT BETWEEN 2101 AND 2499 AND bettype NOT BETWEEN 4001 AND 7999
			AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN (0,3))
		    AND CONVERT(DATE, winlostdate) = @today

		SELECT 	@todayAgentCash = @todayAgentCash + ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash  = @todayCustCash  + ISNULL(SUM(winlost-actual_stake+playercomm),0)
	    FROM bettransRNG WITH (NOLOCK)
	    WHERE recommend = @custid AND statusID NOT IN (0, 1) --AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
			AND CONVERT(DATE, winlostdate) = @today

		SELECT 	@todayAgentCash = @todayAgentCash + ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash  = @todayCustCash  + ISNULL(SUM(winlost-actual_stake+playercomm),0)
	    FROM bettransLC WITH (NOLOCK)
	    WHERE recommend = @custid AND statusID NOT IN (0, 1) --AND gameID BETWEEN 2401 AND 2499
			AND CONVERT(DATE, winlostdate) = @today
    		
	    ;with Balance
	    AS (	
		    SELECT 
			    SUM(CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
			    SUM(CASE WHEN bettype NOT IN (23001,23002) AND ruben=0 THEN actual_stake * apositiontaking ELSE 0 END) agentPositionTaking, 
			    SUM(CASE WHEN custid <> recommend AND ruben=1 THEN winlost-actual_stake+playercomm ELSE 0 END) customerCash,
			    SUM(CASE WHEN bettype NOT IN (23001,23002) AND ruben=0 THEN ABS(actual_stake) ELSE 0 END) customerOutstanding,
			    SUM(CASE WHEN bettype = 23002 AND ruben=0 THEN actual_stake ELSE 0 END) csOutstanding,			
			    SUM(CASE WHEN bettype = 23202 AND ruben=0 THEN actual_stake ELSE 0 END) BingoOutstanding,
			    SUM(CASE WHEN bettype = 23102 AND ruben=0 THEN actual_stake ELSE 0 END) P2POutstanding,
			    SUM(CASE WHEN bettype = 23001 AND ruben=0 THEN actual_stake ELSE 0 END) CSTransfer,			
			    SUM(CASE WHEN bettype = 23201 AND ruben=0 THEN actual_stake ELSE 0 END) BingoTransfer,
			    SUM(CASE WHEN bettype = 23101 AND ruben=0 THEN actual_stake ELSE 0 END) P2PTransfer,
			    MAX(transdate) lastTxn
		    FROM bettrans WITH(NOLOCK) 
		    WHERE recommend = @custid
					AND (
							(bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable <> 0) AND ruben =0)
							OR ruben <> 0
						)
					AND (
						(CONVERT(DATE, winlostdate) >= @yesterday AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN (0,3)))
						OR CONVERT(DATE, winlostdate) < @yesterday
					)
		    UNION ALL
		    SELECT 0 agentCash,
			    SUM(actual_stake*apositiontaking) agentPositionTaking, 
			    0 customerCash,
			    SUM(ABS(actual_stake)) customerOutstanding,
			    0 csOutstanding,
				0 BingoOutstanding,
			    0 P2POutstanding,
			    0 CSTransfer,
			    0 BingoTransfer,
			    0 P2PTransfer,
			    MAX(transdate) lastTxn
		    FROM translog WITH(NOLOCK)
		    WHERE statusid = 0
				AND recommend = @custid
			UNION ALL
			SELECT
				SUM(CASE WHEN custid=recommend AND statusID NOT IN (0, 1) THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
			    SUM(CASE WHEN statusID IN (0, 1) THEN actual_stake * apositiontaking ELSE 0 END) agentPositionTaking,
			    SUM(CASE WHEN custid<>recommend AND statusID NOT IN (0, 1) THEN winlost-actual_stake+playercomm ELSE 0 END) customerCash,
			    SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END) customerOutstanding,
			    0 csOutstanding,
				0 BingoOutstanding,
			    0 P2POutstanding,
			    0 CSTransfer,
			    0 BingoTransfer,
			    0 P2PTransfer,
			    MAX(transdate) lastTxn
		    FROM bettransRNG WITH(NOLOCK)
		    WHERE recommend = @custid
				--AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
				AND (
						(statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
						OR statusID IN (0, 1)
					)
			UNION ALL
			SELECT
				SUM(CASE WHEN custid=recommend AND statusID NOT IN (0, 1) THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
			    SUM(CASE WHEN statusID IN (0, 1) THEN actual_stake * apositiontaking ELSE 0 END) agentPositionTaking,
			    SUM(CASE WHEN custid<>recommend AND statusID NOT IN (0, 1) THEN winlost-actual_stake+playercomm ELSE 0 END) customerCash,
			    SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END) customerOutstanding,
			    0 csOutstanding,
				0 BingoOutstanding,
			    0 P2POutstanding,
			    0 CSTransfer,
			    0 BingoTransfer,
			    0 P2PTransfer,
			    MAX(transdate) lastTxn
		    FROM bettransLC WITH(NOLOCK)
		    WHERE recommend = @custid
				--AND gameID BETWEEN 2401 AND 2499
				AND (
						(statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
						OR statusID IN (0, 1)
					)
	    )
	    SELECT	SUM(ISNULL(Balance.agentCash,0)) agentCash,
			    SUM(ISNULL(Balance.agentCash,0)) - @todayAgentCash yesterday_agentCash,	
			    SUM(ISNULL(Balance.agentPositionTaking,0)) agentPositionTaking,
			    SUM(ISNULL(Balance.customerCash,0)) customerCash,
			    SUM(ISNULL(Balance.customerCash,0)) - @todayCustCash yesterday_customerCash,
			    SUM(ISNULL(Balance.customerOutstanding,0)) customerOutstanding,
			    SUM(ISNULL(Balance.csOutstanding,0)) csOutstanding,
			    SUM(ISNULL(Balance.bingoOutstanding,0)) BingoOutstanding,
			    SUM(ISNULL(Balance.P2POutstanding,0)) P2POutstanding,
			    SUM(ISNULL(Balance.csTransfer,0)) csTransfer,
			    SUM(ISNULL(Balance.BingoTransfer,0)) BingoTransfer,
			    SUM(ISNULL(Balance.P2PTransfer,0)) P2PTransfer,
			    MAX(Balance.lastTxn) lastTxn,
			    @UsedCredit AS agentUsedCredit,
			    @Mem_MaxCredit AS memberMaxCredit
	    FROM Balance 

    END
    ELSE IF @roleid = 3
    BEGIN
	    SELECT @UsedCredit = SUM(credit)  
	    FROM DBCUST.CustDB.dbo.custinfo WITH(NOLOCK) 
	    WHERE roleid=2 
		    AND mrecommend = @custid
    				
	    SELECT	@todayMasterCash = ISNULL(SUM(mwinlost+acomm-comm),0),
			    @todayAgentCash  = ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash   = ISNULL(SUM(winlost-actual_stake + playercomm),0)
	    FROM bettrans WITH (NOLOCK)
	    WHERE mrecommend = @custid AND ruben = 1 AND bettype <= 19000 --AND bettype NOT BETWEEN 2101 AND 2499 AND bettype NOT BETWEEN 4001 AND 7999
		    AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN (0,3))
			AND CONVERT(DATE, winlostdate) = @today

		SELECT	@todayMasterCash = @todayMasterCash + ISNULL(SUM(mwinlost+acomm-comm),0),
			    @todayAgentCash  = @todayAgentCash  + ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash   = @todayCustCash   + ISNULL(SUM(winlost-actual_stake + playercomm),0)
	    FROM bettransRNG WITH (NOLOCK)
	    WHERE mrecommend = @custid AND statusID NOT IN (0, 1) --AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
		    AND CONVERT(DATE, winlostdate) = @today

		SELECT	@todayMasterCash = @todayMasterCash + ISNULL(SUM(mwinlost+acomm-comm),0),
			    @todayAgentCash  = @todayAgentCash  + ISNULL(SUM(awinlost+comm-playercomm),0),
			    @todayCustCash   = @todayCustCash   + ISNULL(SUM(winlost-actual_stake + playercomm),0)
	    FROM bettransLC WITH (NOLOCK)
	    WHERE mrecommend = @custid AND statusID NOT IN (0, 1) --AND gameID BETWEEN 2401 AND 2499
		    AND CONVERT(DATE, winlostdate) = @today
    	
	    ;with Balance
	    AS (	
		    SELECT	SUM(CASE WHEN custid=mrecommend THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) masterCash,
				    SUM(CASE WHEN bettype NOT IN (23001,23002) AND ruben=0 THEN actual_stake * mpositiontaking ELSE 0 END) masterPositionTaking, 
				    SUM(CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
				    SUM(CASE WHEN custid <> recommend AND custid <> mrecommend AND ruben=1 THEN winlost-actual_stake+playercomm ELSE 0  END) customerCash,
				    SUM(CASE WHEN bettype NOT IN (23001,23002) AND custid <> recommend AND custid <> mrecommend AND ruben=0 THEN ABS(actual_stake) ELSE 0 END) customerOutstanding, 
				    SUM(CASE WHEN bettype = 23002 AND ruben=0 THEN actual_stake ELSE 0 END) csOutstanding,
				    SUM(CASE WHEN bettype = 23202 AND ruben=0 THEN actual_stake ELSE 0 END) BingoOutstanding,
				    SUM(CASE WHEN bettype = 23102 AND ruben=0 THEN actual_stake ELSE 0 END) P2POutstanding,
				    SUM(CASE WHEN bettype= 23001 AND ruben=0 THEN actual_stake ELSE 0 END) csTransfer,
				    SUM(CASE WHEN bettype= 23201 AND ruben=0 THEN actual_stake ELSE 0 END) BingoTransfer,
				    SUM(CASE WHEN bettype= 23101 AND ruben=0 THEN actual_stake ELSE 0 END) P2PTransfer,
				    MAX(transdate) lastTxn
		    FROM bettrans WITH(NOLOCK) 
		    WHERE mrecommend = @custid	
				AND (
						(bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable <> 0) AND ruben =0)
						OR ruben <> 0
					)
				AND (
						(CONVERT(DATE, winlostdate) >= @yesterday AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN (0,3)))
						OR CONVERT(DATE, winlostdate) < @yesterday
					)
		    UNION ALL
		    SELECT	0,
				    SUM(actual_stake * mpositiontaking) masterPositionTaking, 
				    0,
					0,
				    SUM(CASE WHEN custid <> mrecommend THEN ABS(actual_stake) ELSE 0 END) customerOutstanding, 
				    0 csOutstanding,
					0 BingoOutstanding,
					0 P2POutstanding,
					0 CSTransfer,
					0 BingoTransfer,
					0 P2PTransfer,
				    MAX(transdate) lastTxn
		    FROM translog WITH(NOLOCK)
		    WHERE statusid = 0
				AND mrecommend = @custid 
			UNION ALL
		    SELECT	
					SUM(CASE WHEN custid = mrecommend AND statusID NOT IN (0, 1) THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) masterCash,
				    SUM(CASE WHEN statusID IN (0, 1) THEN actual_stake * mpositiontaking ELSE 0 END) masterPositionTaking, 
				    SUM(CASE WHEN custid = recommend  AND statusID NOT IN (0, 1) THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
					SUM(CASE WHEN custid <> recommend AND custid <> mrecommend  AND statusID NOT IN (0, 1) THEN winlost-actual_stake+playercomm ELSE 0  END) customerCash,
				    SUM(CASE WHEN custid <> recommend AND custid <> mrecommend AND statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END) customerOutstanding, 
				    0 csOutstanding,
					0 BingoOutstanding,
					0 P2POutstanding,
					0 CSTransfer,
					0 BingoTransfer,
					0 P2PTransfer,
				    MAX(transdate) lastTxn
		    FROM bettransRNG WITH(NOLOCK)
		    WHERE mrecommend = @custid
				--AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
				AND (
						(statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
						OR statusID IN (0, 1)
					)
			UNION ALL
		    SELECT	
					SUM(CASE WHEN custid = mrecommend AND statusID NOT IN (0, 1) THEN winlost-actual_stake ELSE mwinlost+acomm-comm END) masterCash,
				    SUM(CASE WHEN statusID IN (0, 1) THEN actual_stake * mpositiontaking ELSE 0 END) masterPositionTaking, 
				    SUM(CASE WHEN custid = recommend  AND statusID NOT IN (0, 1) THEN winlost-actual_stake ELSE awinlost+comm-playercomm END) agentCash,
					SUM(CASE WHEN custid <> recommend AND custid <> mrecommend  AND statusID NOT IN (0, 1) THEN winlost-actual_stake+playercomm ELSE 0  END) customerCash,
				    SUM(CASE WHEN custid <> recommend AND custid <> mrecommend AND statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END) customerOutstanding, 
				    0 csOutstanding,
					0 BingoOutstanding,
					0 P2POutstanding,
					0 CSTransfer,
					0 BingoTransfer,
					0 P2PTransfer,
				    MAX(transdate) lastTxn
		    FROM bettransLC WITH(NOLOCK)
		    WHERE mrecommend = @custid
				--AND gameID BETWEEN 2401 AND 2499
				AND (
						(statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
						OR statusID IN (0, 1)
					)
	    )
	    SELECT	SUM(ISNULL(Balance.masterCash,0)) masterCash,
			    SUM(ISNULL(Balance.masterCash,0)) - @todayMasterCash yesterday_masterCash,
			    SUM(ISNULL(Balance.masterPositionTaking,0)) masterPositionTaking,
			    SUM(ISNULL(Balance.agentCash,0)) agentCash,
			    SUM(ISNULL(Balance.agentCash,0)) - @todayAgentCash yesterday_agentCash,
			    SUM(ISNULL(Balance.customerCash,0)) customerCash,
			    SUM(ISNULL(Balance.customerCash,0)) - @todayCustCash yesterday_customerCash, 
			    SUM(ISNULL(Balance.customerOutstanding,0)) customerOutstanding,
			    SUM(ISNULL(Balance.csOutstanding,0)) csOutstanding,
			    SUM(ISNULL(Balance.BingoOutstanding,0)) BingoOutstanding,
			    SUM(ISNULL(Balance.P2POutstanding,0)) P2POutstanding,
			    SUM(ISNULL(Balance.csTransfer,0)) csTransfer,
			    SUM(ISNULL(Balance.bingoTransfer,0)) BingoTransfer,
			    SUM(ISNULL(Balance.P2PTransfer,0)) P2PTransfer,
			    MAX(Balance.lastTxn) lastTxn,
			    @UsedCredit AS masterUsedCredit	
	    FROM Balance 
    	
    END
	DROP TABLE #SportBettype
    -- For Sportbook2
	EXEC Acc_CustSetting_StatusSettingSelect @CustID = @custid,@roleid = @roleid		    
END

GO

GRANT EXECUTE ON [dbo].[Age_CustomerSelAllInfo] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Age_CustomerSelAllInfo] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelAllInfo] TO [vnteam] AS [dbo]
GO