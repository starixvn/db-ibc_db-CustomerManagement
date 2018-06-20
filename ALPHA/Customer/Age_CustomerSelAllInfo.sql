/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelAllInfo]
	@username VARCHAR(50),
	@uplineid INT = -1,
	@isInternalAgent BIT = 0
AS

/*
	Created: 20090122@nqminh
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - All Info

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
		- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
		- 20170517@Winnie: Apply color for closed accounts  - [Redmine:74494]
		- 20170703@Percy: Hotfix formula today/yesterday balance when getting data from bettrans [RedmineID: #79236]
		- 20171020@Percy: Apply core SP [RedmineID: #84690]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]	
		- 20180918@Winnie: Esports Product - [Redmine: #101526]	
		- 20180611@Elodie: Move all status of customer to Age_CustomerSelAllStatus SP [RedmineID: #58776]	

	Param's Explanation:
		• @username: username of customer that need to be viewed.   
		• @uplineId: the ID of the upline.
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @custid INT, @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @UsedCredit MONEY, @Mem_MaxCredit MONEY
    DECLARE @ClosedReason TINYINT

	DECLARE @netPosition MONEY = 0 -- for member

    SELECT @username = RTRIM(LTRIM(@username))

    SELECT @custid = custid, @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
	FROM custinfo WITH(NOLOCK)
    WHERE username = @username 
	   AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)

    ------20110721: If @isInternal = 1 then searching by nickname, else do not allow
    IF (@custid IS NULL) AND @isInternalAgent = 1
    BEGIN
	    SELECT @custid = custid , @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend
        FROM customer WITH (NOLOCK)
        WHERE username2 = @username
	       AND (srecommend = @uplineid OR mrecommend = @uplineid OR recommend = @uplineid)
    END
    --end

    --Check valid access!
    IF (@custid IS NULL) RETURN
    IF (@recommend <> @uplineid AND @mrecommend <> @uplineid AND @srecommend <> @uplineid) RETURN
    	
    DECLARE @upLineEnabled   BIT
    DECLARE @Credit_MAg_Min MONEY, @Credit_MAg_Max MONEY, 
		    @Credit_Ag_Min MONEY , @Credit_Ag_Max MONEY , 
		    @Credit_Mem_Min MONEY, @Credit_Mem_Max MONEY

    DECLARE @TotalMemberActive INT, @TotalMemberClosed INT, @TotalMemberSuspended INT,
		    @TotalAgentActive INT, @TotalAgentClosed INT, @TotalAgentSuspended INT		
        
    IF @roleID=1 --for member
    BEGIN	
	    DECLARE @Credit_AllOtherMember MONEY, @Credit_Ag MONEY, @MaxCredit_Mem MONEY, @Credit_Ag_Bal MONEY
    		
		--Upline
	    SELECT	@upLineEnabled = ISNULL(Enabled, 0)
			,	@Credit_Ag = ISNULL(credit, 0)
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @recommend	

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
		SELECT	@upLineEnabled = ISNULL(Enabled, 0)
			,	@Credit_MAg = ISNULL(credit, 0)
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @mrecommend	

	    --Agent Itself		
	    SELECT @Credit_AllOtherAgent = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci WITH(NOLOCK) WHERE mrecommend = @mrecommend AND RoleID = 2 AND Custid <> @custID
    	
	    SELECT @Credit_Ag_Max = ISNULL(@Credit_MAg,0) - ISNULL(@Credit_AllOtherAgent,0)	
	    SELECT @Credit_Ag_Min = ISNULL(SUM(credit),0), 
		       @TotalMemberActive = ISNULL(SUM(CASE WHEN Closed = 0 AND ISNULL(reject,0) = 0 THEN 1 ELSE 0 END), 0),
		       @TotalMemberClosed = ISNULL(SUM(CASE WHEN Closed = 1 THEN 1 ELSE 0 END), 0),
		       @TotalMemberSuspended = ISNULL(SUM(CASE WHEN ISNULL(reject,0) = 1 AND closed = 0 THEN 1 ELSE 0 END), 0) 
	    FROM custinfo (NOLOCK) 
	    WHERE recommend = @custID AND RoleID=1
    		
	    SELECT @Credit_Mem_Min = ISNULL(MAX(credit),0) FROM DBCUST.CustDB.dbo.custinfo with(NOLOCK) WHERE recommend = @CustID AND Roleid=1
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    DECLARE @Credit_AllOtherMaster MONEY, @Credit_SAg MONEY

	    --Upline
		SELECT	@upLineEnabled = ISNULL(Enabled, 0)
			,	@Credit_SAg = ISNULL(credit, 0)
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @srecommend	

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
    END
    
	IF @roleid=1
		SELECT @ClosedReason=ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE Custid = @custid
	ELSE
	BEGIN
		SELECT @ClosedReason=ClosedReason FROM DBACC.bodb02.dbo.CustLoginInfo WITH(NOLOCK) WHERE Custid = @custid	
	END

	-------------------------------------------------------------------------
    --General info
    SELECT	c.custid, ci.roleid, c.username, c.username2, c.firstname, c.lastname, c.phone, c.mobilephone, c.fax, ci.credit, ISNULL(@ClosedReason,0) AS ClosedReason, 
			ci.enabled,	ISNULL(@upLineEnabled,0) AS upLineEnabled, ci.closed, ci.reject AS suspended, @netPosition AS netPosition,
			c.creatdate, lastlogged, iplogin AS lastloginip, pwdexpiry, 
		
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
	    @TotalMemberSuspended AS [TotalMemSuspended]
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
    WHERE c.custid = @custid

	-- Balance Info
	CREATE TABLE #BalanceInfo
	(
		superCash	MONEY DEFAULT ((0)), yesterdaySuperCash	 MONEY DEFAULT ((0)), superOutstanding  MONEY DEFAULT ((0)),
		masterCash	MONEY DEFAULT ((0)), yesterdayMasterCash MONEY DEFAULT ((0)), masterOutstanding MONEY DEFAULT ((0)),
		agentCash	MONEY DEFAULT ((0)), yesterdayAgentCash	 MONEY DEFAULT ((0)), agentOutstanding  MONEY DEFAULT ((0)),
		memberCash	MONEY DEFAULT ((0)), yesterdayMemberCash MONEY DEFAULT ((0)), memberOutstanding MONEY DEFAULT ((0))
	)

	INSERT INTO #BalanceInfo
	(
		superCash,  yesterdaySuperCash,
		masterCash, yesterdayMasterCash,
		agentCash,  yesterdayAgentCash,
		memberCash, yesterdayMemberCash
	)
	EXEC dbo.Acc_CustomerSelCash @CustId = @CustId

	INSERT INTO #BalanceInfo
	(
		superOutstanding,
		masterOutstanding,
		agentOutstanding,
		memberOutstanding
	)
	EXEC dbo.Acc_CustomerSelOutstanding @CustId = @CustId

	-- Used Credit, last transdate, Casino, Bingo, P2P
	DECLARE
		@transdate				DATETIME,
		@TotalCSTransfer		MONEY,
		@TotalCSOutstanding		MONEY,
		@TotalBITransfer		MONEY,
		@TotalBIOutstanding		MONEY,
		@TotalP2PTransfer		MONEY,
		@TotalP2POutstanding	MONEY

	IF @roleid = 1
	BEGIN
		SELECT @UsedCredit = 0

		SELECT @transdate = MAX(transdate) FROM bettrans WITH (NOLOCK) WHERE custid = @custid

		SELECT 
			@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
			@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0),
			@TotalBITransfer     = ISNULL(SUM(CASE WHEN bettype = 23201 THEN actual_stake ELSE 0 END),0),
			@TotalBIOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23202 THEN actual_stake ELSE 0 END),0),
			@TotalP2PTransfer    = ISNULL(SUM(CASE WHEN bettype = 23101 THEN actual_stake ELSE 0 END),0),
			@TotalP2POutstanding = ISNULL(SUM(CASE WHEN bettype = 23102 THEN actual_stake ELSE 0 END),0)
		FROM dbo.bettrans WITH (NOLOCK)  
		WHERE custid = @CustID
			AND bettype IN (23001, 23002, 23101, 23102, 23201, 23202)
			AND ruben = 0
    END 
    ELSE IF @roleid = 2
    BEGIN
	    SELECT @UsedCredit = SUM(ISNULL(Credit, 0))
	    FROM DBCUST.CustDB.dbo.custinfo WITH (NOLOCK)
	    WHERE roleid = 1 AND recommend = @custid

		SELECT @Mem_MaxCredit = ISNULL(maxcredit,0)
		FROM DBCUST.CustDB.dbo.CustAgent WITH (NOLOCK) 
	    WHERE custid = @CustID 
		
		SELECT @transdate = MAX(transdate) FROM bettrans WITH (NOLOCK) WHERE recommend = @custid

		SELECT 
			@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
			@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0),
			@TotalBITransfer     = ISNULL(SUM(CASE WHEN bettype = 23201 THEN actual_stake ELSE 0 END),0),
			@TotalBIOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23202 THEN actual_stake ELSE 0 END),0),
			@TotalP2PTransfer    = ISNULL(SUM(CASE WHEN bettype = 23101 THEN actual_stake ELSE 0 END),0),
			@TotalP2POutstanding = ISNULL(SUM(CASE WHEN bettype = 23102 THEN actual_stake ELSE 0 END),0)
		FROM dbo.bettrans WITH (NOLOCK)  
		WHERE recommend = @CustID
			AND bettype IN (23001, 23002, 23101, 23102, 23201, 23202)
			AND ruben = 0
    END
    ELSE IF @roleid = 3
    BEGIN
	    SELECT @UsedCredit = SUM(ISNULL(Credit, 0))
	    FROM DBCUST.CustDB.dbo.custinfo WITH (NOLOCK) 
	    WHERE roleid = 2 AND mrecommend = @custid

		SELECT @transdate = MAX(transdate) FROM bettrans WITH (NOLOCK) WHERE mrecommend = @custid
		
		SELECT 
			@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
			@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0),
			@TotalBITransfer     = ISNULL(SUM(CASE WHEN bettype = 23201 THEN actual_stake ELSE 0 END),0),
			@TotalBIOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23202 THEN actual_stake ELSE 0 END),0),
			@TotalP2PTransfer    = ISNULL(SUM(CASE WHEN bettype = 23101 THEN actual_stake ELSE 0 END),0),
			@TotalP2POutstanding = ISNULL(SUM(CASE WHEN bettype = 23102 THEN actual_stake ELSE 0 END),0)
		FROM dbo.bettrans WITH (NOLOCK)  
		WHERE mrecommend = @CustID
			AND bettype IN (23001, 23002, 23101, 23102, 23201, 23202)
			AND ruben = 0
    END

	-- Return balance
    IF @roleid = 1
    BEGIN
	    SELECT
			SUM(memberCash)					AS Cash,
			SUM(yesterdayMemberCash)		AS yesterday_Cash,
			SUM(memberOutstanding)			AS outstanding,
			-- Casino, Bingo, P2P
			ISNULL(@TotalCSOutstanding, 0)	AS csOutstanding,
			ISNULL(@TotalBIOutstanding, 0)	AS BingoOutstanding,
			ISNULL(@TotalP2POutstanding, 0)	AS P2POutstanding,
			ISNULL(@TotalCSTransfer, 0)		AS csTransfer,
			ISNULL(@TotalBITransfer, 0)		AS BingoTransfer,
			ISNULL(@TotalP2PTransfer, 0)	AS P2PTransfer,
			@transdate						AS lastTxn
	    FROM #BalanceInfo
    END 
    ELSE IF @roleid = 2
    BEGIN
		SELECT
			SUM(agentCash)					AS agentCash,
			SUM(yesterdayAgentCash)			AS yesterday_agentCash,
			SUM(agentOutstanding)			AS agentPositionTaking,
			SUM(memberCash)					AS customerCash,
			SUM(yesterdayMemberCash)		AS yesterday_customerCash,
			SUM(memberOutstanding)			AS customerOutstanding,
			-- Casino, Bingo, P2P
			ISNULL(@TotalCSOutstanding, 0)	AS csOutstanding,
			ISNULL(@TotalBIOutstanding, 0)	AS BingoOutstanding,
			ISNULL(@TotalP2POutstanding, 0)	AS P2POutstanding,
			ISNULL(@TotalCSTransfer, 0)		AS csTransfer,
			ISNULL(@TotalBITransfer, 0)		AS BingoTransfer,
			ISNULL(@TotalP2PTransfer, 0)	AS P2PTransfer,
			@transdate						AS lastTxn,
			@UsedCredit						AS agentUsedCredit,
			@Mem_MaxCredit					AS memberMaxCredit
	    FROM #BalanceInfo
    END
    ELSE IF @roleid = 3
    BEGIN
		SELECT
			SUM(masterCash)					AS masterCash,
			SUM(yesterdayMasterCash)		AS yesterday_masterCash,
			SUM(masterOutstanding)			AS masterPositionTaking,
			SUM(agentCash)					AS agentCash,
			SUM(yesterdayAgentCash)			AS yesterday_agentCash,
			SUM(memberCash)					AS customerCash,
			SUM(yesterdayMemberCash)		AS yesterday_customerCash,
			SUM(memberOutstanding)			AS customerOutstanding,
			-- Casino, Bingo, P2P
			ISNULL(@TotalCSOutstanding, 0)	AS csOutstanding,
			ISNULL(@TotalBIOutstanding, 0)	AS BingoOutstanding,
			ISNULL(@TotalP2POutstanding, 0)	AS P2POutstanding,
			ISNULL(@TotalCSTransfer, 0)		AS csTransfer,
			ISNULL(@TotalBITransfer, 0)		AS BingoTransfer,
			ISNULL(@TotalP2PTransfer, 0)	AS P2PTransfer,
			@transdate						AS lastTxn,
			@UsedCredit						AS masterUsedCredit
	    FROM #BalanceInfo
    END

	DROP TABLE #BalanceInfo
END
GO