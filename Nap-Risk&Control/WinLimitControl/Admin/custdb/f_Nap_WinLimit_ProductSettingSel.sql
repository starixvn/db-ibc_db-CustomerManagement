USE [CustDB];
GO

/****** Object:  UserDefinedFunction [dbo].[f_Nap_WinLimit_ProductSettingSel]    Script Date: 07/11/2016 12:54:52 ******/

IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[f_Nap_WinLimit_ProductSettingSel]')
          AND type IN(N'FN', N'IF', N'TF', N'FS', N'FT')
)
    DROP FUNCTION [dbo].[f_Nap_WinLimit_ProductSettingSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION [dbo].[f_Nap_WinLimit_ProductSettingSel]
(@ProductId TINYINT = 0
)
RETURNS TABLE
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

Example:
SELECT * FROM [f_Nap_WinLimit_ProductSettingSel] (0)
*/

     RETURN
     SELECT ProductID AS ProductId,
            BettypeID AS BettypeId,
            LevelID AS LevelId,
            SettingStatus AS SettingStatus
     FROM dbo.Winlimit_ProductSetting WITH (NOLOCK)
     WHERE(@ProductId = 0
           OR ProductID = @ProductId)
          AND SettingStatus <= CASE
                                       WHEN(OBJECT_NAME(@@PROCID) LIKE '%[_]xtest%'
                                            OR OBJECT_NAME(@@PROCID) LIKE '%[_]xpre%'
                                            OR OBJECT_NAME(@@PROCID) LIKE '%[_]uat[1-9]%')
                                       THEN 1
                                       ELSE 0
                                   END;
GO
GRANT SELECT ON f_Nap_WinLimit_ProductSettingSel TO [bodbAdminNet,wsv_nap];
GO