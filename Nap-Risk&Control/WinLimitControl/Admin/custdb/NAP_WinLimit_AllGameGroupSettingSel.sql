/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.NAP_WinLimit_AllGameGroupSettingSel
AS
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBGLOB-GlobCustDB

Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20181120@Robert: CWL - Happy 5 Integration [#103496]
		- 20250227@Johnson: move sp to GlobCustDB [redmine: #216870]
Parameters Explanation:	

Example: 
EXEC [NAP_WinLimit_AllGameGroupSettingSel]

*/

BEGIN
    SET NOCOUNT ON;
    CREATE TABLE #GameGroupSetting(
	    ProductId    TINYINT
	  , GroupId      INT
	  , SportId      INT DEFAULT 0
	  , BetTypeId    SMALLINT);

    INSERT INTO #GameGroupSetting(ProductId
						  , GroupId
						  , SportId
						  , BetTypeId)
		 (
			SELECT ProductId
				, GroupId
				, 0 AS SportType
				, BetTypeId
			FROM dbo.WinLimit_GameGroupSetting WITH (NOLOCK)
		 );

    CREATE NONCLUSTERED INDEX IX_ProductId_BetTypeId ON #GameGroupSetting(ProductId, BetTypeId);

    UPDATE g
		 SET
			g.SportId = sb.SportType
    FROM #GameGroupSetting AS g
	   INNER JOIN SportBettypeSettingMatrix AS sb ON g.ProductID = sb.RealProductId
												    AND g.BetTypeID = sb.BetType
													AND sb.isLicensee = 0
													AND sb.isActive=1
    WHERE sb.RealProductId = 3
		AND sb.SportType = 164;

    SELECT ProductId
	    , GroupId
	    , SportId
	    , BetTypeId
    FROM #GameGroupSetting;

    DROP TABLE #GameGroupSetting;
END;
GO
