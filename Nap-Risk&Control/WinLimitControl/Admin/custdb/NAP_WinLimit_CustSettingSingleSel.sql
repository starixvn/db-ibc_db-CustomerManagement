USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingSingleSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingSingleSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingSingleSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingSingleSel] @CustId    INT,
                                                           @ProductID INT,
                                                           @GroupId   INT
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
EXEC [NAP_WinLimit_CustSettingSingleSel] @CustId=18766097, @ProductId=6, @GroupId =1

*/

     SET NOCOUNT ON;
     SELECT CustId,
            ProductId,
            GroupId,
            LevelId,
            MaxWinLimit_RM
     FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
     WHERE CustID = @CustID
           AND ProductID = @ProductID
           AND GroupId = @GroupId;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingSingleSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingSingleSel] TO [vnteam];
GO