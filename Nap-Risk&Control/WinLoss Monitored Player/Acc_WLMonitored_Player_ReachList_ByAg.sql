/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Player_ReachList_ByAg
	 @AgentID		 INT
	,@Sporttype		 SMALLINT = 0
	,@FromDate		 DATETIME
	,@ToDate		 DATETIME
	,@LimitType		 TINYINT = 0
	,@XMLReachList	 VARCHAR(MAX) OUTPUT
AS  
/*  
	Created:	20220523@Eden
	Task:		View Reached threshold accounts
	DB:			DBAGE/bodb02
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	
		- @LimitType : 
				= 1: Global
				= 2: Personal
				= 0: All

	Sample:
	DECLARE @XMLReachList	 VARCHAR(MAX)
	EXEC Acc_WLMonitored_Player_ReachList_ByAg 
		    @AgentID	= 1176086	
			,@FromDate = '2022/05/01'
			,@ToDate = '2022/07/30'
			,@LimitType = 2
			,@XMLReachList = @XMLReachList OUTPUT
	SELECT CONVERT(XML,@XMLReachList) AS XMLReachList
	
*/  
BEGIN 
	CREATE TABLE #WLMonitored_Player_History(
		[CustID] [int],
		[AccumWL] [money],
		[WinningThreshold] [money],
		[LosingThreshold] [money],
		[SettingType] [tinyint],
		[CreatedDate] [datetime],
		[ReachType] [tinyint]
	)

	CREATE TABLE #TempHistory(
		[CustID] [int],
		[ReachedCnt] [int],
		[AccumWL] [money],
		[WinningThreshold] [money],
		[LosingThreshold] [money],
		[LastLimitTypeReach] [tinyint],
		[CreatedDate] [datetime],
		[WinningReachedCnt] [int],
		[LosingReachedCnt] [int]
	)
	
	INSERT INTO #WLMonitored_Player_History(CustID,AccumWL,WinningThreshold,LosingThreshold,SettingType,CreatedDate,ReachType)
	SELECT ci.CustID, w.AccumWL, w.WinningThreshold, w.LosingThreshold, w.SettingType, w.CreatedDate, w.ReachType
	FROM dbo.WLMonitored_Player_History w WITH(NOLOCK)
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON ci.custid = w.custid
	WHERE ci.recommend = @AgentID
		AND sporttype = @Sporttype
		AND ci.roleid = 1
		AND w.CreatedDate >= @FromDate
		AND w.CreatedDate < @ToDate + 1
		AND (w.SettingType = @LimitType OR @LimitType = 0 )

	;WITH TMP AS(
	SELECT CustID, CreatedDate,WinningThreshold,LosingThreshold,SettingType,AccumWL
		, ROW_NUMBER() OVER (PARTITION BY CustID ORDER BY CreatedDate DESC,WinningThreshold DESC,LosingThreshold DESC,SettingType DESC,AccumWL DESC) AS RN
		, ROW_NUMBER() OVER (PARTITION BY CustID ORDER BY CreatedDate,WinningThreshold,LosingThreshold,SettingType,AccumWL) AS RN2
		, SUM(CASE WHEN ReachType = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY CustID) AS  WinningReachedCnt
		, SUM(CASE WHEN ReachType = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY CustID) AS  LosingReachedCnt
	FROM #WLMonitored_Player_History
	)
	INSERT INTO #TempHistory(CustID,ReachedCnt,AccumWL,WinningThreshold,LosingThreshold,LastLimitTypeReach,CreatedDate,WinningReachedCnt,LosingReachedCnt)
	SELECT t.custid,
		RN2 AS ReachedCnt,
		t.AccumWL,
		t.WinningThreshold,
		t.LosingThreshold,
		t.SettingType AS LastLimitTypeReach,
		t.CreatedDate,
		t.WinningReachedCnt,
		t.LosingReachedCnt
	FROM TMP t
	WHERE RN = 1

	SELECT @XMLReachList =
							(
								SELECT CustID
									,ReachedCnt AS Cnt
									,AccumWL,WinningThreshold,LosingThreshold,LastLimitTypeReach,CreatedDate
									,WinningReachedCnt AS WCnt
									,LosingReachedCnt AS LCnt
								FROM #TempHistory
								FOR XML RAW('R'), ROOT ('ROOT')
							)

	DROP TABLE #TempHistory
	DROP TABLE #WLMonitored_Player_History
END
GO
