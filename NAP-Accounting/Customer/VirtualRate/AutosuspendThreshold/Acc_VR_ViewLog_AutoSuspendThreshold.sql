/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Acc_VR_ViewLog_AutoSuspendThreshold 
	  @SportType INT
	, @StartLogTime DATETIME
	, @EndLogTime DATETIME
AS
/*
	Creator : 20200305@Eden
	Task :  Log Function for VR Setting Autosuspend Global Threshold [Redmind: #128749]
	DB: DBLOG/bodb_CustomerLog
	Revisions:
		- 20200305@Eden : First commit [Redmind: #128749]
		- 20221219@Johnson: sort by LeagueGroupOrder [Redmine:#177594]
	Parameter:
	Example :
		EXEC Acc_VR_ViewLog_AutoSuspendThreshold
			  @SportType = 43
			, @StartLogTime = '2020/03/02'
			, @EndLogTime = '2020/03/08'
*/
BEGIN
	DECLARE @LogTrackingValue1 VARCHAR(MAX)
	DECLARE @LogTrackingValue2 VARCHAR(MAX)
	DECLARE @LogDocHandler1 INT, @LogDocHandler2 INT	
	DECLARE @LogID BIGINT, @LogTime	DATETIME, @UserID INT
	DECLARE @ActionID INT = 811

	CREATE TABLE #VRCustLogAutoSuspendThreshold(LogID BIGINT
							, [TrackingValue1] varchar(max)
							, [TrackingValue2] varchar(max)
							, [LogTime] DATETIME
							, [UserID] INT
							, IsExec BIT)

	CREATE CLUSTERED INDEX IX_LogID ON #VRCustLogAutoSuspendThreshold(LogID)
	
	CREATE TABLE #DataOld (
			  LogID BIGINT
			, UserID INT
			, Logtime DATETIME
			, LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, VRAutoSuspendThresholdLive SMALLMONEY
			, VRAutoSuspendThresholdNonLive SMALLMONEY
			, SortOrder SMALLINT
			, SportType SMALLINT
			, IsNew BIT
			, VRLeagueGroupID	smallint
			, VRBetTypeGroupID	smallint
	)
	CREATE TABLE #DataNew (
			  LogID BIGINT
			, UserID INT
			, Logtime DATETIME
			, LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, VRAutoSuspendThresholdLive SMALLMONEY
			, VRAutoSuspendThresholdNonLive SMALLMONEY
			, SortOrder SMALLINT
			, SportType SMALLINT
			, IsNew BIT
			, VRLeagueGroupID	smallint
			, VRBetTypeGroupID	smallint
	)

	CREATE CLUSTERED INDEX IX_LogID2 ON #DataOld(LogID)
	CREATE CLUSTERED INDEX IX_LogID1 ON #DataNew(LogID)

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	IF @StartLogTime >= @__archiveDate
	BEGIN
		INSERT INTO #VRCustLogAutoSuspendThreshold(LogID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = 0
	END
	ELSE IF @EndLogTime < @__archiveDate
	BEGIN
		INSERT INTO #VRCustLogAutoSuspendThreshold(LogID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM bodb_CustomerLog_Archive.dbo.VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = 0
	END
	ELSE
	BEGIN
		INSERT INTO #VRCustLogAutoSuspendThreshold(LogID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @__archiveDate AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = 0
		UNION ALL
		SELECT LogID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM bodb_CustomerLog_Archive.dbo.VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @StartLogTime AND LogTime < @__archiveDate
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = 0
	END

	WHILE(1=1)
	BEGIN
		UPDATE TOP (1) #VRCustLogAutoSuspendThreshold
		SET IsExec = 1
			, @LogID = LogID
			, @LogTime = LogTime
			, @UserID = UserID
			, @LogTrackingValue1 = TrackingValue1
			, @LogTrackingValue2 = TrackingValue2
		WHERE IsExec = 0 
		IF @@ROWCOUNT = 0
			BREAK

		EXEC sp_xml_preparedocument @LogDocHandler1 OUTPUT, @LogTrackingValue1
		EXEC sp_xml_preparedocument @LogDocHandler2 OUTPUT, @LogTrackingValue2

		--Insert data into temporary table after parsing
		INSERT INTO #DataNew(LogID 
						, Logtime
						, LeagueGroup
						, BettypeGroup
						, BetType
						, LevelID
						, VRAutoSuspendThresholdLive 
						, VRAutoSuspendThresholdNonLive 
						, SortOrder
						, SportType
						, UserID
						, IsNew
						, VRLeagueGroupID	
						, VRBetTypeGroupID
			)
		SELECT	@LogID LogID
				, @LogTime AS Logtime
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.VRAutoSuspendThresholdLive
				, tmp.VRAutoSuspendThresholdNonLive
				, MIN(tmp.SortOrder)
				, tmp.SportType
				, @UserID AS UserID
				, tmp.IsNew
				, tmp.VRLeagueGroupID	
				, tmp.VRBetTypeGroupID
		FROM OPENXML (@LogDocHandler1, '/Root/r',1) 
		WITH (
			  LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, VRAutoSuspendThresholdLive SMALLMONEY
			, VRAutoSuspendThresholdNonLive SMALLMONEY
			, SortOrder SMALLINT
			, SportType SMALLINT
			, IsNew BIT
			, VRLeagueGroupID	smallint
			, VRBetTypeGroupID	smallint
		) AS tmp
		GROUP BY  tmp.SportType 
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.VRAutoSuspendThresholdLive
				, tmp.VRAutoSuspendThresholdNonLive
				, tmp.IsNew 
				, tmp.VRLeagueGroupID	
				, tmp.VRBetTypeGroupID

		INSERT INTO #DataOld(LogID 
						, Logtime
						, LeagueGroup
						, BettypeGroup
						, BetType
						, LevelID
						, VRAutoSuspendThresholdLive 
						, VRAutoSuspendThresholdNonLive 
						, SortOrder
						, SportType
						, UserID
						, IsNew
						, VRLeagueGroupID	
						, VRBetTypeGroupID
			)
		SELECT	@LogID LogID
				, @LogTime AS Logtime
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.VRAutoSuspendThresholdLive
				, tmp.VRAutoSuspendThresholdNonLive
				, MIN(tmp.SortOrder)
				, tmp.SportType
				, @UserID AS UserID
				, tmp.IsNew
				, tmp.VRLeagueGroupID	
				, tmp.VRBetTypeGroupID	
		FROM OPENXML (@LogDocHandler2, '/Root/r',1) 
		WITH (
			  LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, VRAutoSuspendThresholdLive SMALLMONEY
			, VRAutoSuspendThresholdNonLive SMALLMONEY 
			, SortOrder SMALLINT
			, SportType SMALLINT
			, IsNew BIT
			, VRLeagueGroupID	smallint
			, VRBetTypeGroupID	smallint
		) AS tmp
		GROUP BY  tmp.SportType 
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.VRAutoSuspendThresholdLive
				, tmp.VRAutoSuspendThresholdNonLive
				, tmp.IsNew
				, tmp.VRLeagueGroupID	
				, tmp.VRBetTypeGroupID
		
		EXEC sp_xml_removedocument @LogDocHandler1
		EXEC sp_xml_removedocument @LogDocHandler2
	END
	
	SELECT *
	INTO #VRLeagueGroup
	FROM
	OPENQUERY(DBACC,'SELECT * FROM bodb02.dbo.VRLeagueGroup lg (NOLOCK)') 
	
	SELECT d1.LogID, 
		   d1.Logtime,
		   d1.LevelID,
		   d1.SportType,
		   d1.LeagueGroup, 
		   d1.BettypeGroup, 
		   d1.BetType, 
		   d1.VRLeagueGroupID,	
		   d1.VRBetTypeGroupID,	
		   d1.VRAutoSuspendThresholdLive AS VRAutoSuspendThresholdLive_New, 
		   d1.VRAutoSuspendThresholdNonLive AS VRAutoSuspendThresholdNonLive_New,
		   d2.VRAutoSuspendThresholdLive AS VRAutoSuspendThresholdLive_Old,
		   d2.VRAutoSuspendThresholdNonLive AS VRAutoSuspendThresholdNonLive_Old,
		   d1.IsNew,
		   c.username AS UpdatedBy
	FROM #DataNew d1
		 INNER JOIN #DataOld d2
		   ON d1.LevelID = d2.LevelID
		   AND d1.LogID = d2.LogID
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON d1.UserID = c.custid
		LEFT JOIN #VRLeagueGroup lg WITH(NOLOCK) ON d1.VRLeagueGroupID = lg.GroupID	
	ORDER BY D1.LogID DESC, lg.LeagueGroupOrder, d1.SortOrder

	DROP TABLE #VRCustLogAutoSuspendThreshold
	DROP TABLE #DataOld
	DROP TABLE #DataNew	
	DROP TABLE #VRLeagueGroup
END
