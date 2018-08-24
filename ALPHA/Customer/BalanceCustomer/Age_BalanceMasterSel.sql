/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[Age_BalanceMasterSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]

	Example: EXEC Age_BalanceMasterSel @CustID=24471545
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @Credit MONEY, @UsedCredit MONEY
    DECLARE @Credit_MAg_Min MONEY, @Credit_MAg_Max MONEY
	DECLARE @Credit_AllOtherMaster MONEY, @Credit_SAg MONEY
		  
	SELECT @roleid = roleid, @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @Credit = credit
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 3

	IF @roleid <> 3 RETURN

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

	DECLARE
		@transdate				DATETIME,
		@TotalCSTransfer		MONEY,
		@TotalCSOutstanding		MONEY
	
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

	DROP TABLE #BalanceInfo
END
GO
