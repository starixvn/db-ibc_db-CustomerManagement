/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_CriteriaMatrix_Check] 
	@SporttypeList VARCHAR(MAX) = NULL,
	@BettypeList VARCHAR(MAX) =  NULL,
	@LeagueGroupList VARCHAR(MAX) = NULL, -- 0: 'None Group' , -1 : All Group
	@LeagueList VARCHAR(MAX) =  NULL,
	@SiteIDList VARCHAR(MAX) =  NULL,
	@CustomerClassList VARCHAR(MAX) =  NULL,
	@DateOfWeekList VARCHAR(MAX) =  NULL,
	@SporttypeList_NotApply VARCHAR(MAX) = NULL,
	@BettypeList_NotApply VARCHAR(MAX) =  NULL,
	@LeagueGroupList_NotApply VARCHAR(MAX) = NULL,
	@LeagueList_NotApply VARCHAR(MAX) =  NULL,
	@SiteIDList_NotApply VARCHAR(MAX) =  NULL,
	@CustomerClassList_NotApply VARCHAR(MAX) =  NULL,
	@DateOfWeekList_NotApply VARCHAR(MAX) =  NULL,
	@ErrorCode INT = 0 OUTPUT,
	@ErrorMsg VARCHAR(MAX) = '' OUTPUT 
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - validate all Criteria Maxtrix (Sport, Bettype, Leagroup, league ...)
	DB: DBCUST-CUSTDB
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20211112@Eden: Alpha/NAP - In-house Replication (isDeleted & RepUpdateTime) [RedmineID: #164321]
	- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
	- 20220610@Tacy: Alpha/NAP - Remove IsDeleted field in League and Team Tables [RedmineID: #171699]

	Parameter explanation:

	Example: 
	DECLARE @ErrorCode INT = 0 ,@ErrorMsg VARCHAR(MAX) = '' 
	EXEC NAP_VREngine_CriteriaMatrix_Check 
		@SporttypeList = '0',
		@BettypeList = '0',
		@LeagueGroupList = '-1',
		@LeagueList =  '-1',
		@ErrorCode = @ErrorCode OUTPUT,
		@ErrorMsg = @ErrorMsg OUTPUT

	*/
BEGIN
	CREATE TABLE #SportVR(sporttype smallint PRIMARY KEY)
	CREATE TABLE #LeagueGroupInput(LeagueGroupID smallint)
	CREATE TABLE #LeagueGroup(LeagueGroupID smallint PRIMARY KEY)

	INSERT INTO #SportVR(sporttype)
	SELECT Sporttype
	FROM OPENQUERY (DBTXN, 'SELECT DISTINCT r.Sporttype FROM bodb02.dbo.Sport_Bettype_Reference_VirtualRate r WITH(NOLOCK)')
	UNION 
	SELECT r.Sporttype
	FROM dbo.VRSettingHierarchy r WITH(NOLOCK)
	WHERE BetType <> -1
	UNION 
	SELECT r.Sporttype
	FROM dbo.ProfileVirtualSetting r WITH(NOLOCK)
	UNION 
	SELECT r.Sporttype
	FROM dbo.VRSettingReference r WITH(NOLOCK)

	---Get LG
	IF @LeagueGroupList = '-1'
	BEGIN
		INSERT INTO #LeagueGroup(LeagueGroupID)
		SELECT m.GroupID
		FROM DBACC.BODB02.dbo.LeagueGroup m WITH(NOLOCK)
			INNER JOIN #SportVR s ON m.Sporttype = s.Sporttype
		WHERE m.IsActive = 1
		UNION
		SELECT m.GroupID
		FROM DBACC.BODB02.dbo.LeagueGroup m WITH(NOLOCK)
		WHERE m.SportType = 0
			AND m.IsActive = 1

		DELETE #LeagueGroup
		WHERE LeagueGroupID IN (SELECT value FROM STRING_SPLIT(@LeagueGroupList_NotApply,','))
	END
	ELSE
	BEGIN
		INSERT INTO #LeagueGroupInput(LeagueGroupID)
		SELECT CAST(value AS SMALLINT) AS LeagueGroupID 
		FROM STRING_SPLIT(@LeagueGroupList,',') le

		INSERT INTO #LeagueGroup(LeagueGroupID)
		SELECT bt.LeagueGroupID
		FROM DBACC.BODB02.dbo.LeagueGroup m WITH(NOLOCK)
			INNER JOIN #SportVR s ON m.Sporttype = s.Sporttype
			INNER JOIN #LeagueGroupInput bt ON m.GroupID = bt.LeagueGroupID
		WHERE m.IsActive = 1
		UNION
		SELECT bt.LeagueGroupID
		FROM DBACC.BODB02.dbo.LeagueGroup m WITH(NOLOCK)
			INNER JOIN #LeagueGroupInput bt ON m.GroupID = bt.LeagueGroupID
		WHERE m.SportType = 0
			AND m.IsActive = 1
	END

	--> get league
	SELECT CAST(value AS INT) AS LeagueID
	INTO #League
	FROM STRING_SPLIT(@LeagueList,',') le
	WHERE value <> ''

	IF @LeagueList <> '-1'
	BEGIN
		DECLARE @ErrorLeagueIDs VARCHAR(MAX) = '' 
		SELECT @ErrorLeagueIDs = @ErrorLeagueIDs + ', ' + CONVERT(VARCHAR,tmp.LeagueID)
		FROM #League tmp
			LEFT JOIN DBACC.BODB02.dbo.League l WITH(NOLOCK) ON tmp.LeagueID = l.leagueID AND l.IsActive = 1
			OUTER APPLY ( SELECT TOP (1) 1 AS haveGroup FROM #LeagueGroup WHERE LeagueGroupID = l.LeagueGroupID) lg
		WHERE lg.haveGroup IS NULL

		IF @ErrorLeagueIDs <> ''
		BEGIN
			SELECT @ErrorLeagueIDs = STUFF(@ErrorLeagueIDs,1,2,'')
			SELECT @ErrorCode = 5,
				@ErrorMsg = 'LeagueID '+ @ErrorLeagueIDs + ' do(es) not exist or not belong with selected LeagueGroup(s).' 

			RETURN
		END
	END

	--> Site
	SELECT CAST(value AS INT) AS SiteID 
	INTO #Site
	FROM STRING_SPLIT(@SiteIDList,',') t
	WHERE value <> ''
	
	--> CustomerClass
	SELECT CAST(value AS SMALLINT) AS CustomerClass 
	INTO #CC
	FROM STRING_SPLIT(@CustomerClassList,',') t
	WHERE value <> ''

	--> DateOfWeek
	SELECT CAST(value AS TINYINT) AS DateOfWeek 
	INTO #DateOfWeek
	FROM STRING_SPLIT(@DateOfWeekList,',') t
	WHERE value <> ''

	--> Get sport
	SELECT CAST(value AS SMALLINT) AS Sporttype 
	INTO #Sport
	FROM STRING_SPLIT(@SporttypeList,',') t
	WHERE value <> ''
	
	--get Bettype
	SELECT CAST(value AS INT) AS Bettype 
	INTO #Bettype
	FROM STRING_SPLIT(@BettypeList,',') t
	WHERE value <> ''

	INSERT INTO #ValidData(Sporttype,Bettype,LeagueGroupID,LeagueID,SiteID,CustomerClass,DateOfWeek,IsApply)
	SELECT
		CASE WHEN @SporttypeList = '0' THEN 0 ELSE s.sporttype END AS sporttype,
		CASE WHEN @BettypeList = '0' THEN 0 ELSE bt.bettype END AS bettype,
		CASE WHEN @LeagueGroupList = '-1' THEN -1 ELSE lg.LeagueGroupID END AS LeagueGroupID,
		CASE WHEN @LeagueList = '-1' THEN -1 ELSE le.LeagueID END AS LeagueID,
		CASE WHEN @SiteIDList = '0' THEN 0 ELSE si.SiteID END AS SiteID,
		CASE WHEN @CustomerClassList = '0' THEN 0 ELSE cc.CustomerClass END AS CustomerClass,
		CASE WHEN @DateOfWeekList = '0' THEN 0 ELSE dw.DateOfWeek END AS DateOfWeek,
		1 AS IsApply
	FROM #Sport s 
		CROSS APPLY #Bettype bt
		CROSS APPLY #LeagueGroup lg
		CROSS APPLY #League le 
		CROSS APPLY #Site si 
		CROSS APPLY #DateOfWeek dw
		CROSS APPLY #CC cc
	UNION
	SELECT CAST(value AS SMALLINT),0,-1,-1,0,0,0,0
	FROM STRING_SPLIT(@SporttypeList_NotApply,',') t 
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0
	UNION
	SELECT 0,CAST(value AS INT),-1,-1,0,0,0,0
	FROM STRING_SPLIT(@BettypeList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,CAST(value AS SMALLINT),-1,0,0,0,0
	FROM STRING_SPLIT(@LeagueGroupList_NotApply,',') t
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0
	UNION
	SELECT 0,0,-1,CAST(value AS INT),0,0,0,0
	FROM STRING_SPLIT(@LeagueList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,CAST(value AS INT),0,0,0
	FROM STRING_SPLIT(@SiteIDList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,0,CAST(value AS SMALLINT),0,0
	FROM STRING_SPLIT(@CustomerClassList_NotApply,',') t
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,0,0,CAST(value AS TINYINT),0
	FROM STRING_SPLIT(@DateOfWeekList_NotApply,',') t
	WHERE ISNULL(CAST(value AS TINYINT),0) <> 0

	DROP TABLE #Sport
	DROP TABLE #Bettype
	DROP TABLE #LeagueGroup
	DROP TABLE #League
	DROP TABLE #CC
	DROP TABLE #DateOfWeek
	DROP TABLE #Site
	DROP TABLE #LeagueGroupInput
	DROP TABLE #SportVR
END
GO


