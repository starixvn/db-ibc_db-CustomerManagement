/*<info serverAlias="DBGLOB-GlobCustDB" selecters="wsv_nap" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_Nap_WinLimit_ProductSettingSel]
(@ProductId TINYINT = 0
)
RETURNS TABLE
AS
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBGLOB-GlobCustDB

Revisions:
	- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
	- 20250226@Johnson: move sp to GlobCustDB [redmine: #216870]

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
