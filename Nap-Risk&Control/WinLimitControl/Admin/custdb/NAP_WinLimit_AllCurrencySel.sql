USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_AllCurrencySel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_AllCurrencySel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE NAP_WinLimit_AllCurrencySel
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:
EXEC NAP_WinLimit_AllCurrencySel
*/


     SET NOCOUNT ON;
     SELECT e.exchangeid AS Id,
            e.Code+' ('+e.currency+')' AS Name
     FROM dbo.exchange e WITH (NOLOCK);
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_AllCurrencySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_AllCurrencySel] TO [vnteam];
GO