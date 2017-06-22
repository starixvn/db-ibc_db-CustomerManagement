USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerTotalAmountSel]    Script Date: 01/19/2016 14:25:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_CustomerTotalAmountSel]
	@custid			INT
	,@TotalAmt		MONEY = 0 OUTPUT
AS
/*
	Creator: Elodie
	Date: 20150612
	Task: Get total amount by custid
	Revisions:
		- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
		- 20160118@Kathy: get balance from bettransRNG & bettransLC [Redmine:#50674]
*/
BEGIN	
	DECLARE @totalAmt_bettransRNG	MONEY = 0
			,@totalAmt_bettransLC	MONEY = 0
			,@totalAmt_translog		MONEY = 0
			,@yesterday				DATE
	
	SET @yesterday = CONVERT(DATE,GETDATE() - 1)
	
	-- translog
    SELECT	@totalAmt_translog = SUM(-actual_stake)
    FROM	dbo.translog WITH(NOLOCK)
    WHERE	custid = @CustId
			AND statusID = 0
			
	-- bettransRNG
	SELECT	@totalAmt_bettransRNG = SUM(winlost - actual_stake + playercomm)
	FROM	dbo.bettransRnG WITH(NOLOCK)
	WHERE	custid = @custID 
			AND IsSum=0
			
	-- bettransLC
	SELECT	@totalAmt_bettransLC = SUM(winlost - actual_stake + playercomm)
	FROM	dbo.bettransLC WITH(NOLOCK)
	WHERE	custid = @custID 
			AND IsSum=0
  
	-- bettrans
	SELECT  @TotalAmt = sum(winlost-actual_stake+playercomm)
    FROM	dbo.bettrans b WITH(NOLOCK)
    WHERE	custid = @CustID
			AND (
					(b.bettype NOT IN (801,802,803,804,805,806)
					AND ruben =0) 
					OR ruben <> 0
					)
    
	SET @TotalAmt = ISNULL(@TotalAmt,0)
					+ ISNULL(@totalAmt_translog,0) 
					+ ISNULL(@totalAmt_bettransRNG,0) 
					+ ISNULL(@totalAmt_bettransLC,0) 
END




GO
GRANT EXECUTE ON [dbo].[Acc_CustomerTotalAmountSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerTotalAmountSel] TO [bodbExtAccNet] AS [dbo]