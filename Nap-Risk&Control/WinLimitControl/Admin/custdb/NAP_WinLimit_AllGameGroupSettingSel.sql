USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_AllGameGroupSettingSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_AllGameGroupSettingSel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_AllGameGroupSettingSel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_AllGameGroupSettingSel]
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
EXEC [NAP_WinLimit_AllGameGroupSettingSel]

*/

     SET NOCOUNT ON;
     SELECT ProductId,
            GroupId,
            BetTypeId
     FROM dbo.WinLimit_GameGroupSetting WITH (NOLOCK);
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_AllGameGroupSettingSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_AllGameGroupSettingSel] TO [vnteam];
GO