USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingSel] @UserName            NVARCHAR(100) = '',
                                                           @SiteID              INT           = 0,
                                                           @CurrencyID          INT           = 0,
                                                           @ProductID           TINYINT       = 0
AS
	
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:

Example: 
EXEC [NAP_WinLimit_CustSettingSel]

*/

     SET NOCOUNT ON;
     BEGIN -- @Products
         DECLARE @Products TABLE
         (ProductId TINYINT,
          LevelId   TINYINT
         );
         INSERT INTO @Products
         (ProductId,
          LevelId
         )
                SELECT DISTINCT
                       ProductId,
                       LevelId
                FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId);
     END;
     BEGIN -- Query
         SELECT c.CustID,
                c.username,
                c.currency CurrencyId,
                s.SiteId,
                p.ProductId,
                cs.GroupId,
                cs.LevelID,
                ISNULL(cs.MaxWinLimit_RM, 0) MaxWinLimit
         FROM dbo.WinLimit_CustGameSetting cs WITH (NOLOCK)
              INNER JOIN @Products p ON cs.ProductId = p.ProductId
                                        AND cs.LevelId = p.LevelId
              INNER JOIN dbo.custInfo c WITH (NOLOCK) ON cs.CustID = c.custid
              INNER JOIN dbo.customer a WITH (NOLOCK) ON a.custid = c.recommend
                                                         AND a.roleid = 2
              INNER JOIN dbo.[Site] s WITH (NOLOCK) ON s.[site] = a.[site]
         WHERE(@UserName = ''
               OR c.username = @UserName)
              AND (@CurrencyID = 0
                   OR c.currency = @CurrencyID)
              AND (@SiteID = 0
                   OR @SiteID = S.siteid)
         ORDER BY c.Username;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingSel] TO [vnteam];
GO