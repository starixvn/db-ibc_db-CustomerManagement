/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Acc_CustVirtualMultiplier_ViewLog_AutoSuspend 
	@Username NVARCHAR(100)
	, @SportType INT
	, @StartLogTime DATETIME
	, @EndLogTime DATETIME
	, @ErrCode TINYINT OUT
	, @ErrMsg NVARCHAR(200) OUT
AS
/*
	Creator : Eden
	Date : 2019-11-01
	Task :  Log Function for New Virtual Rate Setting Autosuspend [Redmind: #121876]
	DB: DBLOG/bodb_CustomerLog
	Revisions:
		- 20191101@Eden: First commit [Redmind: #121876]
		- 20210624@Elodie: Aplly VRCustLog archive [Redmine: #157434]
	Parameter:

	
*/
BEGIN
	DECLARE @CustID INT
	DECLARE @LogTrackingValue1 VARCHAR(MAX)
	DECLARE @LogTrackingValue2 VARCHAR(MAX)
	DECLARE @LogDocHandler1 INT, @LogDocHandler2 INT	
	DECLARE @LogID BIGINT, @LogTime	DATETIME, @UserID INT
	DECLARE @ActionID INT = 809

	CREATE TABLE #VRLineCustID (CustID INT)
	CREATE TABLE #VRCustLogAutoSuspend(LogID BIGINT
							, [CustID] INT
							, [TrackingValue1] varchar(max)
							, [TrackingValue2] varchar(max)
							, [LogTime] DATETIME
							, [UserID] INT
							, IsExec BIT)

	CREATE CLUSTERED INDEX IX_LogID ON #VRCustLogAutoSuspend(LogID)
	
	CREATE TABLE #DataOld (
			  LogID BIGINT
			, UserID INT
			, Logtime DATETIME
			, LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, IsLiveAutoSuspend BIT 
			, IsNonLiveAutoSuspend BIT 
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
			, IsLiveAutoSuspend BIT 
			, IsNonLiveAutoSuspend BIT 
			, SortOrder SMALLINT
			, SportType SMALLINT
	)

	CREATE CLUSTERED INDEX IX_LogID2 ON #DataOld(LogID)
	CREATE CLUSTERED INDEX IX_LogID1 ON #DataNew(LogID)

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	SELECT @CustID = CustID
	FROM bodb02.dbo.Customer c WITH(NOLOCK)
	WHERE username = @Username
		AND roleid IN (1,2,3,4)

	IF @CustID IS NULL
	BEGIN
		SELECT @ErrCode = 1
		SELECT @ErrMsg = 'This username is not valid.'
		RETURN
	END
	
	IF @StartLogTime >= @__archiveDate
	BEGIN
		INSERT INTO #VRCustLogAutoSuspend(LogID, CustID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = @CustID
	END
	ELSE IF @EndLogTime < @__archiveDate
	BEGIN
		INSERT INTO #VRCustLogAutoSuspend(LogID, CustID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM bodb_CustomerLog_Archive.dbo.VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = @CustID
	END
	ELSE
	BEGIN
		INSERT INTO #VRCustLogAutoSuspend(LogID, CustID, TrackingValue1, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @__archiveDate AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = @CustID
		UNION ALL
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue1),dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM bodb_CustomerLog_Archive.dbo.VRCustLog WITH(NOLOCK)
		WHERE LogTime >= @StartLogTime AND LogTime < @__archiveDate
			AND SportType = @SportType
			AND ActionID = @ActionID 
			AND CustID = @CustID
	END

	WHILE(1=1)
	BEGIN
		UPDATE TOP (1) #VRCustLogAutoSuspend
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
						, IsLiveAutoSuspend
						, IsNonLiveAutoSuspend
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
				, tmp.IsLiveAutoSuspend
				, tmp.IsNonLiveAutoSuspend
				, MIN(tmp.SortOrder)
				, tmp.SportType
				, @UserID AS UserID
		FROM OPENXML (@LogDocHandler1, '/Root/r',1) 
		WITH (
			  LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, IsLiveAutoSuspend BIT 
			, IsNonLiveAutoSuspend BIT 
			, SortOrder SMALLINT
			, SportType SMALLINT
		) AS tmp
		GROUP BY  tmp.SportType 
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.IsLiveAutoSuspend
				, tmp.IsNonLiveAutoSuspend

		INSERT INTO #DataOld(LogID 
						, Logtime
						, LeagueGroup
						, BettypeGroup
						, BetType
						, LevelID
						, IsLiveAutoSuspend
						, IsNonLiveAutoSuspend
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
				, tmp.IsLiveAutoSuspend
				, tmp.IsNonLiveAutoSuspend
				, MIN(tmp.SortOrder)
				, tmp.SportType
				, @UserID AS UserID
		FROM OPENXML (@LogDocHandler2, '/Root/r',1) 
		WITH (
			  LeagueGroup NVARCHAR(200)
			, BettypeGroup NVARCHAR(200)
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, IsLiveAutoSuspend BIT 
			, IsNonLiveAutoSuspend BIT 
			, SortOrder SMALLINT
			, SportType SMALLINT
		) AS tmp
		GROUP BY  tmp.SportType 
				, tmp.LeagueGroup
				, tmp.BettypeGroup
				, tmp.BetType
				, tmp.LevelID
				, tmp.IsLiveAutoSuspend
				, tmp.IsNonLiveAutoSuspend
		
		EXEC sp_xml_removedocument @LogDocHandler1
		EXEC sp_xml_removedocument @LogDocHandler2
	END
	
	
	SELECT d1.LogID, 
		   d1.Logtime,
		   c.username AS UpdatedBy,
		   d1.LevelID,
		   d1.SportType,
		   d1.LeagueGroup, 
		   d1.BettypeGroup, 
		   d1.BetType, 
		   d1.IsLiveAutoSuspend AS IsLiveAutoSuspendNew, 
		   d2.IsLiveAutoSuspend AS IsLiveAutoSuspendOld, 
		   d1.IsNonLiveAutoSuspend AS IsNonLiveAutoSuspendNew, 
		   d2.IsNonLiveAutoSuspend AS IsNonLiveAutoSuspendOld
	FROM #DataNew d1
		 INNER JOIN #DataOld d2
		   ON d1.LevelID = d2.LevelID
		   AND d1.LogID = d2.LogID
		 LEFT JOIN bodb02.dbo.Customer c WITH(NOLOCK)
			ON c.custid = d1.UserID
	ORDER BY D1.LogID DESC, d1.SortOrder

	DROP TABLE #VRCustLogAutoSuspend
	DROP TABLE #VRLineCustID
	DROP TABLE #DataOld
	DROP TABLE #DataNew	
END
