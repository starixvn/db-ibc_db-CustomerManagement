/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSetting] 
	 @Site NVARCHAR(MAX) = NULL
	,@CustomerClass VARCHAR(MAX)
	,@CustomerClassDetail VARCHAR(MAX)
	,@SportTypes VARCHAR(2000)
	,@LeagueGroups VARCHAR(MAX)
	,@Currencies VARCHAR(MAX)
	,@IsTest TINYINT
	,@PageSize INT = 500
	,@PageIndex INT = 1
	,@TotalItems INT = 1 OUTPUT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20230928@Winfred: [NAP CM] Customer Class - Enhance for CC [RedmineID: #187368]
		- 20231031@Winfred: NAPCM - Cannot filter specific filters and show league group None on grid [RedmineID: #196365]  
		- 20231107@Winfred: [NAP CM] Customer Class - Auto include new items for rows that is selected option "All" [RedmineID: #186699] 
		- 20240223@Winfred: [NAP CM] Customer Class - Support for Saba [RedmineID: #193809]   
		- 20240314@Winfred: [NAP CM] Customer Class - Grant permission for each Sport type [RedmineID: #199465] 
		- 20240402@Winfred: [NAP CM] Customer Class - Support to add CC by Sport Detail [199679]
		- 20240411@Winfred: [NAP CM] Customer Class Setting - Add filter condition Currency [201435]
		- 20240605@Winfred: [NAP CM] Customer Class Setting - Update the way to get CC Management Settings [201770]

	Param's Explanation:
	Example: NAP_LM_CustomerClassSetting @Site = 'BEST-ODDS', @CustomerClass = '200', @CustomerClassDetail = '204,300,500', @SportType = 2, @LeagueGroup = '1,2,4,5,6', @IsTest = 1	,
										 @Currencies = '0'
	* @LeagueGroup : 0 All
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @RowStart INT, @RowEnd INT, @iDoc INT, @xml XML
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1
 
    CREATE TABLE #LeagueGroup( GroupID SMALLINT, GroupName VARCHAR(200), SportType SMALLINT)    
	CREATE TABLE #PolicyRule( PolicyID INT,  RuleID INT, RuleTitle VARCHAR(500), CustomerClass SMALLINT) 
	CREATE TABLE #Rule( RuleID INT, RowNumber INT IDENTITY(1,1)) 

	CREATE CLUSTERED INDEX  CIX_PolicyRule ON #PolicyRule (PolicyID, RuleID, CustomerClass) 
	CREATE NONCLUSTERED INDEX  IX_PolicyRule ON #PolicyRule (PolicyID)  INCLUDE (CustomerClass)        
    CREATE CLUSTERED INDEX  CIX_LeagueGroupTemp ON #LeagueGroup (GroupID, SportType)    
	CREATE TABLE #SportType(SportType SMALLINT)
	CREATE TABLE #Currency(Currency INT PRIMARY KEY)
	
	DECLARE @SiteTbl TABLE(Site NVARCHAR(50), isDeposit BIT)
	INSERT INTO @SiteTbl (Site) SELECT  'All' --All
	INSERT INTO @SiteTbl (Site , isDeposit)
	SELECT CAST(VALUE AS NVARCHAR(50)) AS site, s.isDeposit
	FROM STRING_SPLIT(@Site,',') a
		OUTER APPLY ( SELECT TOP 1 IsDeposit FROM Site WITH(NOLOCK) WHERE isActive = 1 AND site = a.VALUE ) s 
	WHERE CAST(VALUE AS NVARCHAR(50)) <> ''
	
	IF EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE site = 'AllCredit' )
	BEGIN
		INSERT INTO @SiteTbl (Site, isDeposit) SELECT site , isDeposit
		FROM Site a WITH(NOLOCK) WHERE  IsDeposit = 0 AND isActive = 1 
		AND Site NOT IN (SELECT Site FROM @SiteTbl)
	END

	IF EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE site = 'AllDeposit' )
	BEGIN
		INSERT INTO @SiteTbl (Site, isDeposit) SELECT site , isDeposit
		FROM Site a WITH(NOLOCK) WHERE  IsDeposit = 1 AND isActive = 1 
		AND Site NOT IN (SELECT Site FROM @SiteTbl)
	END

	IF @Site IS NULL OR @Site = 'All'
	BEGIN
		INSERT INTO @SiteTbl (Site, isDeposit) SELECT site , isDeposit
		FROM Site a WITH(NOLOCK) WHERE  isActive = 1 
		AND Site NOT IN (SELECT Site FROM @SiteTbl)
	END

	IF NOT EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE site = 'AllCredit') AND
			   EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE IsDeposit = 0)
	BEGIN
		INSERT INTO @SiteTbl (Site) SELECT  'AllCredit'
	END

	IF NOT EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE site = 'AllDeposit') AND
			EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE IsDeposit = 1)
	BEGIN
		INSERT INTO @SiteTbl (Site) SELECT  'AllDeposit'
	END
	
	INSERT INTO #SportType(SportType) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(ISNULL(@SportTypes,''),',') 
	WHERE VALUE <> ''

	IF @Currencies <> '0'
	BEGIN
		INSERT INTO #Currency(Currency) 
		SELECT DISTINCT VALUE
		FROM STRING_SPLIT(ISNULL(@Currencies,''),',') 
		WHERE VALUE <> ''
	END
	ELSE
	BEGIN
		INSERT INTO #Currency(Currency) 
		SELECT ExchangeId FROM exchange WITH(NOLOCK)
		WHERE ExchangeID NOT IN (27,28)
	END
	
	INSERT INTO #Currency(Currency) SELECT 0 -- All Currency

	--Check if XML is null or empty
	IF @LeagueGroups IS NULL OR @LeagueGroups = ''
		RETURN
	
	EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT, @LeagueGroups;
	INSERT INTO #LeagueGroup(GroupID, GroupName, SportType)
	SELECT	Data.GroupID AS GroupID				
		,	CASE WHEN Data.GroupName = '' THEN null ELSE Data.GroupName END AS GroupName 					    
		,	Data.SportType AS SportType 
	FROM OPENXML(@iDoc, '/ROOT/r', 1) 
	WITH (     
			GroupID 	 SMALLINT,       
			GroupName 	 VARCHAR(200),       
			SportType 	 SMALLINT
	) AS Data;
	EXECUTE	sp_xml_removedocument @iDoc;
		
	-- Get all PolicyID, RuleID 
	INSERT INTO #PolicyRule( PolicyID, RuleID, RuleTitle, CustomerClass)
	SELECT PolicyID, a.RuleID, r.RuleTitle, r.CustomerClass
	FROM CustomerClassPolicyRule a WITH(NOLOCK) 
		CROSS APPLY( SELECT TOP 1 RuleTitle, CustomerClass FROM CustomerClassRule WITH(NOLOCK) 
					WHERE RuleID = a.RuleID AND IsTest <= @IsTest 
					AND SportType IN (SELECT SportType FROM #SportType)
					AND 
					((@CustomerClass = ''  OR CustomerClass IN ( SELECT CAST(VALUE AS SMALLINT) FROM STRING_SPLIT(@CustomerClass,',') WHERE VALUE <> '') ) 
					AND
					 (@CustomerClassDetail = ''  OR CustomerClassDetail IN ( SELECT CAST(VALUE AS SMALLINT) FROM STRING_SPLIT(@CustomerClassDetail,',')WHERE VALUE <> '') )
					)) r

	INSERT INTO #Rule(RuleID)
	SELECT Distinct a.RuleID
	from #PolicyRule a
		CROSS APPLY( SELECT TOP 1 PolicyID 
					 FROM CustomerClassSiteManagement sm WITH(NOLOCK) 
							CROSS APPLY ( SELECT Site FROM @SiteTbl ) t
							CROSS APPLY ( SELECT Currency FROM #Currency ) c
					 WHERE PolicyID = a.PolicyID 
							AND sm.Site = t.Site
							AND sm.Currency = c.Currency
						) r
	ORDER BY a.RuleID

	SELECT @TotalItems = MAX(RowNumber) FROM #Rule c   

	SELECT
		a.RuleID,
		c.CustomerClass,
		c.CustomerClassDetail,
		c.RuleTitle,
		c.SportType,
		c.IsLive,
		(c.DiffBalanceRatio - 1) * 100 AS DiffBalanceRatio,
		(c.BetDelay - 1) * 100 AS BetDelay,
		c.NextBetInterval,
		c.SuperBetInterval,
		c.SiteBetInterval,
		c.MinBet,
		c.MaxBet,
		c.MaxPerMatch,
		c.RepeatedBets,
		c.SeizeBetTicket,
		c.DisableParlay,
		c.PeakHourSpreadAdjustment,
		c.Enable,
		c.LastModifiedUser,
		c.LastModifiedTime ,
		e.LeagueGroupNames
	FROM CustomerClassRule c WITH(NOLOCK)
		CROSS APPLY( SELECT TOP 1 RuleID FROM #Rule WHERE RuleID = c.RuleID AND RowNumber BETWEEN @RowStart AND @RowEnd ) a
		CROSS APPLY(
			SELECT STRING_AGG(CAST(GroupName AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
			FROM (SELECT DISTINCT (CASE WHEN b.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS GroupName
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					LEFT JOIN #LeagueGroup ps ON b.LeagueGroupID = ps.GroupID 
				WHERE a.RuleID = b.RuleID) mis
		) e
	ORDER BY c.RuleID, c.CustomerClass, c.RuleTitle

	DROP TABLE #SportType
	DROP TABLE #Currency
	DROP TABLE #LeagueGroup
	DROP TABLE #PolicyRule
END
