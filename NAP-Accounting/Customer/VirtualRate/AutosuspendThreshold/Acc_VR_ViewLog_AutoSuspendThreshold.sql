/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
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
	)

	CREATE CLUSTERED INDEX IX_LogID2 ON #DataOld(LogID)
	CREATE CLUSTERED INDEX IX_LogID1 ON #DataNew(LogID)
	
	INSERT INTO #VRCustLogAutoSuspendThreshold(LogID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
	SELECT LogID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
	FROM VRCustLog WITH(NOLOCK)
	WHERE LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
		AND SportType = @SportType
		AND ActionID = @ActionID 
		AND CustID = 0

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
		) AS tmp
		GROUP BY  tmp.SportType 
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.VRAutoSuspendThresholdLive
				, tmp.VRAutoSuspendThresholdNonLive

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
		) AS tmp
		GROUP BY  tmp.SportType 
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.VRAutoSuspendThresholdLive
				, tmp.VRAutoSuspendThresholdNonLive
		
		EXEC sp_xml_removedocument @LogDocHandler1
		EXEC sp_xml_removedocument @LogDocHandler2
	END
	
	
	SELECT d1.LogID, 
		   d1.Logtime,
		   d1.LevelID,
		   d1.SportType,
		   d1.LeagueGroup, 
		   d1.BettypeGroup, 
		   d1.BetType, 
		   d1.VRAutoSuspendThresholdLive AS VRAutoSuspendThresholdLive_New, 
		   d1.VRAutoSuspendThresholdNonLive AS VRAutoSuspendThresholdNonLive_New,
		   d2.VRAutoSuspendThresholdLive AS VRAutoSuspendThresholdLive_Old,
		   d2.VRAutoSuspendThresholdNonLive AS VRAutoSuspendThresholdNonLive_Old
	FROM #DataNew d1
		 INNER JOIN #DataOld d2
		   ON d1.LevelID = d2.LevelID
		   AND d1.LogID = d2.LogID
	ORDER BY D1.LogID DESC, d1.SortOrder

	DROP TABLE #VRCustLogAutoSuspendThreshold
	DROP TABLE #DataOld
	DROP TABLE #DataNew	
END
