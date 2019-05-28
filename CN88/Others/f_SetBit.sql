/*<info serverAlias="DBCUST-CustDB" selecters="" viewers="" isFunction="1" isNested="1"></info>*/

ALTER FUNCTION [dbo].[f_SetBit] (
	@Val TINYINT,
	@Pos TINYINT,
	@Bit BIT
)
/*  
	Created by: Paul  
	Date: 2019-05-14
	Task: 
	DB: DBCUST/CustDB
	Original SP:
	Revisions:
		- 20190514@Paul: Create new function [RedmineID: #113198]
*/

RETURNS TABLE
AS
RETURN
(
	SELECT	CASE @Bit
				WHEN 0 THEN @Val & (~POWER(2, @Pos))
				WHEN 1 THEN @Val | POWER(2, @Pos)
			END AS Val
)
GO