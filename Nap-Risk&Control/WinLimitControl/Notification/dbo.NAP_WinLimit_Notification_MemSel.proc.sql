/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_MemSel]
	@ProductId    TINYINT     = 0
   , @Username     VARCHAR(50) = ''
AS
/*
Created: 20150702@bobby.nguyen
Task : #35215 - Win Limit Control - Notification select member
DB: DBCUST.CustDB
Original:
Revisions:
	- 20150702@bobby.nguyen: Initial
	- 20160507@Patrick: #57213 - Voidbridge integration
	- 20160523@Helen: Hardcode for UUS - [Redmine: 57940]
	- 20160524@Helen: Change condition to send email - [Redmine: 57940]
	- 20160701@Robert: CWL - Phase 2 - Support RED and Yellow level - [Redmine: 57722]
	- 20160802@Robert: CWL Phase 2 - Wrong Exchange Rate using in the email notification - [Redmine: 61839]
	- 20160802@Robert: CWL Phase 2 - email notification Enhancement - [Redmine: 62253]
	- 20161027@Robert: CWL Phase 3 - email notification Enhancement - [Redmine: 61220]
	- 20170306@Robert: CWL Phase 3 - email notification Enhancement - [Redmine: 61220]
	- 20170306@Helen: CWL Phase 3A - email notification Enhancement - [Redmine: 72604]
	- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332]
	- 20170808@Robert: CWL Phase 4 - Support Loosing Limit notification, email template and enhancement requests from NSD team [Redmine: 72870]
	- 20180816@Robert: Poker Games - CWL Integration 
	- 20180918@Robert: Macau Games - CWL Integration [Redmine: 101546]
	- 20230104@Tacy: CWL - Split 789y Site [RedmineID: #182390]
	- 20230830@Luke: Apply Company Max Payout rules per ticket [Redmine: #193014]
	- 20230829@Luke: Implement Company Max Payout Notification [Redmine: #193288]
	- 20231031@Tacy: CWL - Support to show suspend information for suspended members [Redmine: #196155]
	- 20250122@Tacy: Offer direct member for super/master [Redmine: #215809]

Param's Explanation:
	� @ErrCode:
		= 0: Transaction recorded successfully.
		> 0: Specific Error.
	� @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @FromDate DATETIME = DATEADD(DAY, DATEDIFF(DAY, 1, GETDATE()),0) 

    SELECT wl.custid
	    , c.username
	    , CASE
			WHEN e.exchangeid = 20
			THEN 'UUS'
			ELSE e.currency
		 END AS               code
	    , CASE WHEN s.isLicensee=0 AND SiteLabel IS NOT NULL
				THEN c.site + ' (' + s.SiteLabel + ')' 
				ELSE c.site
		END AS site
	    , s.isLicensee AS      IsDeposit
	    , wl.ProductID
	    , wl.GroupID
	    , CASE
			WHEN wl.Levelid = 1
			THEN wl.MaxWinLimitSetting.value
				('(/MaxWinLimitSetting/@Level1)[1]', 'MONEY')
			WHEN wl.LevelID = 2
			THEN wl.MaxWinLimitSetting.value
				('(/MaxWinLimitSetting/@Level2)[1]', 'MONEY')
			WHEN wl.LevelID = 3
			THEN wl.MaxWinLimitSetting.value
				('(/MaxWinLimitSetting/@Level3)[1]', 'MONEY')
			WHEN wl.LevelID = 101
			THEN wl.MaxWinLimitSetting.value
				('(/MaxWinLimitSetting/@Level101)[1]', 'MONEY')
			WHEN wl.LevelID = 102
			THEN wl.MaxWinLimitSetting.value
				('(/MaxWinLimitSetting/@Level102)[1]', 'MONEY')
		 END AS               WinlimitAmount
	    , wl.TotalWinAmt AS    TotalWinAmt_OriginalCurrency
	    , wl.TotalWinAmt_RM AS TotalWinAmt_BaseCurrency
	    , wl.ModifiedDate
	    , wl.WinlostDate
	    , wl.LevelId
	    , l.LevelName
	    , wl.BettypeIDList
		, CASE WHEN wl.ActionID IN (6,7) THEN 1 ELSE 0 END AS IsSuspended
	INTO #tmp
    FROM WinLimit_CustGameMonitoring_History AS wl WITH (NOLOCK)
	   INNER JOIN Customer AS c WITH (NOLOCK) ON c.custid = wl.CustID
	   INNER JOIN Site AS S WITH (NOLOCK) ON S.site = c.site
	   INNER JOIN Winlimit_LevelSetting AS l WITH (NOLOCK) ON l.LevelId = wl.LevelId
	   INNER JOIN exchange AS e WITH (NOLOCK) ON c.currency = e.exchangeid
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
		AND S.isActive = 1
		AND wl.ActionID < 200 
		AND wl.ModifiedDate >= @FromDate

	IF EXISTS (SELECT TOP 1 1 FROM #tmp)
	BEGIN
		SELECT custid
	    , username
	    , code
	    , site
	    , IsDeposit
		, p.ProductName
	    , p.ProductID
	    , GroupID
	    , WinlimitAmount
	    , TotalWinAmt_OriginalCurrency
	    , TotalWinAmt_BaseCurrency
	    , ModifiedDate
	    , WinlostDate
	    , LevelId
	    , LevelName
	    , BettypeIDList
		, IsSuspended
		FROM #tmp t 
			INNER JOIN DBPRO.bodb02.dbo.Products AS p WITH (NOLOCK) ON p.ProductID = t.ProductID
	END
	ELSE
		RETURN  
END