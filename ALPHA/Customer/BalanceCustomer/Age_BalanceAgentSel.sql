/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_BalanceAgentSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]

	Example: EXEC Age_BalanceAgentSel @CustID=1382167
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @UsedCredit MONEY, @Mem_MaxCredit MONEY, @Credit MONEY
    DECLARE @Credit_Ag_Min MONEY , @Credit_Ag_Max MONEY, @Credit_Mem_Min MONEY
	DECLARE @Credit_AllOtherAgent MONEY, @Credit_MAg MONEY

	SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @Credit = credit
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 2

	IF @roleid <> 2 RETURN
  
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

	DROP TABLE #BalanceInfo
END
GO
