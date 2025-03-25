/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingUndefinedProductSettingSel] @Username VARCHAR(100) = ''
AS
	
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
	20160923@Jacob: Risk & Control - Phase 3 [#61220].
	20180921@Jacob: Migrate some of Licensee Setting tables (LRF System) from DB052.bodb_Licensee to DBCust.bodb_Licensee [#99855]
	20240118@Tacy: NAP Risk & Control - Merge VS1, VS2, VS3 as Virtual Sports [Redmine: #199920]
	20250122@Tacy: Offer direct member for super/master [Redmine: #215809]

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
         DECLARE @CustID INT, @CurrencyID INT, @SiteId INT, @IsDeposit INT;
         SELECT @CustID = c.custid,
                @CurrencyID = c.currency,
                @SiteId = s.siteid,
                @IsDeposit = s.isDeposit
         FROM dbo.Customer c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
         WHERE c.username = @Username
               AND c.roleid = 1;
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
						CROSS APPLY (SELECT lp.LicenseeName
									 FROM bodb_licensee.dbo.f_Nap_SiteByProductSel(p.ProductId) lp) lp
						INNER JOIN [Site] s WITH (NOLOCK) ON lp.LicenseeName = s.[site]
					WHERE s.[siteid] = @SiteId
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
