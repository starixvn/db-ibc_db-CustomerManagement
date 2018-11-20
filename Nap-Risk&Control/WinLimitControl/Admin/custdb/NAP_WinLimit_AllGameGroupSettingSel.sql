/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [CustDB];
GO

ALTER PROCEDURE dbo.NAP_WinLimit_AllGameGroupSettingSel
AS
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
		  - 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		  - 20181120@Robert: CWL - Happy 5 Integration [#103496]

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
	   INNER JOIN dbtxn.bodb02.dbo.SportBettypeMatrix AS sb ON g.ProductID = sb.ProductId
												    AND g.BetTypeID = sb.BetType
    WHERE sb.ProductId = 3
		AND sb.SportType = 164;

    SELECT ProductId
	    , GroupId
	    , SportId
	    , BetTypeId
    FROM #GameGroupSetting;

    DROP TABLE #GameGroupSetting;
END;
GO

GRANT EXECUTE ON dbo.NAP_WinLimit_AllGameGroupSettingSel TO [bodbAdminNet];
GO

GRANT VIEW DEFINITION ON dbo.NAP_WinLimit_AllGameGroupSettingSel TO [vnteam];
GO