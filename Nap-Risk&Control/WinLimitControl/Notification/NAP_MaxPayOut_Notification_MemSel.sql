/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_MaxPayout_Notification_MemSel]
	@ProductId	TINYINT		= 0
   , @Username	VARCHAR(50)	= ''
AS
/*
Created: 20230829@Luke
Task: Implement Company Max Payout Notification [Redmine: #193288]
DB: DBCUST/CustDB
Original:
Revisions:
	- 20230829@Luke: Implement Company Max Payout Notification [Redmine: #193288]
					 Clone from NAP_WinLimit_Notification_MemSel
	- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
	- 20250122@Tacy: Offer direct member for super/master [Redmine: #215809]
	- 20251105@Dave: Adjust Live Casino PT & Commission [Redmine: #242260]

Param's Explanation:
	� @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	� @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @FromDate DATETIME = DATEADD(DAY, DATEDIFF(DAY, 1, GETDATE()),0) 
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	SELECT t.ProductID
		, wl.CustID
		, c.username
		, e.currency
		, wl.BettypeIDList
		, CASE WHEN s.isLicensee = 0 AND SiteLabel IS NOT NULL
				THEN c.site + ' (' + s.SiteLabel + ')' 
				ELSE c.site
			END AS site 
		, wl.TransID AS TicketRefNo
		, wl.WinlostDate AS TransactionTime
		, wl.WinAmt	AS ActualPayout
		, wl.MaxWinLimit AS CompanyMaxPayout
		, wl.LevelID
		, wl.GroupID
		, wl.LogID
	INTO #tmp
	FROM WinLimit_CustGameMonitoring_History AS wl WITH (NOLOCK)
		INNER JOIN Customer AS c WITH (NOLOCK) ON c.custid = wl.CustID
		INNER JOIN Site AS s WITH (NOLOCK) ON s.site = c.site
		INNER JOIN exchange AS e WITH (NOLOCK) ON c.currency = e.exchangeid
		CROSS APPLY(SELECT TOP 1 RealProductID as ProductID
					FROM dbo.f_CustSetting_SportBetTypeSettingMatrix(@isTest) s 
					WHERE s.SportType = wl.ProductID 
						AND s.isDeleted = 0 AND s.Site IN ('All', c.site)) t
	WHERE CASE
			WHEN @ProductId = 0
			THEN wl.IsNotified
			ELSE 0
		END = 0
		AND CASE
				WHEN @ProductId > 0
				THEN wl.ProductID
				ELSE @ProductId
			END = @ProductId
		AND CASE
				WHEN @ProductId > 0
					AND LEN(@Username) > 0
				THEN c.username
				ELSE @Username
			END = @Username
		AND s.isActive = 1
		AND wl.ActionID >= 200 AND wl.ActionID <= 255
		AND wl.ModifiedDate >= @FromDate
	IF EXISTS(SELECT TOP 1 1 FROM #tmp) 
	BEGIN 
		SELECT p.productid
				, p.productname
				, CustID
				, username
				, currency
				, BettypeIDList
				, site 
				, TicketRefNo
				, TransactionTime
				, ActualPayout
				, CompanyMaxPayout
				, LevelID
				, GroupID
				, LogID
		FROM #tmp t INNER JOIN DBPRO.bodb02.dbo.Products AS p WITH (NOLOCK) ON p.ProductID = t.ProductID
	END
	ELSE
		RETURN
END