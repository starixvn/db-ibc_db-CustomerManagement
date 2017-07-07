USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySel] @SiteId              INT = 0,
                                                  @IsCreditSite        BIT = 0,
                                                  @ExcludeTestCurrency BIT = 0
AS  
   
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
20170313@Jacob: Risk & Control - Phase 3A [#72604].
Parameters Explanation:  
     @SiteId: Site Or Licensee ID.  
     @IsCreditSite: Is Credit Site.  
     @ExcludeTestCurrency: Exclude used Currency.  
     
Example:
EXEC [NAP_WinLimit_CurrencySel] @SiteId=32, @IsCreditSite = 1, @ExcludeTestCurrency = 1
*/

     SET NOCOUNT ON;
     IF @SiteId = 0 -- All Currencies
         BEGIN
             SELECT Id,
                    Name
             FROM [dbo].[f_Nap_WinLimit_CreditCurrencySel]()
             WHERE(@ExcludeTestCurrency = 0
                   OR Name NOT IN('(UUS)'))
             UNION
             SELECT ex.exchangeid,
                    ex.Code+' ('+ex.currency+')'
             FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                  INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                  INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                  INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                                                         AND S.isActive = 1
             WHERE s.siteid = @SiteId
                   AND (@ExcludeTestCurrency = 0
                        OR ex.currency NOT IN('UUS'))
                  AND ex.currency NOT IN('H', 'C')
             ORDER BY Name;
         END;
     ELSE
     IF @IsCreditSite = 1 -- Currencies for credit site
         BEGIN
             SELECT Id,
                    Name
             FROM [dbo].[f_Nap_WinLimit_CreditCurrencySel]()
             WHERE(@ExcludeTestCurrency = 0
                   OR Name NOT IN('(UUS)'))
             ORDER BY Name;
         END;
     ELSE -- Currencies for deposit site
         BEGIN
             SELECT DISTINCT
                    ex.exchangeid AS Id,
                    ex.Code+' ('+ex.currency+')' AS Name
             FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                  INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                  INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
                  INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName
                                                         AND S.isActive = 1
             WHERE s.siteid = @SiteId
                   AND (@ExcludeTestCurrency = 0
                        OR ex.currency NOT IN('UUS'))
                  AND ex.currency NOT IN('H', 'C')
             ORDER BY Name;
         END;;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySel] TO [vnteam];
GO