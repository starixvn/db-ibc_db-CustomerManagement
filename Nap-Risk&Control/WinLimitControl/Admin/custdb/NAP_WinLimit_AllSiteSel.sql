USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_AllSiteSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_AllSiteSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_AllSiteSel] @ProductId INT = NULL
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
EXEC [NAP_WinLimit_AllSiteSel]
*/


     SET NOCOUNT ON;
     SELECT siteid AS Id,
            site AS Name
     FROM dbo.Site WITH (NOLOCK)
     WHERE isActive = 1;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_AllSiteSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_AllSiteSel] TO [vnteam];
GO