/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_CustomerBalanceSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:

	Example: EXEC Age_CustomerBalanceSel @CustID=24471545
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @UsedCredit MONEY, @Mem_MaxCredit MONEY, @Credit MONEY
	DECLARE @netPosition MONEY = 0 -- for member
    DECLARE @Credit_MAg_Min MONEY, @Credit_MAg_Max MONEY, 
		    @Credit_Ag_Min MONEY , @Credit_Ag_Max MONEY, 
		    @Credit_Mem_Min MONEY, @Credit_Mem_Max MONEY

	SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @Credit = credit
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid 

    IF @roleID=1 --for member
    BEGIN	
	    DECLARE @Credit_AllOtherMember MONEY, @Credit_Ag MONEY, @MaxCredit_Mem MONEY, @Credit_Ag_Bal MONEY
    		
		--Upline
	    SELECT	@Credit_Ag = ISNULL(credit, 0)
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @recommend	

	    --Member itself
	    SELECT @Credit_AllOtherMember = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci WITH (NOLOCK) WHERE recommend = @recommend AND RoleID = 1 AND CustID <> @CustID
    	
	    SELECT @MaxCredit_Mem = ISNULL(maxcredit,0) FROM DBCUST.CustDB.dbo.CustAgent WITH(NOLOCK) WHERE CustID = @recommend
    	
	    SELECT @Credit_Ag_Bal = ISNULL(@Credit_Ag,0) - ISNULL(@Credit_AllOtherMember,0)
	    
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
		SELECT	@Credit_MAg = ISNULL(credit, 0)
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @mrecommend	

	    --Agent Itself		
	    SELECT @Credit_AllOtherAgent = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci WITH(NOLOCK) WHERE mrecommend = @mrecommend AND RoleID = 2 AND Custid <> @custID
    	
	    SELECT @Credit_Ag_Max = ISNULL(@Credit_MAg,0) - ISNULL(@Credit_AllOtherAgent,0)	
	    SELECT @Credit_Ag_Min = ISNULL(SUM(credit),0)
	    FROM custinfo (NOLOCK) 
	    WHERE recommend = @custID AND RoleID=1
    		
	    SELECT @Credit_Mem_Min = ISNULL(MAX(credit),0) FROM DBCUST.CustDB.dbo.custinfo with(NOLOCK) WHERE recommend = @CustID AND Roleid=1
    END
    ELSE IF @roleID = 3 --for master
    BEGIN
	    DECLARE @Credit_AllOtherMaster MONEY, @Credit_SAg MONEY

	    --Upline
		SELECT	@Credit_SAg = ISNULL(credit, 0)
	    FROM custinfo WITH(NOLOCK)
	    WHERE custID = @srecommend	

	    --Master Itself
	    SELECT @Credit_AllOtherMaster = ISNULL(SUM(credit), 0) FROM DBCUST.CustDB.dbo.custinfo AS ci (NOLOCK) WHERE srecommend = @Srecommend AND RoleID = 3 AND custid <> @CustId
	    SELECT @Credit_MAg_Max = ISNULL(@Credit_SAg,0) - ISNULL(@Credit_AllOtherMaster,0)	
    	
	    SELECT @Credit_MAg_Min = ISNULL(SUM(CASE WHEN RoleID=2 THEN credit ELSE 0 END),0)
	    FROM custinfo (NOLOCK) 
	    WHERE mrecommend = @custID	
    END

    -------------------------------------------------------------------------
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
		@TotalCSOutstanding		MONEY

	IF @roleid = 1
	BEGIN
		SELECT @UsedCredit = 0

		SELECT 
			@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
			@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0)
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
		
		SELECT 
			@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
			@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0)
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

		SELECT 
			@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
			@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0)
		FROM dbo.bettrans WITH (NOLOCK)  
		WHERE mrecommend = @CustID
			AND bettype IN (23001, 23002, 23101, 23102, 23201, 23202)
			AND ruben = 0
    END

    IF @roleid = 1
    BEGIN
	    SELECT
			@custid AS CustID, 
			@Credit AS Credit,
			@netPosition AS netPosition,		
			@Credit_Mem_Max AS [MemMaxCredit_Max],

			SUM(memberCash)					AS Cash,
			SUM(yesterdayMemberCash)		AS yesterday_Cash,
			SUM(memberOutstanding)			AS outstanding,
			-- Casino, Bingo, P2P
			ISNULL(@TotalCSOutstanding, 0)	AS csOutstanding,
			ISNULL(@TotalCSTransfer, 0)		AS csTransfer
	    FROM #BalanceInfo
    END 
    ELSE IF @roleid = 2
    BEGIN
		SELECT
			@custid AS CustID, 
			@Credit AS Credit,
			@Credit_Ag_Min AS [AgentCredit_Min],
			@Credit_Ag_Max AS [AgentCredit_Max],
			@Credit_Mem_Min AS [MemMaxCredit_Min],

			SUM(agentCash)					AS agentCash,
			SUM(yesterdayAgentCash)			AS yesterday_agentCash,
			SUM(agentOutstanding)			AS agentPositionTaking,
			SUM(memberCash)					AS customerCash,
			SUM(yesterdayMemberCash)		AS yesterday_customerCash,
			SUM(memberOutstanding)			AS customerOutstanding,
			-- Casino, Bingo, P2P
			ISNULL(@TotalCSOutstanding, 0)	AS csOutstanding,
			ISNULL(@TotalCSTransfer, 0)		AS csTransfer,
			@UsedCredit						AS agentUsedCredit,
			@Mem_MaxCredit					AS memberMaxCredit
	    FROM #BalanceInfo
    END
    ELSE IF @roleid = 3
    BEGIN
		SELECT
			@custid AS CustID, 
			@Credit AS Credit,
			@Credit_MAg_Min AS [MasterCredit_Min],
			@Credit_MAg_Max AS [MasterCredit_Max],

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
			ISNULL(@TotalCSTransfer, 0)		AS csTransfer,
			@UsedCredit						AS masterUsedCredit
	    FROM #BalanceInfo
    END

	DROP TABLE #BalanceInfo
END
GO

