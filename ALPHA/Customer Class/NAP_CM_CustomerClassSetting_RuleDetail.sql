/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_CustomerClassSetting_RuleDetail] 
	 @RuleID INT
	,@Site NVARCHAR(MAX) = NULL
	,@SportTypes VARCHAR(2000)
	,@Currencies VARCHAR(MAX)
	,@IsTest TINYINT
	,@IsMultiSite BIT = 0
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original: Change Name for NAP_LM_CustomerClassSetting_RuleDetail

	Revisions:
		- 20240605@Winfred: [NAP CM] Customer Class Setting - Update the way to get CC Management Settings [201770]
		- 20250507@Winfred: [NAP CM] Risk Control - Upgrade ExchangeID Data Type[Redmine: #214119]

	Param's Explanation:
	Example: NAP_CM_CustomerClassSetting_RuleDetail @Site = 'BEST-ODDS', @RuleID = 86, @SportType = 2, @Currencies = '0', @IsTest = 1	
*/ 
BEGIN
	SET NOCOUNT ON;

    CREATE TABLE #CustomerClassSiteManagement ( Site NVARCHAR(50), CurrencyName NVARCHAR(MAX),Platform VARCHAR(100))  
	CREATE NONCLUSTERED INDEX Ix_CustomerClassSiteManagement ON #CustomerClassSiteManagement (Platform) INCLUDE (Site)  
    
	CREATE TABLE #CustomerClass_Platform( PolicyID INT, Site NVARCHAR(50), Currency SMALLINT, Platform VARCHAR(100))  
    CREATE CLUSTERED INDEX  CIX_CustomerClass_Platform ON #CustomerClass_Platform (PolicyID, Site, Platform)  

	CREATE TABLE #CustomerClass_Currency( PolicyID INT, Site NVARCHAR(50), CurrencyName NVARCHAR(MAX), Platform VARCHAR(100))  
    CREATE CLUSTERED INDEX  CIX_CustomerClass_Currency ON #CustomerClass_Currency (PolicyID, Site,Platform)
	
	CREATE TABLE #PolicyRule( PolicyID INT,  RuleID INT) 
	CREATE CLUSTERED INDEX  CIX_PolicyRule ON #PolicyRule (PolicyID, RuleID) 
	CREATE NONCLUSTERED INDEX  IX_PolicyRule ON #PolicyRule (PolicyID)    
	
	CREATE TABLE #SportType(SportType SMALLINT)
	CREATE TABLE #Currency(Currency SMALLINT PRIMARY KEY)
	
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

	INSERT INTO #PolicyRule( PolicyID, RuleID)
	SELECT PolicyID, a.RuleID
	FROM CustomerClassPolicyRule a WITH(NOLOCK) 
	WHERE RuleID = @RuleID

	INSERT INTO #CustomerClass_Platform(PolicyID, Site, Currency, Platform)  
	SELECT DISTINCT a.PolicyID, s.Site, s.Currency , d.Platforms  
	FROM CustomerClassPolicyManagement a  WITH(NOLOCK) 
		CROSS APPLY( SELECT TOP 1 PolicyID FROM #PolicyRule WHERE PolicyID = a.PolicyID ) r
		CROSS APPLY( SELECT DISTINCT sm.Site, sm.Currency
					 FROM CustomerClassSiteManagement sm WITH(NOLOCK) 
							CROSS APPLY ( SELECT Site FROM @SiteTbl ) t
							CROSS APPLY ( SELECT Currency FROM #Currency ) c
					 WHERE PolicyID = r.PolicyID 
						AND sm.Site = t.Site
						AND sm.Currency = c.Currency
					) s
		CROSS APPLY(
					SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
					FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(100)) AS Platform
						FROM CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = a.PolicyID AND Site = s.Site AND Currency = s.Currency) mis
				) d
	WHERE SportType IN (SELECT SportType FROM #SportType) AND IsTest <= @IsTest

	INSERT INTO #CustomerClass_Currency( PolicyID, Site, CurrencyName, Platform)
	SELECT DISTINCT
			a.PolicyID,
			a.Site,
			d.CurrencyName,
			CASE WHEN 
				 CHARINDEX('1',a.Platform) > 0 AND
				 CHARINDEX('2',a.Platform) > 0 AND
				 CHARINDEX('3',a.Platform) > 0 AND
				 CHARINDEX('4',a.Platform) > 0 AND
				 CHARINDEX('5',a.Platform) > 0  THEN '0' ELSE a.Platform END AS Platform
	FROM #CustomerClass_Platform a
		CROSS APPLY(
			SELECT STRING_AGG(CAST(CurrencyName AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY Currency)  AS CurrencyName
			FROM (SELECT  DISTINCT b.Currency, (CASE WHEN b.currency = 0 THEN 'All' ELSE e.currency END) AS CurrencyName
				FROM #CustomerClass_Platform b  
					LEFT JOIN exchange e WITH(NOLOCK) ON b.Currency = e.ExchangeId		
				WHERE PolicyID = a.PolicyID AND a.Site = b.Site AND a.Platform = b.Platform ) mis
		) d

	INSERT INTO #CustomerClassSiteManagement( Site, CurrencyName, Platform)
	SELECT DISTINCT
			a.Site,
			a.CurrencyName,
			CASE WHEN CHARINDEX('1',STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)) > 0 AND
					  CHARINDEX('2',STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)) > 0 AND
					  CHARINDEX('3',STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)) > 0 AND
					  CHARINDEX('4',STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)) > 0 AND
					  CHARINDEX('5',STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)) > 0 
				THEN '0' 
				ELSE STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform) END AS Platform
	FROM #PolicyRule d WITH(NOLOCK)
		CROSS APPLY( SELECT  Site, CurrencyName, Platform 
					 FROM #CustomerClass_Currency WITH (NOLOCK, INDEX = CIX_CustomerClass_Currency ,FORCESEEK)
					 WHERE PolicyID = d.PolicyID ) a
	GROUP BY a.Site, a.CurrencyName ,d.RuleID 
	
	IF @IsMultiSite = 0
	BEGIN
		SELECT DISTINCT a.Site AS Sites,
			1 AS NumberOfSites,
			a.CurrencyName,
			LEN(a.CurrencyName) - LEN(REPLACE(a.CurrencyName, ',', '')) + 1 AS NumberOfCurrencies,
			a.Platform ,
			LEN(a.Platform) - LEN(REPLACE(a.Platform, ',', '')) + 1 AS NumberOfPlatform
		FROM #CustomerClassSiteManagement a
	END
	ELSE
	BEGIN
		SELECT DISTINCT d.Sites,
			LEN(d.Sites) - LEN(REPLACE(d.Sites, ',', '')) + 1 AS NumberOfSites,
			a.CurrencyName,
			LEN(a.CurrencyName) - LEN(REPLACE(a.CurrencyName, ',', '')) + 1 AS NumberOfCurrencies,
			a.Platform ,
			LEN(a.Platform) - LEN(REPLACE(a.Platform, ',', '')) + 1 AS NumberOfPlatform
		FROM #CustomerClassSiteManagement a
		CROSS APPLY(
				SELECT STRING_AGG(Site, ',') WITHIN GROUP (ORDER BY Site)  AS Sites
				FROM (SELECT DISTINCT CAST(Site AS VARCHAR(MAX)) AS Site
					FROM #CustomerClassSiteManagement
					WHERE a.Platform = Platform AND a.CurrencyName = CurrencyName) mis
			) d
	END
		
	DROP TABLE #CustomerClassSiteManagement
	DROP TABLE #CustomerClass_Platform
	DROP TABLE #CustomerClass_Currency
	DROP TABLE #PolicyRule
	DROP TABLE #SportType
	DROP TABLE #Currency
END
