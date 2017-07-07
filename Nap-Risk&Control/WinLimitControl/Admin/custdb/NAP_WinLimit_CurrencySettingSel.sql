USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSel] @ProductId    INT,
                                                         @SiteId       INT,
                                                         @IsCreditSite BIT = 0,
                                                         @CurrencyId   INT = 0
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
   @ProductId: Product ID
   @SiteId	: Site or Licensee ID
   @IsCreditSite: Is Credit Site
   @CurrencyId	: Currency ID
   
Example:
EXEC [NAP_WinLimit_CurrencySettingSel] @ProductId=21,@SiteId=32,@IsCreditSite=1,@CurrencyId=72


*/


     SET NOCOUNT ON;
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
         (ProductId  TINYINT,
          SiteId     SMALLINT,
          CurrencyId TINYINT
         );
         IF @IsCreditSite = 0
             BEGIN
                 INSERT INTO #ProductSiteCurrencySetting
                        SELECT DISTINCT
                               @ProductId,
                               @SiteId,
                               lc.Currency
                        FROM DBLIC.bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
                             INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
                             INNER JOIN exchange ex WITH (NOLOCK) ON ex.exchangeid = lc.Currency
                             INNER JOIN dbo.site s ON s.site = l.LicenseeName
                                                      AND s.isActive = 1
                        WHERE s.siteid = @SiteId
                              AND (@CurrencyId = 0
                                   OR lc.Currency = @CurrencyId)
                              AND lc.CurrencyName NOT IN('H', 'C');
             END;
         ELSE
             BEGIN
                 INSERT INTO #ProductSiteCurrencySetting
                        SELECT @ProductId,
                               @SiteId,
                               ex.exchangeid
                        FROM dbo.exchange ex WITH (NOLOCK)
                             INNER JOIN [dbo].[f_Nap_WinLimit_CreditCurrencySel]() c ON c.Id = ex.exchangeid
                        WHERE(@CurrencyId = 0
                              OR ex.exchangeid = @CurrencyId)
                             AND ex.currency NOT IN('H', 'C');
             END;
     END;
     BEGIN -- Query Data
         SELECT p.ProductId,
                p.LevelId,
                p.GroupId,
                pc.CurrencyId,
                pc.SiteId,
                ISNULL(s.MaxWinLimit_RM, 0) AS MaxWinLimit,
                ISNULL(s.IsBlockedPlaceBet, 0) AS IsBlockedPlaceBet,
                ISNULL(s.IsBlockedTransfer, 0) AS IsBlockedTransfer,
                @IsCreditSite AS IsCreditSite
         FROM #ProductSiteCurrencySetting pc
              INNER JOIN @Products p ON p.ProductId = pc.ProductId
              INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH (NOLOCK) ON s.ProductID = p.ProductId
                                                                              AND s.LevelID = p.LevelId
                                                                              AND s.SiteID = pc.SiteId
                                                                              AND s.ExchangeID = pc.CurrencyId
                                                                              AND s.GroupID = p.GroupId
         ORDER BY pc.CurrencyId,
                  p.LevelId;
     END;
     DROP TABLE #ProductSiteCurrencySetting;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingSel] TO [vnteam];
GO