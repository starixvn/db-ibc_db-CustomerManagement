/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_BalanceMemberSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]

	Example: EXEC Age_BalanceMemberSel @CustID=1382337
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @Credit MONEY
	DECLARE @netPosition MONEY = 0 -- for member
    DECLARE @Credit_Mem_Max MONEY, @Credit_AllOtherMember MONEY, @Credit_Ag MONEY, @MaxCredit_Mem MONEY, @Credit_Ag_Bal MONEY

	SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @Credit = credit
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 1

	IF @roleid <> 1 RETURN
    		
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

	SELECT 
		@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
		@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0)
	FROM dbo.bettrans WITH (NOLOCK)  
	WHERE custid = @CustID
		AND bettype IN (23001, 23002, 23101, 23102, 23201, 23202)
		AND ruben = 0

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

	DROP TABLE #BalanceInfo
END
GO



