USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingSingleSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSingleSel];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingSingleSel] @ProductId  INT,
                                                               @SiteId     INT,
                                                               @CurrencyId INT,
                                                               @GroupId    INT
AS
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
Parameters Explanation:
   @ProductId: Product ID
   @SiteId	: Site or Licensee ID
   @IsCreditSite: Is Credit Site
   @CurrencyId	: Currency ID
   
Example:
EXEC [NAP_WinLimit_CurrencySettingSingleSel] @ProductId = 6, @SiteId = 30, @CurrencyId = 1, @GroupId = 1
*/


     SET NOCOUNT ON;
     SELECT ProductID,
            GroupID,
            ExchangeID,
            SiteID,
            LevelID,
            MaxWinLimit,
            IsBlockedPlaceBet,
            IsBlockedTransfer,
            MaxWinLimit_RM
     FROM dbo.WinLimit_ProductSettingDetail WITH (NOLOCK)
     WHERE ProductID = @ProductId
           AND ExchangeID = @CurrencyId
           AND SiteID = @SiteId
           AND GroupId = @GroupId;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingSingleSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingSingleSel] TO [vnteam];
GO