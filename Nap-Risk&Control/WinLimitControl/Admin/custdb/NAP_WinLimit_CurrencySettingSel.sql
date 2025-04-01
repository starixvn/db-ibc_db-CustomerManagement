/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel] 
	@ProductId    INT, 
	@MultiSite	  VARCHAR(Max), 
	@IsCreditSite TINYINT = 0, 
	@CurrencyId   INT = 0, 
	@GroupId      INT = 0
AS

/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2
	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20170313@Jacob: Risk & Control - Phase 3A [#72604].
		- 20180921@Jacob: Migrate some of Licensee Setting tables (LRF System) from DB052.bodb_Licensee to DBCust.bodb_Licensee [#99855]
		- 20220522@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page
		- 20230215@Tacy: CWL - Split 789y site [RedmineID: #182387]
		- 20230911@Tacy: CWL - Suspend member accounts when member reaches Yellow level on RNG Slots Games [RedmineID: #184911]
		- 20250401@Lani: [TVS] Extend ExchangeID data type from TINYINT to SMALLINT [Redmine: #222191]
		
	Parameters Explanation:
		@ProductId	: Product ID
		@IsCreditSite:	0 ~ Licensee
						1 ~ Credit
						2 ~ Both
		@CurrencyId	: Currency ID
		@MultiSite	: 0 ~ all site; <>0 ~ Site
	
	Example:
		EXEC [NAP_WinLimit_CurrencySettingSel] @ProductId=21,@MultiSite='20,3',@IsCreditSite=2,@CurrencyId=72
*/
BEGIN
	SET NOCOUNT ON;

	BEGIN --Site
		DECLARE @Site TABLE (siteID INT, IsLicensee BIT)
		
		IF @MultiSite='0'
		BEGIN
			INSERT INTO @Site(siteID, IsLicensee)
			SELECT siteid, isLicensee
			FROM Site WITH (NOLOCK)
			WHERE isActive=1
		END
		ELSE
		BEGIN
			;WITH CTE AS (
				SELECT TRIM(value) SiteID
				FROM STRING_SPLIT(@MultiSite, ',')
			)
			INSERT INTO @Site(siteID, IsLicensee)
			SELECT t.SiteID, s.isLicensee
			FROM CTE t
			INNER JOIN Site s WITH (NOLOCK) ON s.siteid=t.SiteID
			WHERE s.isActive=1
		END
	END;
	BEGIN -- @Products
		DECLARE @Products TABLE (ProductId TINYINT, 
								GroupId   INT, 
								LevelId   TINYINT
								);

		INSERT INTO @Products
			(
			ProductId, 
			LevelId, 
			GroupId
			)
			SELECT DISTINCT 
					p.ProductId, 
					p.LevelId, 
					s.GroupId
			FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId) p
				INNER JOIN dbo.WinLimit_GameGroupSetting s WITH(NOLOCK) ON p.ProductId = s.ProductId
			WHERE CASE
					WHEN @GroupId > 0
					THEN s.GroupID
					ELSE @GroupId
					END = @GroupId;
	END;
	BEGIN --#ProductSiteCurrencySetting
		CREATE TABLE #ProductSiteCurrencySetting
					(
			ProductId  TINYINT, 
			SiteId     SMALLINT, 
			CurrencyId SMALLINT,
			IsCreditSite BIT
					);
		IF @IsCreditSite = 0
			BEGIN
				INSERT INTO #ProductSiteCurrencySetting (ProductId, SiteId, CurrencyId, IsCreditSite)
				SELECT DISTINCT 
					@ProductId, 
					s.siteid, 
					lc.Currency,
					@IsCreditSite
				FROM bodb_licensee.dbo.LicenseeCust lc WITH(NOLOCK)
					INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON l.LicenseeID = lc.LicenseeID
					INNER JOIN exchange ex WITH(NOLOCK) ON ex.exchangeid = lc.Currency
					INNER JOIN dbo.site s ON s.site = l.LicenseeName
										AND s.isActive = 1
					CROSS APPLY (SELECT 1 val FROM @Site ss WHERE ss.siteID=s.siteid AND ss.IsLicensee=1) ss
				WHERE (@CurrencyId = 0 OR lc.Currency = @CurrencyId)
					AND lc.CurrencyName NOT IN('H', 'C');
			END;
		ELSE IF @IsCreditSite = 1
			BEGIN
				INSERT INTO #ProductSiteCurrencySetting(ProductId, SiteId, CurrencyId, IsCreditSite)
				SELECT 
					@ProductId, 
					ss.siteID, 
					ex.exchangeid,
					@IsCreditSite
				FROM dbo.exchange ex WITH(NOLOCK)
					INNER JOIN [dbo].[f_Nap_WinLimit_CreditCurrencySel]() c ON c.Id = ex.exchangeid
					CROSS APPLY (SELECT siteID FROM @Site WHERE IsLicensee=0) ss
				WHERE(@CurrencyId = 0
					OR ex.exchangeid = @CurrencyId)
					AND ex.currency NOT IN('H', 'C');
			END;
		ELSE
			BEGIN
				INSERT INTO #ProductSiteCurrencySetting (ProductId, SiteId, CurrencyId, IsCreditSite)
				SELECT DISTINCT 
					@ProductId, 
					s.siteid, 
					lc.Currency,
					0 AS IsCreditSite
				FROM bodb_licensee.dbo.LicenseeCust lc WITH(NOLOCK)
					INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON l.LicenseeID = lc.LicenseeID
					INNER JOIN exchange ex WITH(NOLOCK) ON ex.exchangeid = lc.Currency
					INNER JOIN dbo.site s ON s.site = l.LicenseeName
										AND s.isActive = 1
					CROSS APPLY (SELECT 1 val FROM @Site ss WHERE ss.siteID=s.siteid AND ss.IsLicensee=1) ss
				WHERE (@CurrencyId = 0 OR lc.Currency = @CurrencyId)
					AND lc.CurrencyName NOT IN('H', 'C')
				UNION ALL
				SELECT 
					@ProductId, 
					ss.siteID, 
					ex.exchangeid,
					1 AS IsCreditSite
				FROM dbo.exchange ex WITH(NOLOCK)
					INNER JOIN [dbo].[f_Nap_WinLimit_CreditCurrencySel]() c ON c.Id = ex.exchangeid
					CROSS APPLY (SELECT siteID FROM @Site WHERE IsLicensee=0) ss
				WHERE(@CurrencyId = 0
					OR ex.exchangeid = @CurrencyId)
					AND ex.currency NOT IN('H', 'C');
			END
	END;
	BEGIN -- Query Data
		SELECT 
			p.ProductId, 
			p.LevelId, 
			p.GroupId, 
			pc.CurrencyId, 
			pc.SiteId, 
			ISNULL(s.MaxWinLimit_RM, 0) AS MaxWinLimit, 
			ISNULL(s.IsBlockedPlaceBet, 0) AS IsBlockedPlaceBet, 
			ISNULL(s.IsBlockedTransfer, 0) AS IsBlockedTransfer,
			ISNULL(s.IsSuspendedAccount, 0) AS IsSuspendedAccount, 
			IsCreditSite
		FROM #ProductSiteCurrencySetting pc
			INNER JOIN @Products p ON p.ProductId = pc.ProductId
			INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH(NOLOCK) ON s.ProductID = p.ProductId
																AND s.LevelID = p.LevelId
																AND s.SiteID = pc.SiteId
																AND s.ExchangeID = pc.CurrencyId
																AND s.GroupID = p.GroupId
		ORDER BY pc.SiteId,
				pc.CurrencyId, 
				p.LevelId;
	END;
	DROP TABLE #ProductSiteCurrencySetting;
END
GO