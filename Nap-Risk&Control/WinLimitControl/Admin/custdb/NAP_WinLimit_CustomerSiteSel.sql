USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustomerSiteSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustomerSiteSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustomerSiteSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustomerSiteSel] @UserNameList NVARCHAR(MAX) = ''
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
EXEC [NAP_WinLimit_CustomerSiteSel] @UserNameList = '12BETEURO01,12BETEURO01001,12BETEURO01002'

*/

     SET NOCOUNT ON;
     DECLARE @User TABLE(Username NVARCHAR(100));
     INSERT INTO @User(Username)
            SELECT val
            FROM dbo.strSplit(@UserNameList, ',');
     SELECT c.username,
            a.[site] SiteName
     FROM dbo.custInfo c WITH (NOLOCK)
          INNER JOIN @User u ON c.username = u.Username
          INNER JOIN dbo.Customer a WITH (NOLOCK) ON c.recommend = a.custid;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustomerSiteSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustomerSiteSel] TO [vnteam];
GO