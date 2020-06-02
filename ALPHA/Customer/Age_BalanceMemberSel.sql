/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_BalanceMemberSel]
	@CustID INT
AS
/*
	Created: 20180627@Elodie
	DB: DBAGE/bodb02
	Task: Left menu - Search customer - Balance Info

	Revisions:
		- 20180627@Elodie: Left menu - Search customer - Balance Info [Redmine: #58776]
		- 20190723@Percy: Member level - Don't calculate Cash & Outstanding amount [RedmineID: #117334]
		- 20191008@Johnson: remove credit info [redmine:#121538]
		- 20200602@Percy: Separate 3rdPendingTransfer from Cash and Balance [RedmineID: #135200]

	Example: EXEC Age_BalanceMemberSel @CustID=1382337
*/

BEGIN
    SET NOCOUNT ON

    DECLARE @roleid TINYINT
	
	SELECT @roleid = roleid
	FROM dbo.custinfo WITH(NOLOCK)
    WHERE custid = @custid AND roleid = 1

	IF @roleid <> 1 RETURN    	
	
	-- Net Balance: get data from other SP

    -------------------------------------------------------------------------
	-- Balance Info
	CREATE TABLE #BalanceInfo
	(
		superCash	MONEY DEFAULT ((0)), yesterdaySuperCash	 MONEY DEFAULT ((0)),
		masterCash	MONEY DEFAULT ((0)), yesterdayMasterCash MONEY DEFAULT ((0)),
		agentCash	MONEY DEFAULT ((0)), yesterdayAgentCash	 MONEY DEFAULT ((0)),
		memberCash	MONEY DEFAULT ((0)), yesterdayMemberCash MONEY DEFAULT ((0)),
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

	SELECT
		@custid AS CustID,		
		SUM(yesterdayMemberCash) AS yesterday_Cash
		-- Cash & Outstanding & 3rdPendingTransfer: get from other SP
	FROM #BalanceInfo

	DROP TABLE #BalanceInfo
END
GO
