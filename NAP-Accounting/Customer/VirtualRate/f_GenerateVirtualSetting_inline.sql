/*<info serverAlias="DBCUST-CustDB" executers="" viewers="vnteam" isFunction="1"></info>*/
USE [CustDB]
GO

ALTER FUNCTION [dbo].[f_GenerateVirtualSetting_inline] (@Bin BINARY(64), @NewVal VARBINARY(64), @Pos VARBINARY(64))   
RETURNS TABLE  
AS  
/*
	Created: Paul @ 20180823
	DB: DBCust.custDB

	Revision:      
		- 20180823@Paul: Create new [RedmineID:#99839]
		- 20190411@Paul: Enhance and change to use recursion [RedmineID:#110345]
	Param's Explanation:   
		@Pos:  '0x0102030405' 
*/ 
RETURN  (
	WITH cte AS (
		SELECT CAST(1 AS INT) AS loopcount, @Bin AS val

		UNION ALL

		SELECT  loopcount + 1, 
				CAST(STUFF(val, CAST(SUBSTRING(@Pos, loopcount, 1) AS INT), 1, SUBSTRING(@NewVal, loopcount, 1)) AS BINARY(64))
		FROM cte
		WHERE loopcount <= 64
			AND loopcount <= LEN(@NewVal)
	)
	SELECT TOP 1 val AS bitmap 
	FROM cte 
	ORDER BY loopcount DESC
)

GO