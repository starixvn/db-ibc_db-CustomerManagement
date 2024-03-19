/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySel] @MultiSite			VARCHAR(Max),
                                                  @IsCreditSite			TINYINT = 0,
                                                  @ExcludeTestCurrency	BIT = 0
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
		- 20201111@Franklin: Remove un-used currencies [#140386]
		- 20230215@Tacy: CWL - Split 789y site [RedmineID: #182387]

	Parameters Explanation:  
		 @IsCreditSite:	0 ~ Licensee
						1 ~ Credit
						2 ~ Both  
		 @ExcludeTestCurrency: Exclude used Currency.  
     
	Example:
	EXEC [NAP_WinLimit_CurrencySel] @SiteId=32, @IsCreditSite = 1, @ExcludeTestCurrency = 1
*/
BEGIN
    SET NOCOUNT ON;

	CREATE TABLE #tempAllCurrencies(Id INT, Name VARCHAR(50));

	DECLARE @Site TABLE (siteID INT, IsLicensee BIT)

	IF @MultiSite<>'0'
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

    IF @MultiSite = '0' -- All Currencies
        BEGIN
		INSERT INTO #tempAllCurrencies
            SELECT Id,
                Name
            FROM [dbo].[f_Nap_WinLimit_CreditCurrencySel]()
            WHERE(@ExcludeTestCurrency = 0
                OR Name NOT IN('(UUS)'))
            UNION
            SELECT ex.exchangeid,
					CASE
					WHEN ex.exchangeid = 20
						THEN 'UUS'
						ELSE ex.Code
						END +' ('+ex.currency+')' 
            FROM bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                                                        AND S.isActive = 1
            WHERE ex.OfferSite IN (0, 2)
			AND ex.IsActive = 1
                AND (@ExcludeTestCurrency = 0
                    OR ex.currency NOT IN('UUS'))
                AND ex.currency NOT IN('H', 'C')
            ORDER BY Name;
		SELECT DISTINCT Id, Name From #tempAllCurrencies ORDER BY Name;
		END;
    ELSE IF @IsCreditSite = 1 -- Currencies for credit site
        BEGIN
            SELECT Id,
                Name
            FROM [dbo].[f_Nap_WinLimit_CreditCurrencySel]()
            WHERE(@ExcludeTestCurrency = 0
                OR Name NOT IN('(UUS)'))
            ORDER BY Name;
        END;
    ELSE IF @IsCreditSite = 0-- Currencies for deposit site
        BEGIN
            SELECT DISTINCT
                ex.exchangeid AS Id,
                ex.Code+' ('+ex.currency+')' AS Name
            FROM bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                                                        AND S.isActive = 1
				CROSS APPLY (SELECT 1 val FROM @Site ss WHERE ss.siteID=s.siteid AND ss.IsLicensee=1) ss
            WHERE (@ExcludeTestCurrency = 0 OR ex.currency NOT IN('UUS'))
                AND ex.currency NOT IN('H', 'C')
				AND ex.IsActive = 1
            ORDER BY Name;
        END;
	ELSE
		BEGIN
			SELECT Id,
                Name
            FROM [dbo].[f_Nap_WinLimit_CreditCurrencySel]()
            WHERE(@ExcludeTestCurrency = 0
                OR Name NOT IN('(UUS)'))
			UNION
			SELECT DISTINCT
                ex.exchangeid AS Id,
                CASE
					WHEN ex.exchangeid = 20
						THEN 'UUS'
						ELSE ex.Code
						END +' ('+ex.currency+')' AS Name
            FROM bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                                                        AND S.isActive = 1
				CROSS APPLY (SELECT 1 val FROM @Site ss WHERE ss.siteID=s.siteid AND ss.IsLicensee=1) ss
            WHERE (@ExcludeTestCurrency = 0 OR ex.currency NOT IN('UUS'))
                AND ex.currency NOT IN('H', 'C')
				AND ex.IsActive = 1
            ORDER BY Name
		END;

	DROP TABLE #tempAllCurrencies;
END
GO
