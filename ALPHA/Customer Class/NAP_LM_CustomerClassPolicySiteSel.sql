/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteSel] 
	@PolicyID INT
	,@Site NVARCHAR(MAX)
	,@Platform NVARCHAR(MAX)
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
		- 20231107@Winfred: [NAP CM] Customer Class - Auto include new items for rows that is selected option "All" [RedmineID: #186699] 

	Param's Explanation:
	Example: NAP_LM_CustomerClassPolicySiteSel @PolicyID = 1, @Site = '12Bet', @Platform = 1
*/ 
BEGIN
	SET NOCOUNT ON;

	DECLARE @RowStart INT, @RowEnd INT
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(50), Currency TINYINT)
	
	CREATE TABLE #CustomerClass_Platform ( PolicyID INT, Site VARCHAR(50), Currency TINYINT, CurrencyName NVARCHAR(50), Platform VARCHAR(500))

	CREATE TABLE #CustomerClassSiteManagement ( PolicyID INT, Site VARCHAR(50), CurrencyName	VARCHAR(MAX), CurrencyID VARCHAR(MAX),
												Platform VARCHAR(500), RowNumber INT)
	CREATE CLUSTERED INDEX CIX_CustomerClass ON #CustomerClass(PolicyID, Site, Currency)
	CREATE CLUSTERED INDEX CIX_CustomerClass_Platform ON #CustomerClass_Platform(PolicyID, Site, Platform)
	CREATE NONCLUSTERED INDEX inx_temp3 ON #CustomerClassSiteManagement(RowNumber )
	CREATE NONCLUSTERED INDEX CIX_CustomerClassSiteManagement ON #CustomerClassSiteManagement(PolicyID, Platform) INCLUDE ( CurrencyID,Site)
	 
	DECLARE @SiteTbl TABLE(Site NVARCHAR(50), isDeposit BIT)
	DECLARE @PlatformTB TABLE(Platform TINYINT)
	INSERT INTO @PlatformTB(Platform)
	SELECT VALUE AS Platform FROM STRING_SPLIT(@Platform,',') WHERE VALUE <> ''
	UNION ALL SELECT 0 AS Platform

	IF @site = 'All'
	BEGIN
		IF @Platform = '0'
		BEGIN
			INSERT INTO #CustomerClass(PolicyID, Site, Currency)
			SELECT DISTINCT a.PolicyID,
					b.Site,
					b.Currency
				FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					CROSS APPLY ( SELECT DISTINCT Site, Currency 
								  FROM CustomerClassSiteManagement WITH(NOLOCK) 
								  WHERE a.PolicyID = PolicyID) b
				WHERE (@PolicyID = 0 OR a.PolicyID = @PolicyID) AND a.IsTest <= @IsTest
		END
		ELSE
		BEGIN
			INSERT INTO #CustomerClass(PolicyID, Site, Currency)
			SELECT DISTINCT a.PolicyID,
					b.Site,
					b.Currency
				FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					CROSS APPLY ( SELECT DISTINCT Site, Currency 
								  FROM CustomerClassSiteManagement WITH(NOLOCK) 
								  WHERE a.PolicyID = PolicyID 
								  AND Platform IN (SELECT Platform FROM @PlatformTB)) b
				WHERE (@PolicyID = 0 OR a.PolicyID = @PolicyID) AND a.IsTest <= @IsTest
		END
	END
	ELSE
	BEGIN
		INSERT INTO @SiteTbl (Site) SELECT  'All' --All
		INSERT INTO @SiteTbl (Site , isDeposit)
		SELECT VALUE AS site, s.isDeposit
		FROM STRING_SPLIT(@Site,',') a
		  OUTER APPLY ( SELECT TOP 1 IsDeposit FROM Site WITH(NOLOCK) WHERE isActive = 1 AND site = a.VALUE ) s 
		WHERE VALUE <> ''

		IF EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE site = 'AllCredit' )
		BEGIN
			INSERT INTO @SiteTbl (Site) SELECT site 
			FROM Site a WITH(NOLOCK) WHERE  IsDeposit = 0 AND isActive = 1 
			AND Site NOT IN (SELECT Site FROM @SiteTbl)
		END

		IF EXISTS(SELECT TOP 1 1 FROM @SiteTbl WHERE site = 'AllDeposit' )
		BEGIN
			INSERT INTO @SiteTbl (Site) SELECT site 
			FROM Site a WITH(NOLOCK) WHERE  IsDeposit = 1 AND isActive = 1 
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
		
		IF @Platform = '0'
		BEGIN
			INSERT INTO #CustomerClass(PolicyID, Site, Currency)
			SELECT DISTINCT a.PolicyID,
					b.Site,
					b.Currency
				FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					CROSS APPLY ( SELECT DISTINCT Site, Currency 
								  FROM CustomerClassSiteManagement WITH(NOLOCK) 
								  WHERE a.PolicyID = PolicyID 
								  AND Site IN (SELECT Site FROM @SiteTbl)) b
				WHERE (@PolicyID = 0 OR a.PolicyID = @PolicyID) AND a.IsTest <= @IsTest
		END
		ELSE
		BEGIN
			INSERT INTO #CustomerClass(PolicyID, Site, Currency)
			SELECT DISTINCT a.PolicyID,
					b.Site,
					b.Currency
				FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					CROSS APPLY ( SELECT DISTINCT Site, Currency 
								  FROM CustomerClassSiteManagement WITH(NOLOCK) 
								  WHERE a.PolicyID = PolicyID 
								  AND Platform IN (SELECT Platform FROM @PlatformTB)
								  AND Site IN (SELECT Site FROM @SiteTbl) ) b
				WHERE (@PolicyID = 0 OR a.PolicyID = @PolicyID) AND a.IsTest <= @IsTest 
		END
	END

	INSERT INTO #CustomerClass_Platform(PolicyID, Site, Currency, CurrencyName, Platform)
	SELECT DISTINCT a.PolicyID,
			a.Site,
			a.Currency,
			CASE WHEN a.currency = 0 THEN 'ALL' ELSE e.currency END AS CurrencyName,
			d.Platforms
	FROM #CustomerClass a WITH(NOLOCK)
		LEFT JOIN exchange e WITH(NOLOCK) ON a.Currency = e.ExchangeId
		CROSS APPLY(
			SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
			FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(MAX)) AS Platform
				FROM CustomerClassSiteManagement WITH(NOLOCK)
				WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Currency = currency) mis
		) d

	INSERT INTO #CustomerClassSiteManagement(PolicyID, Site, CurrencyID, CurrencyName, Platform, RowNumber)
	SELECT   a.PolicyID, --DISTINCT
			a.Site,
			e.CurrencyID,
			d.CurrencyName,
			a.Platform, 
			DENSE_RANK() OVER( ORDER BY a.PolicyID, d.CurrencyName, a.Platform) AS RowNumber
	FROM #CustomerClass_Platform a 
			CROSS APPLY(
				SELECT STRING_AGG(CAST(CurrencyName AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY CurrencyName)  AS CurrencyName
				FROM #CustomerClass_Platform p
				WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Platform = Platform
			) d
		CROSS APPLY(
			SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY Currency)  AS CurrencyID
			FROM (SELECT DISTINCT Currency 
				FROM #CustomerClass_Platform b  
				WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Platform = Platform ) mis
		) e

	--Paging
	SELECT @TotalItems = MAX(RowNumber) FROM #CustomerClassSiteManagement c 
	DELETE FROM #CustomerClassSiteManagement  WHERE RowNumber NOT BETWEEN @RowStart AND @RowEnd 
	-- Group Currency
	SELECT  a.PolicyID,
			a.PolicyTitle,
			d.Sites,
			b.CurrencyName,
			b.CurrencyID,
			b.Platform, 
			b.RowNumber
	FROM CustomerClassPolicyManagement a WITH(NOLOCK)
			CROSS APPLY( SELECT DISTINCT Platform, CurrencyID, CurrencyName, RowNumber FROM #CustomerClassSiteManagement WHERE PolicyID = a.PolicyID ) b
			CROSS APPLY(
				SELECT  STRING_AGG(CAST(Site AS VARCHAR(MAX)), ',')  AS Sites
				FROM (SELECT DISTINCT Site 
				FROM #CustomerClassSiteManagement 
				WHERE PolicyID = a.PolicyID AND Platform = b.Platform AND CurrencyID = b.CurrencyID ) mis
			) d
	ORDER BY a.PolicyID

	DROP TABLE #CustomerClass
	DROP TABLE #CustomerClass_Platform
	DROP TABLE #CustomerClassSiteManagement
END
GO
