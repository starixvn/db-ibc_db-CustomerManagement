/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_VREngine_CriteriaMatrix_Check] 
	@SporttypeList VARCHAR(MAX) = NULL,
	@BettypeList VARCHAR(MAX) =  NULL,
	@LeagueGroupList VARCHAR(MAX) = NULL, -- 0: 'None Group' , -1 : All Group
	@LeagueList VARCHAR(MAX) =  NULL,
	@SiteIDList VARCHAR(MAX) =  NULL,
	@CustomerClassList VARCHAR(MAX) =  NULL,
	@DateOfWeekList VARCHAR(MAX) =  NULL,
	@CurrencyIDList VARCHAR(MAX) = NULL,
	@CCSporttypeList VARCHAR(MAX) = NULL,
	@CustomerClassDetailList VARCHAR(MAX) =  NULL,
	@JsonSportList VARCHAR(MAX)	= '',
	@Criteria_NotApply VARCHAR(MAX) = NULL,
	@ErrorCode INT = 0 OUTPUT,
	@ErrorMsg VARCHAR(MAX) = '' OUTPUT 
AS
/*
	Created: 20210428@Eden
	Task : VR Engine - validate all Criteria Maxtrix (Sport, Bettype, Leagroup, league ...)
	DB: DBACC-bodb02
	Original:

	Revisions:  
	- 20210428@Eden: First commit [Redmine:#136423]
	- 20211112@Eden: Alpha/NAP - In-house Replication (isDeleted & RepUpdateTime) [RedmineID: #164321]
	- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
	- 20220610@Tacy: Alpha/NAP - Remove IsDeleted field in League Table [RedmineID: #171699]
	- 20220617@Johnson: define temp table to avoid dump db [redmine:#174035]
	- 20240319@Luke: [NAP CM] VR Engine - Add in new criteria: Apply follow the VR accumulated balance, Currency [Redmine: #201333]
	- 20240422@Winfred: [NAP CM] VR Engine - Allow to add CC by Sport, and re-arrange league group on dropdownlist [Redmine: #195539]
	- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting [redmine: #207029]

	Parameter explanation:
		@Criteria_NotApply = 
			'<Root>
				<Row Criteria="SporttypeList" Value="1" />	
				<Row Criteria="BettypeList" Value="" />	
				<Row Criteria="LeagueGroupList" Value="" />	
				<Row Criteria="LeagueList" Value="" />	
				<Row Criteria="SiteIDList" Value="" />	
				<Row Criteria="CustomerClassList" Value="8,9,10" />	
				<Row Criteria="DateOfWeekList" Value="" />	
				<Row Criteria="CurrencyIDList" Value="" />
				<Row Criteria="CCSporttypeList" Value="" />
				<Row Criteria="CustomerClassDetailList" Value="" />
			</Root>'

		- Input -> @JsonSportList : Json Type
		'[  { "Sporttype": "1" }, { "Sporttype": "2" }, { "Sporttype": "43" }, { "Sporttype": "99" },
			{ "Sporttype": "5" }, { "Sporttype": "8" }, { "Sporttype": "9901" }, { "Sporttype": "9902" }
		]'

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
	
	DECLARE @SporttypeList_NotApply VARCHAR(MAX) = NULL,
	@BettypeList_NotApply VARCHAR(MAX) =  NULL,
	@LeagueGroupList_NotApply VARCHAR(MAX) = NULL,
	@LeagueList_NotApply VARCHAR(MAX) =  NULL,
	@SiteIDList_NotApply VARCHAR(MAX) =  NULL,
	@CustomerClassList_NotApply VARCHAR(MAX) =  NULL,
	@DateOfWeekList_NotApply VARCHAR(MAX) =  NULL,
	@CurrencyIDList_NotApply VARCHAR(MAX) = NULL,
	@CCSporttypeList_NotApply VARCHAR(MAX) = NULL,
	@CustomerClassDetailList_NotApply VARCHAR(MAX) =  NULL

	SELECT @SporttypeList = ISNULL( @SporttypeList,'0')
	SELECT @BettypeList = ISNULL( @BettypeList,'0')
	SELECT @LeagueGroupList = ISNULL( @LeagueGroupList,'-1')
	SELECT @LeagueList = ISNULL( @LeagueList,'-1')
	SELECT @SiteIDList = ISNULL( @SiteIDList,'0')
	SELECT @CustomerClassList = ISNULL( @CustomerClassList,'0')
	SELECT @DateOfWeekList = ISNULL( @DateOfWeekList,'0')
	SELECT @CurrencyIDList = ISNULL(@CurrencyIDList,'0')
	SELECT @CustomerClassDetailList = ISNULL( @CustomerClassDetailList,'0')
	SELECT @CCSporttypeList = ISNULL(@CCSporttypeList,'0')

	IF @Criteria_NotApply <> ''
	BEGIN
		DECLARE @DocHandler INT	
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Criteria_NotApply

		SELECT @SporttypeList_NotApply = CASE WHEN @SporttypeList = '0' AND Criteria = 'SporttypeList' THEN Value ELSE @SporttypeList_NotApply END,
			@BettypeList_NotApply = CASE WHEN @BettypeList = '0' AND Criteria = 'BettypeList' THEN Value ELSE @BettypeList_NotApply END,
			@LeagueGroupList_NotApply = CASE WHEN @LeagueGroupList = '-1' AND Criteria = 'LeagueGroupList' THEN Value ELSE @LeagueGroupList_NotApply END,
			@LeagueList_NotApply = CASE WHEN @LeagueList = '-1' AND Criteria = 'LeagueList' THEN Value ELSE @LeagueList_NotApply END,
			@SiteIDList_NotApply = CASE WHEN @SiteIDList = '0' AND Criteria = 'SiteIDList' THEN Value ELSE @SiteIDList_NotApply END,
			@CustomerClassList_NotApply = CASE WHEN @CustomerClassList = '0' AND Criteria = 'CustomerClassList' THEN Value ELSE @CustomerClassList_NotApply END,
			@DateOfWeekList_NotApply = CASE WHEN @DateOfWeekList = '0' AND Criteria = 'DateOfWeekList' THEN Value ELSE @DateOfWeekList_NotApply END,
			@CurrencyIDList_NotApply = CASE WHEN @CurrencyIDList = '0' AND Criteria = 'CurrencyIDList' THEN Value ELSE @CurrencyIDList_NotApply END,
			@CustomerClassDetailList_NotApply = CASE WHEN @CustomerClassDetailList = '0' AND Criteria = 'CustomerClassDetailList' THEN Value ELSE @CustomerClassDetailList_NotApply END,
			@CCSporttypeList_NotApply = CASE WHEN @CCSporttypeList = '0' AND Criteria = 'CCSporttypeList' THEN Value ELSE @CCSporttypeList_NotApply END
		FROM OPENXML (@DocHandler, '/Root/Row',1) 
		WITH (
			Criteria VARCHAR(40),
			Value VARCHAR(8000)
		) AS Data
		WHERE ISNULL(Value,'') <> ''

		EXEC sp_xml_removedocument @DocHandler
	END

	INSERT INTO #SportVR(sporttype)
	SELECT sb.Sporttype
	FROM OPENJSON(@JsonSportList )
	WITH  (Sporttype smallint ) AS sb
	WHERE ISJSON(@JsonSportList) > 0
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
		WHERE LeagueGroupID IN (SELECT value FROM STRING_SPLIT(@LeagueGroupList_NotApply,','))
	END
	ELSE
	BEGIN
		INSERT INTO #LeagueGroupInput(LeagueGroupID)
		SELECT CAST(value AS SMALLINT) AS LeagueGroupID 
		FROM STRING_SPLIT(@LeagueGroupList,',') le

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

	--> get league
	CREATE TABLE #League(LeagueID INT)
	
	INSERT INTO #League(LeagueID)
	SELECT CAST(value AS INT) AS LeagueID	
	FROM STRING_SPLIT(@LeagueList,',') le
	WHERE value <> ''

	IF @LeagueList <> '-1'
	BEGIN
		DECLARE @ErrorLeagueIDs VARCHAR(MAX) = '' 
		SELECT @ErrorLeagueIDs = @ErrorLeagueIDs + ', ' + CONVERT(VARCHAR,tmp.LeagueID)
		FROM #League tmp
			LEFT JOIN dbo.League l WITH(NOLOCK) ON tmp.LeagueID = l.leagueID AND l.IsActive = 1
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
	CREATE TABLE #Site(SiteID INT)
	CREATE TABLE #CC(CustomerClass SMALLINT)
	CREATE TABLE #DateOfWeek(DateOfWeek TINYINT)
	CREATE TABLE #Sport(Sporttype SMALLINT)
	CREATE TABLE #Bettype(Bettype SMALLINT)
	CREATE TABLE #Currency(CurrencyID INT)
	CREATE TABLE #CCSport(Sporttype SMALLINT)
	CREATE TABLE #CCDetail(CustomerClass SMALLINT)
	
	INSERT INTO #Site(SiteID)
	SELECT CAST(value AS INT) AS SiteID 	
	FROM STRING_SPLIT(@SiteIDList,',') t
	WHERE value <> ''
	
	--> CustomerClass
	INSERT INTO #CC(CustomerClass)
	SELECT CAST(value AS SMALLINT) AS CustomerClass 	
	FROM STRING_SPLIT(@CustomerClassList,',') t
	WHERE value <> ''

	--> DateOfWeek
	INSERT INTO #DateOfWeek(DateOfWeek)
	SELECT CAST(value AS TINYINT) AS DateOfWeek 	
	FROM STRING_SPLIT(@DateOfWeekList,',') t
	WHERE value <> ''

	--> Get sport
	INSERT INTO #Sport(Sporttype)
	SELECT CAST(value AS SMALLINT) AS Sporttype
	FROM STRING_SPLIT(@SporttypeList,',') t
	WHERE value <> ''
	
	--get Bettype
	INSERT INTO #Bettype(Bettype)
	SELECT CAST(value AS INT) AS Bettype 	
	FROM STRING_SPLIT(@BettypeList,',') t
	WHERE value <> ''

	--Currency
	INSERT INTO #Currency(CurrencyID)
	SELECT CAST(value AS INT) AS CurrencyID 	
	FROM STRING_SPLIT(@CurrencyIDList,',') t
	WHERE value <> ''

	--> Get sport CC
	INSERT INTO #CCSport(Sporttype)
	SELECT CAST(value AS SMALLINT) AS Sporttype
	FROM STRING_SPLIT(@CCSporttypeList,',') t
	WHERE value <> ''

	--> CustomerClass
	INSERT INTO #CCDetail(CustomerClass)
	SELECT CAST(value AS SMALLINT) AS CustomerClass 	
	FROM STRING_SPLIT(@CustomerClassDetailList,',') t
	WHERE value <> ''

	SELECT
		CAST(CASE WHEN @SporttypeList = '0' THEN 0 ELSE s.sporttype END AS SMALLINT) AS Sporttype,
		CAST(CASE WHEN @BettypeList = '0' THEN 0 ELSE bt.bettype END AS SMALLINT) AS Bettype,
		CAST(CASE WHEN @LeagueGroupList = '-1' THEN -1 ELSE lg.LeagueGroupID END AS INT) AS LeagueGroupID,
		CAST(CASE WHEN @LeagueList = '-1' THEN -1 ELSE le.LeagueID END AS INT) AS LeagueID,
		CAST(CASE WHEN @SiteIDList = '0' THEN 0 ELSE si.SiteID END AS INT) AS SiteID,
		CAST(CASE WHEN @CustomerClassList = '0' THEN 0 ELSE cc.CustomerClass END AS SMALLINT) AS CustomerClass,
		CAST(CASE WHEN @DateOfWeekList = '0' THEN 0 ELSE dw.DateOfWeek END AS TINYINT) AS DateOfWeek,
		CAST(CASE WHEN @CurrencyIDList = '0' THEN 0 ELSE c.CurrencyID END AS INT) AS CurrencyID,
		CAST(1  AS BIT) AS IsApply,
		CAST(CASE WHEN @CustomerClassDetailList = '0' THEN 0 ELSE ccd.CustomerClass END AS SMALLINT) AS CustomerClassDetail,
		CAST(CASE WHEN @CCSporttypeList = '0' THEN 0 ELSE ccd.sporttype END AS SMALLINT) AS CCSporttype
	FROM #Sport s 
		CROSS APPLY #Bettype bt
		CROSS APPLY #LeagueGroup lg
		CROSS APPLY #League le 
		CROSS APPLY #Site si 
		CROSS APPLY #DateOfWeek dw
		CROSS APPLY #Currency c
		CROSS APPLY #CC cc
		CROSS APPLY (SELECT sporttype, CustomerClass 
					 FROM #CCSport cs
						CROSS APPLY #CCDetail )  ccd
	UNION
	SELECT CAST(value AS SMALLINT),0,-1,-1,0,0,0,0,0,0,0
	FROM STRING_SPLIT(@SporttypeList_NotApply,',') t 
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0
	UNION
	SELECT 0,CAST(value AS INT),-1,-1,0,0,0,0,0,0,0
	FROM STRING_SPLIT(@BettypeList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,CAST(value AS SMALLINT),-1,0,0,0,0,0,0,0
	FROM STRING_SPLIT(@LeagueGroupList_NotApply,',') t
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0
	UNION
	SELECT 0,0,-1,CAST(value AS INT),0,0,0,0,0,0,0
	FROM STRING_SPLIT(@LeagueList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,CAST(value AS INT),0,0,0,0,0,0
	FROM STRING_SPLIT(@SiteIDList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,0,CAST(value AS SMALLINT),0,0,0,0,0
	FROM STRING_SPLIT(@CustomerClassList_NotApply,',') t
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,0,0,CAST(value AS TINYINT),0,0,0,0
	FROM STRING_SPLIT(@DateOfWeekList_NotApply,',') t
	WHERE ISNULL(CAST(value AS TINYINT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,0,0,0,CAST(value AS INT),0,0,0
	FROM STRING_SPLIT(@CurrencyIDList_NotApply,',') t
	WHERE ISNULL(CAST(value AS INT),0) <> 0
	UNION
	SELECT 0,0,-1,-1,0,0,0,0,0,CAST(value AS SMALLINT),CCSporttypeList_NotApply
	FROM STRING_SPLIT(@CustomerClassDetailList_NotApply,',') t
		CROSS APPLY (SELECT CAST(value AS SMALLINT) AS CCSporttypeList_NotApply
						FROM STRING_SPLIT(@CCSporttypeList_NotApply,',') t 
					 WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0) s
	WHERE ISNULL(CAST(value AS SMALLINT),0) <> 0

	DROP TABLE #Sport
	DROP TABLE #Bettype
	DROP TABLE #LeagueGroup
	DROP TABLE #League
	DROP TABLE #CC
	DROP TABLE #DateOfWeek
	DROP TABLE #Site
	DROP TABLE #LeagueGroupInput
	DROP TABLE #SportVR
	DROP TABLE #Currency
	DROP TABLE #CCDetail
	DROP TABLE #CCSport
END
GO


