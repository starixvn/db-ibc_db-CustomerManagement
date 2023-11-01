/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSetting] 
	 @Site NVARCHAR(50) = NULL
	,@CustomerClass SMALLINT
	,@SportType SMALLINT
	,@LeagueGroups VARCHAR(MAX)
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

	Param's Explanation:
	Example: NAP_LM_CustomerClassSetting @Site = 'BEST-ODDS' @CustomerClass = 200 , @SportType = 2,  @LeagueGroup = '1,2,4,5,6', @Islive = 1	
	* @LeagueGroup : 0 All
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @RowStart INT, @RowEnd INT, @iDoc INT, @xml XML
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

    CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, RuleID INT)    
    CREATE TABLE #CustomerClassSiteManagement ( Site NVARCHAR(50), Currency TINYINT, CurrencyName NVARCHAR(50),Platform VARCHAR(MAX), RuleID INT , RowNumber INT)    
    CREATE TABLE #LeagueGroup( GroupID SMALLINT, GroupName VARCHAR(200), SportType SMALLINT)    
    
    CREATE CLUSTERED INDEX Ix_CustomerClass ON #CustomerClass (PolicyID, Site, Currency)    
    CREATE CLUSTERED INDEX Ix_LeagueGroupTemp ON #LeagueGroup (GroupID, SportType)    
    CREATE CLUSTERED INDEX Ix_CustomerClassSiteManagement ON #CustomerClassSiteManagement (Site,Currency,RuleID) 	
    CREATE NONCLUSTERED INDEX NIx_CustomerClassSiteManagement_RowNumber ON #CustomerClassSiteManagement (RowNumber) 	

	--Check if XML is null or empty
	IF @LeagueGroups IS NULL OR @LeagueGroups = ''
		RETURN
	
	EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT, @LeagueGroups;
	INSERT INTO #LeagueGroup(GroupID, GroupName, SportType)
	SELECT	CAST(Data.GroupID AS SMALLINT) AS GroupID				
		,	CASE WHEN Data.GroupName = '' THEN null ELSE CAST(Data.GroupName AS VARCHAR(200)) END 
			AS GroupName 					    
		,	 CAST(Data.SportType AS SMALLINT)  AS SportType 
	FROM OPENXML(@iDoc, '/ROOT/r', 1) 
	WITH (     
			GroupID 	 SMALLINT,       
			GroupName 	 VARCHAR(500),       
			SportType 	 VARCHAR(20)
	) AS Data;
	EXECUTE	sp_xml_removedocument @iDoc;

	IF @SportType = 0
	BEGIN
		INSERT INTO #CustomerClass(PolicyID, Site, Currency)    
		SELECT DISTINCT a.PolicyID, a.Site, a.Currency     
		FROM CustomerClassSiteManagement a WITH(NOLOCK) 
			INNER JOIN  CustomerClassPolicyManagement ccp WITH(NOLOCK) ON a.PolicyID = ccp.PolicyID
		WHERE a.Site = @Site AND ccp.IsTest <= @IsTest
		-- Get all Platform for policy 
		INSERT INTO #CustomerClassSiteManagement( Site, Currency, Platform, RuleID, RowNumber)
		SELECT DISTINCT
				a.Site,
				a.Currency,
				d.Platforms,
				r.RuleID  , 
				DENSE_RANK() OVER( ORDER BY Site,r.RuleID,d.Platforms) AS RowNumber
		FROM #CustomerClass a WITH(NOLOCK)
			CROSS APPLY(
					SELECT cr.RuleID
					FROM CustomerClassPolicyRule cp WITH(NOLOCK)
						INNER JOIN CustomerClassRule cr WITH(NOLOCK) ON cp.RuleID =cr.RuleID
					WHERE cp.PolicyID = a.PolicyID AND cr.CustomerClass = @CustomerClass
				) r
			CROSS APPLY(
				SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
				FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
					FROM CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Currency = currency) mis
			) d

	END
	ELSE IF @Site IS NULL
	BEGIN
		INSERT INTO #CustomerClass(PolicyID, Site, Currency)    
		SELECT DISTINCT a.PolicyID, a.Site, a.Currency     
		FROM CustomerClassSiteManagement a WITH(NOLOCK) 
			INNER JOIN  CustomerClassPolicyManagement ccp WITH(NOLOCK) ON a.PolicyID = ccp.PolicyID
		WHERE ccp.SportType = @SportType AND ccp.IsTest <= @IsTest
		-- Get all Platform for policy 
		INSERT INTO #CustomerClassSiteManagement( Site, Currency, Platform, RuleID, RowNumber)
		SELECT DISTINCT
				a.Site,
				a.Currency,
				d.Platforms,
				r.RuleID  , 
				DENSE_RANK() OVER( ORDER BY Site,r.RuleID,d.Platforms) AS RowNumber
		FROM #CustomerClass a WITH(NOLOCK)
			CROSS APPLY(
					SELECT cr.RuleID
					FROM CustomerClassPolicyRule cp WITH(NOLOCK)
						INNER JOIN CustomerClassRule cr WITH(NOLOCK) ON cp.RuleID =cr.RuleID
					WHERE cp.PolicyID = a.PolicyID AND cr.CustomerClass = @CustomerClass
				) r
			CROSS APPLY(
				SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
				FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
					FROM CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Currency = currency) mis
			) d
	END
	ELSE IF @CustomerClass = 0
	BEGIN
		INSERT INTO #CustomerClass(PolicyID, Site, Currency)    
		SELECT DISTINCT a.PolicyID, a.Site, a.Currency     
		FROM CustomerClassSiteManagement a WITH(NOLOCK) 
			INNER JOIN  CustomerClassPolicyManagement ccp WITH(NOLOCK) ON a.PolicyID = ccp.PolicyID
		WHERE a.Site = @Site AND ccp.SportType = @SportType AND ccp.IsTest <= @IsTest
		-- Get all Platform for policy 
		INSERT INTO #CustomerClassSiteManagement( Site, Currency, Platform, RuleID, RowNumber)
		SELECT DISTINCT
				a.Site,
				a.Currency,
				d.Platforms,
				r.RuleID  , 
				DENSE_RANK() OVER( ORDER BY Site,r.RuleID,d.Platforms) AS RowNumber
		FROM #CustomerClass a WITH(NOLOCK)
			CROSS APPLY(
					SELECT cr.RuleID
					FROM CustomerClassPolicyRule cp WITH(NOLOCK)
						INNER JOIN CustomerClassRule cr WITH(NOLOCK) ON cp.RuleID =cr.RuleID
					WHERE cp.PolicyID = a.PolicyID
				) r
			CROSS APPLY(
				SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
				FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
					FROM CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Currency = currency) mis
			) d
	END
	ELSE
	BEGIN
		INSERT INTO #CustomerClass(PolicyID, Site, Currency)    
		SELECT DISTINCT a.PolicyID, a.Site, a.Currency     
		FROM CustomerClassSiteManagement a WITH(NOLOCK) 
			INNER JOIN  CustomerClassPolicyManagement ccp WITH(NOLOCK) ON a.PolicyID = ccp.PolicyID
		WHERE a.Site = @Site AND ccp.SportType = @SportType AND ccp.IsTest <= @IsTest
		-- Get all Platform for policy 
		INSERT INTO #CustomerClassSiteManagement( Site, Currency, Platform, RuleID, RowNumber)
		SELECT DISTINCT
				a.Site,
				a.Currency,
				d.Platforms,
				r.RuleID  , 
				DENSE_RANK() OVER( ORDER BY Site,r.RuleID,d.Platforms) AS RowNumber
		FROM #CustomerClass a WITH(NOLOCK)
			CROSS APPLY(
					SELECT cr.RuleID
					FROM CustomerClassPolicyRule cp WITH(NOLOCK)
						INNER JOIN CustomerClassRule cr WITH(NOLOCK) ON cp.RuleID =cr.RuleID
					WHERE cp.PolicyID = a.PolicyID AND cr.CustomerClass = @CustomerClass
				) r
			CROSS APPLY(
				SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
				FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
					FROM CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Currency = currency) mis
			) d
	END
	
	--Paging
	SELECT @TotalItems = MAX(RowNumber) FROM #CustomerClassSiteManagement c     
    
	DELETE FROM #CustomerClassSiteManagement  WHERE  RowNumber NOT BETWEEN @RowStart AND @RowEnd 
	
	SELECT DISTINCT
		a.Site,
		d.CurrencyName,
		a.Platform ,
		a.RuleID,
		c.CustomerClass,
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
	FROM #CustomerClassSiteManagement a 
		INNER JOIN CustomerClassRule c WITH(NOLOCK) ON a.RuleID = c.RuleID
		CROSS APPLY(
			SELECT STRING_AGG(CurrencyName, ',') WITHIN GROUP (ORDER BY CurrencyName)  AS CurrencyName
			FROM (SELECT DISTINCT e.currency AS CurrencyName
				FROM #CustomerClassSiteManagement b  
					INNER JOIN exchange e WITH(NOLOCK) ON b.Currency = e.ExchangeId		
				WHERE a.RuleID = b.RuleID AND a.Site = b.Site AND a.Platform = b.Platform ) mis
		) d
		CROSS APPLY(
			SELECT STRING_AGG(CAST(GroupName AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
			FROM (SELECT DISTINCT (CASE WHEN b.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS GroupName
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					LEFT JOIN #LeagueGroup ps ON b.LeagueGroupID = ps.GroupID 
				WHERE a.RuleID = b.RuleID) mis
		) e

	DROP TABLE #CustomerClass
END
GO
