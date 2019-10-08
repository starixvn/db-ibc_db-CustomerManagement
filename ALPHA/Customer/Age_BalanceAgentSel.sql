/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Age_BalanceAgentSel
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]
		- 20191007@Johnson: remove credit info [redmine:#121538]
	Example: EXEC Age_BalanceAgentSel @CustID=1382167
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT
	
	SELECT @roleid = roleid
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 2

	IF @roleid <> 2 RETURN
  	
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
		@TotalCSTransfer		MONEY,
		@TotalCSOutstanding		MONEY
	
	SELECT 
		@TotalCSTransfer     = ISNULL(SUM(CASE WHEN bettype = 23001 THEN actual_stake ELSE 0 END),0),
		@TotalCSOutstanding  = ISNULL(SUM(CASE WHEN bettype = 23002 THEN actual_stake ELSE 0 END),0)
	FROM dbo.bettrans WITH (NOLOCK)  
	WHERE recommend = @CustID
		AND bettype IN (23001, 23002, 23101, 23102, 23201, 23202)
		AND ruben = 0
		
	SELECT
		@custid AS CustID, 		
		SUM(agentCash)					AS agentCash,
		SUM(yesterdayAgentCash)			AS yesterday_agentCash,
		SUM(agentOutstanding)			AS agentPositionTaking,
		SUM(memberCash)					AS customerCash,
		SUM(yesterdayMemberCash)		AS yesterday_customerCash,
		SUM(memberOutstanding)			AS customerOutstanding,
		-- Casino, Bingo, P2P
		ISNULL(@TotalCSOutstanding, 0)	AS csOutstanding,
		ISNULL(@TotalCSTransfer, 0)		AS csTransfer		
	FROM #BalanceInfo

	DROP TABLE #BalanceInfo
END
GO
