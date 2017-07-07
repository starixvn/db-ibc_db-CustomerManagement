USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustomerSiteByCustIdSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustomerSiteByCustIdSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustomerSiteByCustIdSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustomerSiteByCustIdSel] @CustIdList NVARCHAR(MAX) = ''
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
EXEC [NAP_WinLimit_CustomerSiteByCustIdSel] @CustIdList = '791088,807023,807567'
*/

     SET NOCOUNT ON;
     DECLARE @Customer TABLE(CustId INT);
     INSERT INTO @Customer(CustId)
            SELECT CONVERT( INT, val)
            FROM dbo.strSplit(@CustIdList, ',');
     SELECT c.custid,
            c.username,
            a.[site] SiteName
     FROM dbo.custInfo c WITH (NOLOCK)
          INNER JOIN @Customer u ON c.custid = u.custid
          INNER JOIN dbo.Customer a WITH (NOLOCK) ON c.recommend = a.custid;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustomerSiteByCustIdSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustomerSiteByCustIdSel] TO [vnteam];
GO