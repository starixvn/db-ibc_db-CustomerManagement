USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_AllProductSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_AllProductSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [NAP_WinLimit_AllProductSel]
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
EXEC [NAP_WinLimit_AllProductSel]
*/

     SET NOCOUNT ON;
     SELECT DISTINCT
            p.ProductId Id,
            p.ProductName Name
     FROM dbo.f_Nap_WinLimit_ProductSettingSel(DEFAULT) s
          LEFT JOIN DBTXN.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID = s.ProductId
     ORDER BY p.ProductName;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_AllProductSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_AllProductSel] TO [vnteam];
GO