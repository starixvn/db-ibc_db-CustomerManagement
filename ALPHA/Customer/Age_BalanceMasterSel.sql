/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_BalanceMasterSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]
		- 20190918@Percy: Remove inactive products [RedmineID: #118699]
		- 20191008@Johnson: remove credit info [redmine:#121538]
		- 20200602@Percy: Separate 3rdPendingTransfer from Cash and Balance [RedmineID: #135200]

	Example: EXEC Age_BalanceMasterSel @CustID=24471545
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT
		  
	SELECT @roleid = roleid
	FROM custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 3

	IF @roleid <> 3 RETURN

    -------------------------------------------------------------------------
	-- Balance Info
	CREATE TABLE #BalanceInfo
	(
		superCash	MONEY DEFAULT ((0)), yesterdaySuperCash	 MONEY DEFAULT ((0)), superOutstanding  MONEY DEFAULT ((0)),
		masterCash	MONEY DEFAULT ((0)), yesterdayMasterCash MONEY DEFAULT ((0)), masterOutstanding MONEY DEFAULT ((0)),
		agentCash	MONEY DEFAULT ((0)), yesterdayAgentCash	 MONEY DEFAULT ((0)), agentOutstanding  MONEY DEFAULT ((0)),
		memberCash	MONEY DEFAULT ((0)), yesterdayMemberCash MONEY DEFAULT ((0)), memberOutstanding MONEY DEFAULT ((0)),
		[3rdPendingTransfer] MONEY DEFAULT ((0))
	)

	INSERT INTO #BalanceInfo
	(
		superCash,  yesterdaySuperCash,
		masterCash, yesterdayMasterCash,
		agentCash,  yesterdayAgentCash,
		memberCash, yesterdayMemberCash,
		[3rdPendingTransfer]
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

	SELECT
		@custid AS CustID, 
		
		SUM(masterCash)					AS masterCash,
		SUM(yesterdayMasterCash)		AS yesterday_masterCash,
		SUM(masterOutstanding)			AS masterPositionTaking,
		SUM(agentCash)					AS agentCash,
		SUM(yesterdayAgentCash)			AS yesterday_agentCash,
		SUM(memberCash)					AS customerCash,
		SUM(yesterdayMemberCash)		AS yesterday_customerCash,
		SUM(memberOutstanding)			AS customerOutstanding,
		SUM([3rdPendingTransfer])		AS [3rdPendingTransfer]
	FROM #BalanceInfo

	DROP TABLE #BalanceInfo
END
GO