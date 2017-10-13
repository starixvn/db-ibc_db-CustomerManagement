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

	CREATE TABLE #Cust_LimitLoss_Setting (custid INT, roleId TINYINT)

	INSERT INTO #Cust_LimitLoss_Setting (custid, roleId)
	SELECT c.custid, c.roleid
	FROM dbo.LimitLoss_Setting s WITH (NOLOCK)
		INNER JOIN bodb02.dbo.CustInfo c WITH (NOLOCK) ON s.custid = c.custid

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
	
	CREATE TABLE #tmpBalance
	(
		custid INT, recommend INT,
		totalSuperCash MONEY, totalMasterCash MONEY, totalAgentCash MONEY, totalMemberCash MONEY,
		yesterdaySuperCash MONEY, yesterdayMasterCash MONEY, yesterdayAgentCash MONEY, yesterdayMemberCash MONEY
	)

	/* get balance */
	-- Super
	BEGIN
			-- bettransRnG
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.srecommend,
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
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 4
			) s ON b.srecommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
		GROUP BY b.srecommend

			-- bettransLC
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.srecommend,
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
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 4
			) s ON b.srecommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
		GROUP BY b.srecommend

			-- bettrans
			-- split code by winlostdate due to performance
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.srecommend,
			-- total
			SUM(CASE WHEN b.srecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.swinlost+b.scomm-b.acomm END) AS totalSuperCash,
			SUM(CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.mwinlost+b.acomm-b.comm END) AS totalMasterCash,
			SUM(CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END) AS totalAgentCash,
			SUM(CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END) AS totalMemberCash,
			-- yesterday
			SUM(CASE WHEN b.srecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.swinlost+b.scomm-b.acomm END) AS yesterdaySuperCash,
			SUM(CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.mwinlost+b.acomm-b.comm END) AS yesterdayMasterCash,
			SUM(CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END) AS yesterdayAgentCash,
			SUM(CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 4
			) s ON b.srecommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate < @yesterday
		GROUP BY b.srecommend

		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.srecommend,
			-- total
			SUM(CASE WHEN b.srecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.swinlost+b.scomm-b.acomm END) AS totalSuperCash,
			SUM(CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.mwinlost+b.acomm-b.comm END) AS totalMasterCash,
			SUM(CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END) AS totalAgentCash,
			SUM(CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END) AS totalMemberCash,
			-- yesterday
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.srecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.swinlost+b.scomm-b.acomm END ELSE 0 END) AS yesterdaySuperCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.mwinlost+b.acomm-b.comm END ELSE 0 END) AS yesterdayMasterCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 4
			) s ON b.srecommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
			AND NOT EXISTS (SELECT s.bettype FROM #SportBettype s WHERE s.bettype = b.bettype AND s.RefTable IN (1, 2))
		GROUP BY b.srecommend
	END

	-- Master
	BEGIN
			-- bettransRnG
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.mrecommend,
			-- total
			0 AS totalSuperCash,
			SUM(b.mwinlost+b.acomm-b.comm) AS totalMasterCash,
			SUM(b.awinlost+b.comm-b.playercomm) AS totalAgentCash,
			SUM(b.winlost-b.actual_stake+b.playercomm) AS totalMemberCash,
			-- yesterday
			0 AS yesterdaySuperCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.mwinlost+b.acomm-b.comm ELSE 0 END) AS yesterdayMasterCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.awinlost+b.comm-b.playercomm ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettransRnG b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 3
			) s ON b.mrecommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
		GROUP BY b.mrecommend

			-- bettransLC
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.mrecommend,
			-- total
			0 AS totalSuperCash,
			SUM(b.mwinlost+b.acomm-b.comm) AS totalMasterCash,
			SUM(b.awinlost+b.comm-b.playercomm) AS totalAgentCash,
			SUM(b.winlost-b.actual_stake+b.playercomm) AS totalMemberCash,
			-- yesterday
			0 AS yesterdaySuperCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.mwinlost+b.acomm-b.comm ELSE 0 END) AS yesterdayMasterCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.awinlost+b.comm-b.playercomm ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettransLC b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 3
			) s ON b.mrecommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
		GROUP BY b.mrecommend

			-- bettrans
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.mrecommend,
			-- total
			0 AS totalSuperCash,
			SUM(CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.mwinlost+b.acomm-b.comm END) AS totalMasterCash,
			SUM(CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END) AS totalAgentCash,
			SUM(CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END) AS totalMemberCash,
			-- yesterday
			0 AS yesterdaySuperCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.mrecommend = b.custid THEN b.winlost-b.actual_stake ELSE b.mwinlost+b.acomm-b.comm END ELSE 0 END) AS yesterdayMasterCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN (
				SELECT ci.custid
				FROM #Cust_LimitLoss_Setting c
					INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON c.custid = ci.mrecommend
				WHERE c.roleId = 3 AND ci.roleid = 2
			) s ON b.recommend = s.custid -- get index on recommend
		WHERE b.statusID NOT IN (0, 1)
			AND (
				b.winlostdate < @yesterday
				OR NOT EXISTS (SELECT s.bettype FROM #SportBettype s WHERE s.bettype = b.bettype AND s.RefTable IN (1, 2))
			)
		GROUP BY b.mrecommend
	END

	-- Agent
	BEGIN
			-- bettransRnG
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.recommend,
			-- total
			0 AS totalSuperCash,
			0 AS totalMasterCash,
			SUM(b.awinlost+b.comm-b.playercomm) AS totalAgentCash,
			SUM(b.winlost-b.actual_stake+b.playercomm) AS totalMemberCash,
			-- yesterday
			0 AS yesterdaySuperCash,
			0 AS yesterdayMasterCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.awinlost+b.comm-b.playercomm ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettransRnG b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 2
			) s ON b.recommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
		GROUP BY b.recommend

			-- bettransLC
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.recommend,
			-- total
			0 AS totalSuperCash,
			0 AS totalMasterCash,
			SUM(b.awinlost+b.comm-b.playercomm) AS totalAgentCash,
			SUM(b.winlost-b.actual_stake+b.playercomm) AS totalMemberCash,
			-- yesterday
			0 AS yesterdaySuperCash,
			0 AS yesterdayMasterCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.awinlost+b.comm-b.playercomm ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN b.winlostdate = @yesterday THEN b.winlost-b.actual_stake+b.playercomm ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettransLC b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 2
			) s ON b.recommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND b.winlostdate >= @yesterday
		GROUP BY b.recommend

			-- bettrans
		INSERT INTO #tmpBalance
		(
			custid,
			totalSuperCash, totalMasterCash, totalAgentCash, totalMemberCash,
			yesterdaySuperCash, yesterdayMasterCash, yesterdayAgentCash, yesterdayMemberCash
		)
		SELECT
			b.recommend,
			-- total
			0 AS totalSuperCash,
			0 AS totalMasterCash,
			SUM(CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END) AS totalAgentCash,
			SUM(CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END) AS totalMemberCash,
			-- yesterday
			0 AS yesterdaySuperCash,
			0 AS yesterdayMasterCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.recommend = b.custid THEN b.winlost-b.actual_stake ELSE b.awinlost+b.comm-b.playercomm END ELSE 0 END) AS yesterdayAgentCash,
			SUM(CASE WHEN (b.winlostdate <= @yesterday OR b.bettype > 20000) THEN CASE WHEN b.srecommend <> b.custid AND b.mrecommend <> b.custid AND b.recommend <> b.custid THEN b.winlost-b.actual_stake ELSE b.winlost-b.actual_stake+b.playercomm END ELSE 0 END) AS yesterdayMemberCash
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN (
				SELECT custid FROM #Cust_LimitLoss_Setting WHERE roleId = 2
			) s ON b.recommend = s.custid
		WHERE b.statusID NOT IN (0, 1)
			AND (
				b.winlostdate < @yesterday
				OR NOT EXISTS (SELECT s.bettype FROM #SportBettype s WHERE s.bettype = b.bettype AND s.RefTable IN (1, 2))
			)
		GROUP BY b.recommend
	END
	--------------

	INSERT INTO #BalanceCust (CustID, NewTotalBalance, YesterdayTotalBalance, NewLevelID)
	SELECT
		b.custid,
		SUM(b.totalMemberCash + b.totalAgentCash + b.totalMasterCash + b.totalSuperCash) AS NewTotalBalance,
		SUM(b.yesterdayMemberCash + b.yesterdayAgentCash + b.yesterdayMasterCash + b.yesterdaySuperCash) AS YesterdayTotalBalance,
		0 AS NewLevelID
	FROM #tmpBalance b
	GROUP BY b.custid
	/* End get balance */

	WHILE (@i<@MaxLevel)
	BEGIN
		UPDATE b
		SET NewLevelID = @i
		FROM #BalanceCust b
			INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
		WHERE (b.NewTotalBalance/l.MaxLoss*100) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND (b.NewTotalBalance/l.MaxLoss*100) < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)
			AND l.MaxLoss IS NOT NULL

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM #BalanceCust b
		INNER JOIN LimitLoss_Setting l ON b.CustID = l.CustID
	WHERE (b.NewTotalBalance/l.MaxLoss*100) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)
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
		WHERE (b.NewTotalBalance/l.MaxLoss*100) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i)
			AND (b.NewTotalBalance/l.MaxLoss*100) < (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @i+1)

		SET @i = @i+1
	END

	UPDATE b
	SET NewLevelID = @MaxLevel
	FROM #BalanceGroupHeadline b
		INNER JOIN LimitLoss_HeadlineSetting l ON b.GroupHeadlineID = l.GroupHeadlineID
	WHERE (b.NewTotalBalance/l.MaxLoss*100) >= (SELECT Value FROM LimitLoss_ActionConfig WITH (NOLOCK) WHERE LevelID = @MaxLevel)

	UPDATE l
	SET l.TotalBalance = b.NewTotalBalance,
		l.YesterdayBalance = b.YesterdayTotalBalance,
		l.OldLevelID = CASE WHEN l.LevelID = b.NewLevelID THEN l.OldLevelID ELSE l.LevelID END,
		l.LevelID = b.NewLevelID
	FROM LimitLoss_HeadlineSetting l WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #BalanceGroupHeadline b ON b.GroupHeadlineID = l.GroupHeadlineID
END
