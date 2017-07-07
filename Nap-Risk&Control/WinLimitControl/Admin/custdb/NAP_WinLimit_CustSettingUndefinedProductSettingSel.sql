USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel]    Script Date: 07/07/2015 16:09:00 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel] @Username VARCHAR(100) = ''
AS
	
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:

EXEC [NAP_WinLimit_CustSettingUndefinedProductSettingSel] @Username = 'SPONUUS01045'
	
*/

     SET NOCOUNT ON;
     BEGIN -- @ProductSetting
         DECLARE @ProductSetting TABLE
         (ProductId TINYINT,
          GroupId   INT,
          LevelId   INT
         );
         INSERT INTO @ProductSetting
         (ProductId,
          GroupId,
          LevelId
         )
                SELECT DISTINCT
                       p.ProductId,
                       s.GroupId,
                       p.LevelId
                FROM dbo.f_Nap_WinLimit_ProductSettingSel(0) p
                     INNER JOIN dbo.WinLimit_GameGroupSetting s ON p.ProductId = s.ProductId;
     END;
     BEGIN -- @CustID, @CurrencyID.
         DECLARE @CustID INT, @CurrencyID INT, @AgentId INT, @SuperId INT;
         SELECT @CustID = c.custid,
                @CurrencyID = c.currency,
                @AgentId = c.recommend,
                @SuperId = c.srecommend
         FROM dbo.Customer c WITH (NOLOCK)
         WHERE c.username = @Username
               AND c.roleid = 1;
     END;
     BEGIN -- @SiteId
         DECLARE @SiteId INT;
         SELECT @SiteId = s.siteid
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.[Site] s WITH (NOLOCK) ON c.site = s.site
         WHERE CustId = @AgentId;
     END;
     BEGIN-- @IsDeposit
         DECLARE @IsDeposit INT;
         SELECT @IsDeposit = CASE
                                 WHEN EXISTS
         (
             SELECT 1
             FROM f_DepSuper_1('All')
             WHERE CustId = @SuperId
         )
                                 THEN 1
                                 ELSE 0
                             END;
     END;
     BEGIN -- @OfferProducts
         DECLARE @OfferProducts TABLE
         (ProductId INT,
          GroupId   INT,
          LevelId   INT
         );
         IF @IsDeposit = 0 -- Get all products
             BEGIN
                 INSERT INTO @OfferProducts
                        SELECT ProductId,
                               GroupId,
                               LevelId
                        FROM @ProductSetting;
             END;
         ELSE -- Get all products of licensee
             BEGIN
                 INSERT INTO @OfferProducts
                        SELECT p.ProductId,
                               p.GroupId,
                               p.LevelId
                        FROM @ProductSetting p
                             INNER JOIN
                        (
                            SELECT DISTINCT
                                   CASE
                                       WHEN ProductID = 14
                                       THEN 13
                                       ELSE ProductID
                                   END AS ProductID,
                                   LicenseeId
                            FROM DBLIC.bodb_licensee.dbo.LicenseeProduct3rd WITH (NOLOCK)
                        ) AS lp ON p.ProductId = lp.ProductId
                             INNER JOIN DBLIC.bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lp.licenseeId
                             INNER JOIN dbo.[Site] s WITH (NOLOCK) ON l.LicenseeName = s.[site]
                        WHERE s.[siteid] = @SiteId;
             END;
     END;
     BEGIN -- @ExistedSetting
         DECLARE @ExistedSetting TABLE
         (ProductId INT,
          GroupId   INT,
          LevelId   INT
         );
         INSERT INTO @ExistedSetting
                SELECT DISTINCT
                       ProductID,
                       GroupId,
                       LevelID
                FROM dbo.WinLimit_CustGameSetting wc WITH (NOLOCK)
                WHERE wc.CustId = @CustId;
     END;
     BEGIN -- Query
         SELECT @CustId CustId,
                @Username Username,
                @CurrencyId CurrencyId,
                @SiteId SiteId,
                p.ProductId,
                p.GroupId,
                p.LevelId,
                0 AS PlayerWinLimit,
                CASE
                    WHEN pd.MaxWinLimit IS NULL
                    THEN 0
                    ELSE 1
                END HasCurrencySetting
         FROM @OfferProducts p
              LEFT JOIN dbo.WinLimit_ProductSettingDetail pd WITH (NOLOCK) ON p.ProductId = pd.ProductId
                                                                              AND p.GroupId = pd.GroupId
                                                                              AND p.LevelId = pd.LevelId
                                                                              AND pd.ExchangeId = @CurrencyId
                                                                              AND pd.SiteId = @SiteId
         WHERE NOT EXISTS
         (
             SELECT 1
             FROM @ExistedSetting e
             WHERE p.ProductId = e.ProductId
                   AND p.GroupId = e.GroupId
                   AND p.LevelId = e.LevelId
         );
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel] TO [vnteam];
GO