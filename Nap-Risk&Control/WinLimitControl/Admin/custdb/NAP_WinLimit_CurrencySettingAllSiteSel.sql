USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingAllSiteSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingAllSiteSel];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingAllSiteSel] @ProductId  INT,
                                                                @CurrencyId INT = 0
AS

/*
Created: Jacob	
Date: 2017-03-13
Task: #72604 - Implement Game Win Limit Control phase2 3A

DB: DBCUST/CustDB

Revisions:
20170313@Jacob: Risk & Control - Phase 3A [#72604].

Parameters Explanation:
   @ProductId: Product ID
   
Example:
EXEC [NAP_WinLimit_CurrencySettingAllSiteSel] @ProductId = 22, @CurrencyId = 72
*/


     SET NOCOUNT ON;
     BEGIN -- All LicenseeDeposit Licensee

         DECLARE @AllLicensees TABLE
         (LicenseeId   INT,
          LicenseeName NVARCHAR(50)
         );
         INSERT INTO @AllLicensees
         (LicenseeId,
          LicenseeName
         )
                SELECT l.LicenseeId,
                       l.LicenseeName
                FROM DBLIC.bodb_licensee.dbo.LicenseeProduct3rd lp WITH (NOLOCK)
                     INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeId = lp.LicenseeId
                     INNER JOIN
                (
                    SELECT DISTINCT
                           CASE
                               WHEN ProductId = 13
                               THEN 14
                               ELSE ProductId
                           END ProductId
                    FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId)
                ) p ON p.ProductId = lp.ProductId;
     END;
     BEGIN -- @Products
         DECLARE @Products TABLE
         (ProductId TINYINT,
          GroupId   INT,
          LevelId   TINYINT
         );
         INSERT INTO @Products
         (ProductId,
          LevelId,
          GroupId
         )
                SELECT DISTINCT
                       p.ProductId,
                       p.LevelId,
                       s.GroupId
                FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId) p
                     INNER JOIN dbo.WinLimit_GameGroupSetting s WITH (NOLOCK) ON p.ProductId = s.ProductId;
     END;
     BEGIN --#ProductSiteCurrencySetting
         CREATE TABLE #ProductSiteCurrencySetting
         (ProductId    TINYINT,
          SiteId       SMALLINT,
          CurrencyId   TINYINT,
          IsCreditSite BIT
         );
         INSERT INTO #ProductSiteCurrencySetting
                SELECT DISTINCT
                       @ProductId,
                       s.siteId,
                       lc.Currency,
                       0 AS IsCreditSite
                FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                     INNER JOIN @AllLicensees l ON l.LicenseeID = lc.LicenseeID
                     INNER JOIN exchange ex WITH (NOLOCK) ON ex.exchangeid = lc.Currency
                     INNER JOIN dbo.site s ON s.site = l.LicenseeName
                                              AND s.isLicensee = 1
                                              AND s.isActive = 1
                WHERE lc.CurrencyName NOT IN('H', 'C')
                UNION
                SELECT @ProductId,
                       T.SiteId,
                       c.Id,
                       1 AS IsCreditSite
                FROM [dbo].[f_Nap_WinLimit_CreditCurrencySel]() c
                     CROSS APPLY
                (
                    SELECT s.siteid AS SiteId
                    FROM dbo.Site s WITH (NOLOCK)
                    WHERE s.isLicensee = 0
                          AND S.isActive = 1
                ) AS T;
     END;
     BEGIN -- Query Data
         SELECT p.ProductId,
                p.LevelId,
                p.GroupId,
                pc.CurrencyId,
                pc.SiteId,
                pc.IsCreditSite,
                ISNULL(s.MaxWinLimit_RM, 0) AS MaxWinLimit,
                ISNULL(s.IsBlockedPlaceBet, 0) AS IsBlockedPlaceBet,
                ISNULL(s.IsBlockedTransfer, 0) AS IsBlockedTransfer
         FROM #ProductSiteCurrencySetting pc
              INNER JOIN @Products p ON p.ProductId = pc.ProductId
              INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH (NOLOCK) ON s.ProductID = p.ProductId
                                                                              AND s.LevelID = p.LevelId
                                                                              AND s.SiteID = pc.SiteId
                                                                              AND s.ExchangeID = pc.CurrencyId
                                                                              AND s.GroupID = p.GroupId
         WHERE @CurrencyId = 0
               OR pc.CurrencyId = @CurrencyId
         ORDER BY pc.CurrencyId,
                  p.LevelId;
     END;
     DROP TABLE #ProductSiteCurrencySetting;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingAllSiteSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingAllSiteSel] TO [vnteam];
GO