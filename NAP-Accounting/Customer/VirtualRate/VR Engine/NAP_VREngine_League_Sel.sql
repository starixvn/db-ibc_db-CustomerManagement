/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_League_Sel] 
	@Leaguename NVARCHAR(500) = '',
	@LeagueGroupList VARCHAR(MAX) = NULL,
	@LeagueGroupList_NotApply VARCHAR(MAX) = NULL
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - get League 
	DB: DBACC-bodb02
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20211112@Eden: Alpha/NAP - In-house Replication (isDeleted & RepUpdateTime) [RedmineID: #164321]
	- 20220610@Tacy: Alpha/NAP - Remove IsDeleted field in League Table [RedmineID: #171699]

	Parameter explanation:

	Example: 
	EXEC NAP_VREngine_League_Sel 
		@Leaguename = 'Serie a',
		@LeagueGroupList = '-1',
		@LeagueGroupList_NotApply = '1'

	*/
BEGIN
	CREATE TABLE #SportVR(sporttype smallint PRIMARY KEY)
	CREATE TABLE #LeagueGroupInput(LeagueGroupID smallint)
	CREATE TABLE #LeagueGroup(LeagueGroupID smallint PRIMARY KEY)

	SELECT @Leaguename = ISNULL(@Leaguename,'')

	IF ISNULL(@LeagueGroupList_NotApply,'') <> ''
	BEGIN
		SET @LeagueGroupList = '-1'
	END

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
		FROM dbo.LeagueGroup m WITH(NOLOCK)
			INNER JOIN #SportVR s ON m.Sporttype = s.Sporttype
		WHERE m.IsActive = 1
		UNION
		SELECT m.GroupID
		FROM dbo.LeagueGroup m WITH(NOLOCK)
		WHERE m.SportType = 0
			AND m.IsActive = 1

		DELETE #LeagueGroup
		WHERE LeagueGroupID IN (SELECT val FROM dbo.f_StringSplit(@LeagueGroupList_NotApply,','))
		OPTION (MAXRECURSION 0)
	END
	ELSE
	BEGIN
		INSERT INTO #LeagueGroupInput(LeagueGroupID)
		SELECT CAST(val AS SMALLINT) AS LeagueGroupID 
		FROM dbo.f_StringSplit(@LeagueGroupList,',') le
		OPTION (MAXRECURSION 0)

		INSERT INTO #LeagueGroup(LeagueGroupID)
		SELECT bt.LeagueGroupID
		FROM dbo.LeagueGroup m WITH(NOLOCK)
			INNER JOIN #SportVR s ON m.Sporttype = s.Sporttype
			INNER JOIN #LeagueGroupInput bt ON m.GroupID = bt.LeagueGroupID
		WHERE m.IsActive = 1
		UNION
		SELECT bt.LeagueGroupID
		FROM dbo.LeagueGroup m WITH(NOLOCK)
			INNER JOIN #LeagueGroupInput bt ON m.GroupID = bt.LeagueGroupID
		WHERE m.SportType = 0
			AND m.IsActive = 1
	END

	SELECT TOP(15)
		l.leagueid, l.leaguename
	FROM dbo.League l WITH(NOLOCK)
		INNER JOIN #SportVR s ON s.sporttype = l.SportType
		CROSS APPLY ( SELECT TOP (1) 1 AS haveGroup FROM #LeagueGroup WHERE LeagueGroupID = l.LeagueGroupID) lg
	WHERE l.IsActive = 1
		AND l.leaguename LIKE '%' + @Leaguename + '%'
	ORDER BY l.leaguename

	DROP TABLE #LeagueGroup
	DROP TABLE #SportVR
	DROP TABLE #LeagueGroupInput
END
GO


