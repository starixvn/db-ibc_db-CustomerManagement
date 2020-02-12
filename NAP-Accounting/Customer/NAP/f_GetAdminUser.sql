/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="1"></info>*/

ALTER FUNCTION [dbo].[f_GetAdminUser]()
RETURNS TABLE 
/*
    Created: 20200211@Tiara
    Task: Get Admin user permission info
    DB: DBCUST/CustDB
    Original versions:                
    Revision:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]

    Parameter's Explanation:

*/
RETURN
	SELECT CONVERT (INT,111) AS UserID
	,CONVERT(VARCHAR(3), 'A') AS GroupName
	UNION ALL SELECT 151, 'A'
	UNION ALL SELECT 161, 'A'
	UNION ALL SELECT 888, 'B'
	UNION ALL SELECT 8627, 'B'
	UNION ALL SELECT 8646, 'B'
	UNION ALL SELECT 8652, 'B'
	UNION ALL SELECT 12667, 'B'

GO

