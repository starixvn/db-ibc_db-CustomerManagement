USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[Task_LimitLoss_Setting_TotalBalanceUpd_Job]
AS
/*
	Created: Elodie
	Date: 20140522
	Task: Update total balance
	DB: DBAGE/bodb_AGE

	Revisions:
		- 20140620@Dom: Support Yesterday balance [Redmine: #17906]
		- 20170915@Elodie: Support Group Headline Setting [Redmine: #82892]

	Parameter's explaination: 
		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #BalanceCust (CustID INT PRIMARY KEY, NewTotalBalance MONEY, YesterdayTotalBalance MONEY, NewLevelID TINYINT)
	CREATE TABLE #BalanceGroupHeadline (GroupHeadlineID INT PRIMARY KEY, NewTotalBalance MONEY, YesterdayTotalBalance MONEY, NewLevelID TINYINT)
	
	DECLARE @MaxLevel TINYINT, @i TINYINT
	SELECT @i = min(LevelID), @MaxLevel = max(LevelID) FROM LimitLoss_ActionConfig WITH (NOLOCK)

	CREATE TABLE #Cust_LimitLoss_Setting(custid INT, srecommend INT, mrecommend INT, recommend INT, roleId TINYINT)

	-- super
	INSERT INTO #Cust_LimitLoss_Setting (custid, srecommend, mrecommend, recommend, roleId)
	SELECT c.srecommend, c.srecommend, c.mrecommend, c.recommend, 4
	FROM dbo.LimitLoss_Setting s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON s.custid = c.srecommend
	WHERE c.roleid = 2

	-- master
	INSERT INTO #Cust_LimitLoss_Setting (custid, srecommend, mrecommend, recommend, roleId)
	SELECT c.mrecommend, c.srecommend, c.mrecommend, c.recommend, 3
	FROM dbo.LimitLoss_Setting s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON s.custid = c.mrecommend
	WHERE c.roleid = 2

	-- agent
	INSERT INTO #Cust_LimitLoss_Setting (custid, srecommend, mrecommend, recommend, roleId)
	SELECT c.recommend, c.srecommend, c.mrecommend, c.recommend, 2
	FROM dbo.LimitLoss_Setting s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON s.custid = c.recommend
	WHERE c.roleid = 2

	--------INSERT/DELETE LimitLoss_Setting when GroupHeadline is changed-------------------------
	INSERT INTO dbo.LimitLoss_Setting(CustID, MaxLoss)
	SELECT custid, NULL
	FROM #Cust_LimitLoss_Setting cs
	WHERE NOT EXISTS (SELECT 1 FROM LimitLoss_Setting WITH (NOLOCK) WHERE CustID = cs.custid)
	        
	DELETE cs
	FROM LimitLoss_Setting cs WITH (ROWLOCK,UPDLOCK)  
	WHERE NOT EXISTS (SELECT 1 FROM #Cust_LimitLoss_Setting WITH (NOLOCK) WHERE CustID = cs.custid)
		AND cs.MaxLoss IS NULL

	/* Balance Info */
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM bodb02.dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)

	/* for bettransRnG/bettransLC:
		winlostdate < yesterday: get sum tickets on bettrans
		winlostdate >= yesterday: get detail tickets on bettransRnG/LC
	*/
	DECLARE @today SMALLDATETIME, @yesterday SMALLDATETIME
	SELECT  @today		= CONVERT(DATE, GETDATE())
	SELECT  @yesterday	= DATEADD(DAY, -1, @today)
	
	DECLARE @recommend TABLE (recommend INT) -- using index on bettrans/bettransRnG/bettransLC
	INSERT INTO @recommend (recommend)
	SELECT DISTINCT recommend FROM #Cust_LimitLoss_Setting

	CREATE TABLE #tmpBalance
	(
		custid INT, recommend INT,
		totalSuperCash MONEY, totalMasterCash MONEY, totalAgentCash MONEY, totalMemberCash MONEY,
		yesterdaySuperCash MONEY, yesterdayMasterCash MONEY, yesterdayAgentCash MONEY, yesterdayMemberCash MONEY
	)

	/* get balance */
		-- bettransRnG
	INSERT INTO #tmpBalance
	(
		custid, recommend,
		totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
		yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
	)
	SELECT
		0 AS custid,
		b.recommend,
		-- total
		SUM(b.swinlost+b.scomm-b.acomm) AS totalSuperCash,
		SUM(b.mwinlost+b.acomm-b.comm) AS totalMasterCash,
		SUM(b.awinlost+b.comm-b.playercomm) AS totalAgentCash,
		SUM(b.winlost-b.actual_stake+b.playercomm) AS totalMemberCash,
		-- yesterday
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.swinlost+b.scomm-b.acomm ELSE 0 END) AS yesterdaySuperCash,
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.mwinlost+b.acomm-b.comm ELSE 0 END) AS yesterdayMasterCash,
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.awinlost+b.comm-b.playercomm ELSE 0 END) AS yesterdayAgentCash,
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS yesterdayMemberCash
	FROM bodb02.dbo.bettransRnG b WITH (NOLOCK)
		INNER JOIN @recommend r ON b.recommend = r.recommend
	WHERE b.statusID NOT IN (0, 1)
		AND b.winlostdate >= @yesterday
	GROUP BY b.recommend

		-- bettransLC
	INSERT INTO #tmpBalance
	(
		custid, recommend,
		totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
		yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
	)
	SELECT
		0 AS custid,
		b.recommend,
		-- total
		SUM(b.swinlost+b.scomm-b.acomm) AS totalSuperCash,
		SUM(b.mwinlost+b.acomm-b.comm) AS totalMasterCash,
		SUM(b.awinlost+b.comm-b.playercomm) AS totalAgentCash,
		SUM(b.winlost-b.actual_stake+b.playercomm) AS totalMemberCash,
		-- yesterday
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.swinlost+b.scomm-b.acomm ELSE 0 END) AS yesterdaySuperCash,
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.mwinlost+b.acomm-b.comm ELSE 0 END) AS yesterdayMasterCash,
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.awinlost+b.comm-b.playercomm ELSE 0 END) AS yesterdayAgentCash,
		SUM(CASE WHEN b.winlostdate = @yesterday THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS yesterdayMemberCash
	FROM bodb02.dbo.bettransLC b WITH (NOLOCK)
		INNER JOIN @recommend r ON b.recommend = r.recommend
	WHERE b.statusID NOT IN (0, 1)
		AND b.winlostdate >= @yesterday
	GROUP BY b.recommend

		-- bettrans
	INSERT INTO #tmpBalance
	(
		custid, recommend,
		totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
		yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
	)
	SELECT
		0 AS custid,
		b.recommend,
		-- total
		SUM(b.swinlost+b.scomm-b.acomm) AS totalSuperCash,
		SUM(b.mwinlost+b.acomm-b.comm) AS totalMasterCash,
		SUM(CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END) AS totalAgentCash,
		SUM(CASE WHEN b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END) AS totalMemberCash,
		-- yesterday
		SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN b.swinlost+b.scomm-b.acomm ELSE 0 END) AS yesterdaySuperCash,
		SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN b.mwinlost+b.acomm-b.comm ELSE 0 END) AS yesterdayMasterCash,
		SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END ELSE 0 END) AS yesterdayAgentCash,
		SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END ELSE 0 END) AS yesterdayMemberCash
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN @recommend r ON b.recommend = r.recommend
	WHERE b.statusID NOT IN (0, 1)
		AND (
			b.winlostdate < @yesterday
			OR NOT EXISTS (SELECT s.bettype FROM #SportBettype s WHERE s.bettype = b.bettype AND s.RefTable IN (1, 2))
		)
	GROUP BY b.recommend

	-- sum, balance, transfer, ... tickets of super/master
	INSERT INTO #tmpBalance
	(
		custid, recommend,
		totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
		yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
	)
	SELECT
		c.srecommend,
		0 AS recommend,
		-- total
		SUM(CASE WHEN b.srecommend = b.custid THEN b.winlost-b.actual_stake ELSE 0 END) AS totalSuperCash,
		SUM(CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE 0 END) AS totalMasterCash,
		0 AS totalAgentCash,
		0 AS totalMemberCash,
		-- yesterday
		SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) AND b.srecommend = b.custid THEN b.winlost-b.actual_stake ELSE 0 END) AS yesterdaySuperCash,
		SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) AND b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE 0 END) AS yesterdayMasterCash,
		0 AS yesterdayAgentCash,
		0 AS yesterdayMemberCash
	FROM bodb02.dbo.bettrans b WITH (NOLOCK)
		INNER JOIN (
			SELECT DISTINCT srecommend, custid
			FROM (
				SELECT srecommend, srecommend AS custid FROM #Cust_LimitLoss_Setting WHERE roleId = 4
				UNION ALL
				SELECT srecommend, mrecommend AS custid FROM #Cust_LimitLoss_Setting WHERE roleId = 4
				UNION ALL
				SELECT mrecommend, mrecommend AS custid FROM #Cust_LimitLoss_Setting WHERE roleId = 3
			) AS a
		) AS c ON b.custid = c.custid
	WHERE b.statusID NOT IN (0, 1)
		AND b.bettype >= 19000
	GROUP BY c.srecommend

	INSERT INTO #BalanceCust (CustID, NewTotalBalance, YesterdayTotalBalance, NewLevelID)
	SELECT custid, SUM(NewTotalBalance), SUM(YesterdayTotalBalance), 0 AS NewLevelID
	FROM
	(
		SELECT
			c.custid,
			SUM(CASE c.roleId
					WHEN 2 THEN b.totalMemberCash + b.totalAgentCash
					WHEN 3 THEN b.totalMemberCash + b.totalAgentCash + b.totalMasterCash
					WHEN 4 THEN b.totalMemberCash + b.totalAgentCash + b.totalMasterCash + b.totalSuperCash
				END) AS NewTotalBalance,
			SUM(CASE c.roleId
					WHEN 2 THEN b.yesterdayMemberCash + b.yesterdayAgentCash
					WHEN 3 THEN b.yesterdayMemberCash + b.yesterdayAgentCash + b.yesterdayMasterCash
					WHEN 4 THEN b.yesterdayMemberCash + b.yesterdayAgentCash + b.yesterdayMasterCash + b.yesterdaySuperCash
				END) AS YesterdayTotalBalance
		FROM #tmpBalance b
			INNER JOIN #Cust_LimitLoss_Setting c ON b.recommend = c.recommend
		WHERE b.custid = 0
		GROUP BY c.custid

		UNION ALL
		SELECT
			c.custid,
			SUM(CASE c.roleId
					WHEN 2 THEN b.totalMemberCash + b.totalAgentCash
					WHEN 3 THEN b.totalMemberCash + b.totalAgentCash + b.totalMasterCash
					WHEN 4 THEN b.totalMemberCash + b.totalAgentCash + b.totalMasterCash + b.totalSuperCash
				END) AS NewTotalBalance,
			SUM(CASE c.roleId
					WHEN 2 THEN b.yesterdayMemberCash + b.yesterdayAgentCash
					WHEN 3 THEN b.yesterdayMemberCash + b.yesterdayAgentCash + b.yesterdayMasterCash
					WHEN 4 THEN b.yesterdayMemberCash + b.yesterdayAgentCash + b.yesterdayMasterCash + b.yesterdaySuperCash
				END) AS YesterdayTotalBalance
		FROM #tmpBalance b
			INNER JOIN (SELECT DISTINCT custid, roleid FROM #Cust_LimitLoss_Setting) c ON b.custid = c.custid
		WHERE b.recommend = 0
		GROUP BY c.custid
	) AS A
	GROUP BY custid

	WHILE (@i<@MaxLevel)
	BEGIN
		UPDATE b
		SET NewLevelID = @i
		FROM #BalanceCust b
			INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
		WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)
			AND l.MaxLoss IS NOT NULL

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM #BalanceCust b
		INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
	WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)
		AND l.MaxLoss IS NOT NULL

	UPDATE l
	SET l.TotalBalance = b.NewTotalBalance,
		l.YesterdayBalance = b.YesterdayTotalBalance,
		l.OldLevelID = CASE WHEN l.LevelID = b.NewLevelID THEN l.OldLevelID ELSE l.LevelID END,
		l.LevelID = b.NewLevelID
	FROM LimitLoss_Setting l WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #BalanceCust b ON l.CustID = b.CustID

	-------------------------Headline---------------------------------------------------------------------
	INSERT INTO #BalanceGroupHeadline (GroupHeadlineID, NewTotalBalance, YesterdayTotalBalance, NewLevelID)
	SELECT hs.GroupHeadlineID, SUM(ls.TotalBalance), SUM(ls.YesterdayBalance), 0
	FROM dbo.LimitLoss_Setting ls WITH (NOLOCK)
		INNER JOIN bodb02.dbo.custAccount ca WITH (NOLOCK) ON ca.custid = ls.CustID
		INNER JOIN dbo.LimitLoss_HeadlineSetting hs WITH (NOLOCK) ON ca.groupID = hs.GroupHeadlineID
	GROUP BY hs.GroupHeadlineID

	SELECT @i = min(LevelID), @MaxLevel = max(LevelID) FROM LimitLoss_ActionConfig WITH (NOLOCK)
	WHILE (@i<@MaxLevel)
	BEGIN
		UPDATE b
		SET NewLevelID = @i
		FROM #BalanceGroupHeadline b
			INNER JOIN LimitLoss_HeadlineSetting l ON b.GroupHeadlineID = l.GroupHeadlineID
		WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM #BalanceGroupHeadline b
		INNER JOIN LimitLoss_HeadlineSetting l ON b.GroupHeadlineID = l.GroupHeadlineID
	WHERE CAST((b.NewTotalBalance/l.MaxLoss*100) AS INT) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)

	UPDATE l
	SET l.TotalBalance = b.NewTotalBalance,
		l.YesterdayBalance = b.YesterdayTotalBalance,
		l.OldLevelID = CASE WHEN l.LevelID = b.NewLevelID THEN l.OldLevelID ELSE l.LevelID END,
		l.LevelID = b.NewLevelID
	FROM LimitLoss_HeadlineSetting l WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #BalanceGroupHeadline b ON b.GroupHeadlineID = l.GroupHeadlineID
END
