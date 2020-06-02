/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_BalanceMemberSel]
	@CustId					INT
	,@Balance				MONEY = 0 OUTPUT
	,@NetPosition			MONEY = 0 OUTPUT
	,@3rdPendingTransfer	MONEY = 0 OUTPUT
AS

/*
	Created: 20190723@Percy
	DB: DBTXN.bodb02
	Task: Get a specific member's balance
		
	Revisions:
		- 20190723@Percy: Initialize SP [RedmineID: #117334]
		- 20200602@Percy: Add output param: @3rdPendingTransfer [RedmineID: #135200]
*/

BEGIN
	SET NOCOUNT ON

	-- balance tables
	SELECT @Balance = (cs.Balance + cc.Balance + co.Balance + ct.Balance) - (ds.Balance + dc.Balance + do.Balance + dt.Balance)
	FROM dbo.BalCreditSports				cs WITH(NOLOCK)
		INNER JOIN dbo.BalCreditCasino 		cc WITH(NOLOCK)	ON cs.custid = cc.custid
		INNER JOIN dbo.BalCreditOthers 		co WITH(NOLOCK) ON cs.custid = co.custid
		INNER JOIN dbo.BalCreditTransfer	ct WITH(NOLOCK) ON cs.custid = ct.custid
		INNER JOIN dbo.BalDebitSports		ds ON cs.custid = ds.custid
		INNER JOIN dbo.BalDebitCasino		dc ON cs.custid = dc.custid
		INNER JOIN dbo.BalDebitOthers		do ON cs.custid = do.custid
		INNER JOIN dbo.BalDebitTransfer		dt ON cs.custid = dt.custid
	WHERE cs.custid = @CustId
	
	-- netPosition
	SELECT @NetPosition = SUM(Credit - Debit) FROM dbo.BalNetPosition WHERE CustID = @CustId

	-- 3rd Pending Transfer
	SELECT @3rdPendingTransfer = -SUM(winlost-actual_stake)
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE custid = @CustId
		AND bettype IN (21008, 21009) -- BBIN Transfer
	
	-- Return data
	SELECT @Balance = ISNULL(@Balance, 0), @NetPosition = ISNULL(@NetPosition, 0), @3rdPendingTransfer = ISNULL(@3rdPendingTransfer, 0)
END
GO