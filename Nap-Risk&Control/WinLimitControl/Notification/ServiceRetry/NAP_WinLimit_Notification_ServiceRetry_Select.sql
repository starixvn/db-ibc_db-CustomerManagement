/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_ServiceRetry_Select]
(
	@logIDs VARCHAR(MAX)
)
AS
/*
	Created: 20210410@Helen
	Task : 153241 - Win Limit Control - Notification - RetryService
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210410@Helen: Support retry notification server - [Redmine:153241]
			
	Param's Explanation:
	• @logIDs: '63252,63254' (from table WinLimit_CustGameMonitoring_History)
		
*/
BEGIN

	CREATE TABLE #logIDs (LogID BIGINT)

	INSERT INTO #logIDs (LogID)
	SELECT val
	FROM dbo.f_SplitString (@logIDs,',')
	OPTION (MAXRECURSION 0)

	SELECT 
		lg.logid
		, wl.IsNotified
		, wl.custid
		, c.username
		, CASE
			WHEN e.exchangeid = 20
			THEN 'UUS'
			ELSE e.currency
		 END AS               code
		, ag.site
		, s.isLicensee AS      IsDeposit
		, p.ProductName
		, p.ProductId
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
	FROM WinLimit_CustGameMonitoring_History AS wl WITH (NOLOCK)
		INNER JOIN #logIDs lg ON lg.LogID = wl.LogID
		INNER JOIN Customer AS c WITH (NOLOCK) ON c.custid = wl.CustID
		INNER JOIN Customer AS ag WITH (NOLOCK) ON ag.custid = c.recommend
		INNER JOIN Site AS S WITH (NOLOCK) ON S.site = ag.site
		INNER JOIN DBPRO.bodb02.dbo.Products AS p WITH (NOLOCK) ON p.ProductID = wl.ProductID
		INNER JOIN Winlimit_LevelSetting AS l WITH (NOLOCK) ON l.LevelId = wl.LevelId
		INNER JOIN exchange AS e WITH (NOLOCK) ON c.currency = e.exchangeid
	WHERE IsNotified = 1

	DROP TABLE #logIDs
END	