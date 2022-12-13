/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Acc_CustVirtualMultiplier_ViewLog
	@Username NVARCHAR(100)
	, @SportType INT
	, @IncludingUpline BIT
	, @StartLogTime DATETIME
	, @EndLogTime DATETIME
	, @ErrCode TINYINT OUT
	, @ErrMsg NVARCHAR(200) OUT
AS
/*
	Creator : Dominic
	Date : 2019-07-25
	Task :  Log Function for New Virtual Rate Setting  [Redmind: #114830]
	DB: DBLOG/bodb_CustomerLog
	Revisions:
		- 20190725@Dominic: First commit
		- 20191106@Eden : Esport VR Phase 2 - Integrate Auto Suspend [Redmind: #121876]
		- 20200207@Tiara: New VR structure for Soccer [Redmind: #126243]
		- 20201009@Eden: NAP CM - Customize Logs of Virtual Rate [Redmine: #143201]
		- 20210624@Elodie: Aplly VRCustLog archive [Redmine: #157434]
		- 20221215@Johnson: sort by LeagueGroupOrder [Redmine:#177594]
	Parameter:
	Mapping log columns:
		, IsNew							AS C1
		, VRLeagueGroupID               AS C2
		, VRBetTypeGroupID              AS C3
		, BetType                       AS C4
		, LevelID                       AS C5
		, ValueLive						AS C6
		, FollowingValueLive            AS C7
		, FollowingCustIDLive           AS C8
		, FollowingLevelIDLive          AS C9
		, ValueNonLive					AS C10
		, FollowingValueNonLive         AS C11
		, FollowingCustIDNonLive        AS C12
		, FollowingLevelIDNonLive       AS C13
		, SortOrder                     AS C14
	
*/
BEGIN
	DECLARE @CustID INT
	DECLARE @LogTrackingValue2 VARCHAR(MAX)
	DECLARE @LogDocHandler INT	
	DECLARE @LogID BIGINT
	DECLARE @Newlog_DTS DATETIME = '2021/01/11 00:00:00' -- New format log effective date ( Released Date)
	DECLARE @LogTime DATETIME

	CREATE TABLE #VRLineCustID (CustID INT)
	CREATE TABLE #VRCustLog(LogID BIGINT
							, [CustID] INT
							, [TrackingValue2] varchar(max)
							, [LogTime] DATETIME
							, [UserID] INT
							, CurrencyRate FLOAT
							, IsExec BIT)

	CREATE CLUSTERED INDEX IX_LogID ON #VRCustLog(LogID)
	
	CREATE TABLE #Data (
			LogID BIGINT
			, IsNew TINYINT --IsNew
			, VRLeagueGroupID SMALLINT --VRLeagueGroupID
			, VRBetTypeGroupID SMALLINT --VRBetTypeGroupID
			, BetType SMALLINT --BetType
			, LevelID INT --LevelID
			, FollowingValueLive SMALLMONEY --FollowingValueLive
			, FollowingCustIDLive INT --FollowingCustID
			, FollowingLevelIDLive INT --FollowingLevelID
			, FollowingValueNonLive SMALLMONEY --FollowingValueNonLive
			, FollowingCustIDNonLive INT --FollowingCustID
			, FollowingLevelIDNonLive INT --FollowingLevelID
			, SortOrder SMALLINT
	)

	CREATE CLUSTERED INDEX IX_LogID ON #Data(LogID)

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	SELECT @CustID = CustID
	FROM bodb02.dbo.Customer c(NOLOCK)
	WHERE username = @Username
		AND roleid IN (1,2,3,4)

	IF @CustID IS NULL
	BEGIN
		SELECT @ErrCode = 1
		SELECT @ErrMsg = 'This username is not valid.'
		RETURN
	END

	IF @IncludingUpline = 1
	BEGIN
		INSERT INTO #VRLineCustID(CustID)
		SELECT CustID
		FROM (
			SELECT upv.Val CustID
			FROM (
				SELECT custid,recommend,mrecommend,srecommend,0 [Global]
				FROM bodb02.dbo.Customer (NOLOCK)
				WHERE CustID=@CustID
			) t
			UNPIVOT
			(
				Val
				FOR col IN (custid,recommend,mrecommend,srecommend,[Global])
			) upv
		) tmp
		GROUP BY CustID
	END
	ELSE
	BEGIN
		INSERT INTO #VRLineCustID(CustID)
		SELECT @CustID
	END
	
	IF @StartLogTime >= @__archiveDate
	BEGIN
		INSERT INTO #VRCustLog(LogID, CustID, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM VRCustLog (NOLOCK)
		WHERE CustID IN (SELECT CustID FROM #VRLineCustID) 
			AND LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = 808
	END
	ELSE IF @EndLogTime < @__archiveDate
	BEGIN
		INSERT INTO #VRCustLog(LogID, CustID, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM bodb_CustomerLog_Archive.dbo.VRCustLog (NOLOCK)
		WHERE CustID IN (SELECT CustID FROM #VRLineCustID) 
			AND LogTime >= @StartLogTime AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = 808
	END
	ELSE
	BEGIN
		INSERT INTO #VRCustLog(LogID, CustID, TrackingValue2, IsExec, UserID, LogTime)
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM VRCustLog (NOLOCK)
		WHERE CustID IN (SELECT CustID FROM #VRLineCustID) 
			AND LogTime >= @__archiveDate AND LogTime < DATEADD(DAY,1,@EndLogTime)
			AND SportType = @SportType
			AND ActionID = 808
		UNION ALL
		SELECT LogID, CustID, dbo.DecompressString(TrackingValue2), 0, UserID, LogTime
		FROM bodb_CustomerLog_Archive.dbo.VRCustLog (NOLOCK)
		WHERE CustID IN (SELECT CustID FROM #VRLineCustID) 
			AND LogTime >= @StartLogTime AND LogTime < @__archiveDate
			AND SportType = @SportType
			AND ActionID = 808
	END

	UPDATE #VRCustLog
	SET CurrencyRate = CAST(CAST(TrackingValue2 AS XML).value('(/Root/@actualrate)[1]', 'nvarchar(100)') AS FLOAT) 


	WHILE(1=1)
	BEGIN
		UPDATE TOP (1) #VRCustLog
		SET IsExec = 1
			, @LogID = LogID
			, @LogTrackingValue2 = TrackingValue2
			, @LogTime = LogTime
		WHERE IsExec = 0 

		IF @@ROWCOUNT = 0
			BREAK

		EXEC sp_xml_preparedocument @LogDocHandler OUTPUT, @LogTrackingValue2

		IF @LogTime >= @Newlog_DTS 
		BEGIN -- Log with new format
			--Insert data into temporary table after parsing
			INSERT INTO #Data(LogID 
							, IsNew
							, VRLeagueGroupID
							, VRBetTypeGroupID
							, BetType
							, LevelID
							, FollowingValueLive
							, FollowingCustIDLive
							, FollowingLevelIDLive
							, FollowingValueNonLive
							, FollowingCustIDNonLive
							, FollowingLevelIDNonLive
							, SortOrder
				)
			SELECT	@LogID LogID
					, MIN(tmp.C1)
					, tmp.C2
					, tmp.C3
					, tmp.C4
					, tmp.C5
					, tmp.C7
					, tmp.C8
					, tmp.C9
					, tmp.C11
					, tmp.C12
					, tmp.C13
					, MIN(tmp.C14)
			FROM OPENXML (@LogDocHandler, '/Root/r',1) 
			WITH (
				  C1 TINYINT --IsNew
				, C2 SMALLINT --VRLeagueGroupID
				, C3 SMALLINT --VRBetTypeGroupID
				, C4 SMALLINT --BetType
				, C5 INT --LevelID
				, C6 SMALLMONEY --ValueLive
				, C7 SMALLMONEY --FollowingValueLive
				, C8 INT --FollowingCustIDLive
				, C9 INT --FollowingLevelIDLive
				, C10 SMALLMONEY --ValueNonLive
				, C11 SMALLMONEY --FollowingValueNonLive
				, C12 INT --FollowingCustIDNonLive
				, C13 INT --FollowingLevelIDNonLive
				, C14 SMALLINT --SortOrder
			) AS tmp
			GROUP BY tmp.C2
					, tmp.C3
					, tmp.C4
					, tmp.C5
					, tmp.C7
					, tmp.C8
					, tmp.C9
					, tmp.C11
					, tmp.C12
					, tmp.C13
		END
		ELSE
		BEGIN -- Log with old format
			--Insert data into temporary table after parsing
			INSERT INTO #Data(LogID 
							, IsNew
							, VRLeagueGroupID
							, VRBetTypeGroupID
							, BetType
							, LevelID
							, FollowingValueLive
							, FollowingCustIDLive
							, FollowingLevelIDLive
							, FollowingValueNonLive
							, FollowingCustIDNonLive
							, FollowingLevelIDNonLive
							, SortOrder
				)
			SELECT	@LogID LogID
					, MIN(tmp.IsNew) IsNew
					, tmp.VRLeagueGroupID
					, tmp.VRBetTypeGroupID
					, tmp.BetType
					, tmp.LevelID
					, tmp.FollowingValueLive
					, tmp.FollowingCustIDLive
					, tmp.FollowingLevelIDLive
					, tmp.FollowingValueNonLive
					, tmp.FollowingCustIDNonLive
					, tmp.FollowingLevelIDNonLive
					, MIN(tmp.SortOrder)
			FROM OPENXML (@LogDocHandler, '/Root/r',1) 
			WITH (
				IsNew TINYINT --IsNew
				, VRLeagueGroupID SMALLINT --VRLeagueGroupID
				, VRBetTypeGroupID SMALLINT --VRBetTypeGroupID
				, BetType SMALLINT --BetType
				, LevelID INT --LevelID
				, ValueLive SMALLMONEY --ValueLive
				, FollowingValueLive SMALLMONEY --FollowingValueLive
				, FollowingCustIDLive INT --FollowingCustID
				, FollowingLevelIDLive INT --FollowingLevelID
				, ValueNonLive SMALLMONEY --ValueNonLive
				, FollowingValueNonLive SMALLMONEY --FollowingValueNonLive
				, FollowingCustIDNonLive INT --FollowingCustID
				, FollowingLevelIDNonLive INT --FollowingLevelID
				, SortOrder SMALLINT
			) AS tmp
			GROUP BY tmp.VRLeagueGroupID
					, tmp.VRBetTypeGroupID
					, tmp.BetType
					, tmp.LevelID
					, tmp.FollowingValueLive
					, tmp.FollowingCustIDLive
					, tmp.FollowingLevelIDLive
					, tmp.FollowingValueNonLive
					, tmp.FollowingCustIDNonLive
					, tmp.FollowingLevelIDNonLive
		END

		EXEC sp_xml_removedocument @LogDocHandler
	END

	SELECT currency
	FROM bodb02..Exchange e (NOLOCK)
	WHERE e.exchangeid IN (
		SELECT currency
		FROM bodb02..Customer c(NOLOCK)
		WHERE custid = @CustID
	)

	SELECT *
	INTO #VRLeagueGroup
	FROM
	OPENQUERY(DBACC,'SELECT * FROM bodb02.dbo.VRLeagueGroup lg (NOLOCK)') 

	SELECT *
	INTO #VRBettypeGroup
	FROM
	OPENQUERY(DBACC,'SELECT * FROM bodb02.dbo.VRBettypeGroup bg (NOLOCK)') 
	
	CREATE TABLE #Hierarchy 
	(
			 LevelID INT --LevelID
			, VRLeagueGroupID SMALLINT --VRLeagueGroupID
			, VRBetTypeGroupID SMALLINT --VRBetTypeGroupID
			, BetType SMALLINT --BetType
			, VRBetTypeGroupName VARCHAR(200)--VRBetTypeGroupName
			, VRLeagueGroupName VARCHAR(200)--VRLeagueGroupName
			, SortOrder SMALLINT
			, LeagueGroupOrder SMALLINT
	)	

		INSERT INTO #Hierarchy (LevelID, VRLeagueGroupID, VRBetTypeGroupID, BetType, VRBetTypeGroupName, VRLeagueGroupName, SortOrder, LeagueGroupOrder)
		SELECT h.LevelID,h.VRLeagueGroupID, h.VRBetTypeGroupID,CASE WHEN h.BetType = -1 THEN NULL ELSE h.BetType END BetType
				, bg.GroupName VRBetTypeGroupName
				, lg.GroupName VRLeagueGroupName
				, SortOrder
				, lg.LeagueGroupOrder
		FROM (
			SELECT DISTINCT VRLeagueGroupID, VRBetTypeGroupID, LevelID, CASE WHEN BetType = -1 THEN NULL ELSE BetType END BetType, SortOrder 
			FROM #Data 
		) as h
		LEFT JOIN #VRLeagueGroup lg (NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
		LEFT JOIN #VRBettypeGroup bg (NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID

		CREATE UNIQUE CLUSTERED INDEX PK_LevelID ON #Hierarchy(LevelID)

		SELECT m.LogID
			, CASE WHEN m.custid = 0 THEN 'Global Setting' ELSE c.username END username
			, CASE WHEN m.custid = 0 THEN NULL ELSE m.CurrencyRate END CurrencyRate
			, m.LogTime UpdatedTime, u.username UpdatedBy
			, @SportType SportType
			, h.VRLeagueGroupID LeagueGroupID , h.VRLeagueGroupName LeagueGroup
			, h.VRBetTypeGroupID BettypeGroupID, h.VRBetTypeGroupName BettypeGroup
			, d.BetType
			, d.LevelID
			, d.IsNew
			--Live
			, d.FollowingLevelIDLive Live_FollowingLevelID
			, d.FollowingValueLive Live_FollowingValue
			, CASE 
					WHEN d.FollowingCustIDLive = m.CustID THEN NULL
					WHEN d.FollowingCustIDLive = 0 THEN 'Global'
					WHEN cl.roleid = 4 THEN 'Super'
					WHEN cl.roleid = 3 THEN 'Master'
					WHEN cl.roleid = 2 THEN 'Agent'
				END Live_FollowingRole
			, hl.BetType Live_FollowingBetTypeID
			, hl.VRBetTypeGroupName Live_FollowingBettypeGroup
			, hl.VRLeagueGroupName Live_FollowingLeagueGroup
			--NonLive
			, d.FollowingLevelIDNonLive NonLive_FollowingLevelID
			, d.FollowingValueNonLive NonLive_FollowingValue
			, CASE 
					WHEN d.FollowingCustIDNonLive = m.CustID THEN NULL
					WHEN d.FollowingCustIDNonLive = 0 THEN 'Global'
					WHEN cnl.roleid = 4 THEN 'Super'
					WHEN cnl.roleid = 3 THEN 'Master'
					WHEN cnl.roleid = 2 THEN 'Agent'
				END NonLive_FollowingRole
			, hnl.BetType NonLive_FollowingBetTypeID
			, hnl.VRBetTypeGroupName NonLive_FollowingBettypeGroup
			, hnl.VRLeagueGroupName NonLive_FollowingLeagueGroup
		FROM #VRCustLog m
			INNER JOIN #Data d ON m.LogID = d.LogID
			INNER JOIN #Hierarchy h ON h.LevelID = d.LevelID
			LEFT JOIN bodb02..Customer u (NOLOCK) ON u.custid = m.UserID
			LEFT JOIN bodb02..Customer c (NOLOCK) ON c.custid = m.CustID
			LEFT JOIN bodb02..Customer cl (NOLOCK) ON cl.custid = d.FollowingCustIDLive
			LEFT JOIN bodb02..Customer cnl (NOLOCK) ON cnl.custid = d.FollowingCustIDNonLive
			INNER JOIN #Hierarchy hl (NOLOCK) ON hl.LevelID = d.FollowingLevelIDLive
			INNER JOIN #Hierarchy hnl (NOLOCK) ON hnl.LevelID = d.FollowingLevelIDNonLive
		ORDER BY m.LogID DESC, h.LeagueGroupOrder, d.SortOrder, IsNew
	

	DROP TABLE #VRCustLog
	DROP TABLE #VRLineCustID
	DROP TABLE #Data
	DROP TABLE #Hierarchy
	DROP TABLE #VRLeagueGroup
	DROP TABLE #VRBettypeGroup
END
