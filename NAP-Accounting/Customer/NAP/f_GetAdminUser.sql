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
	SELECT CONVERT (INT,772168) AS UserID
	,CONVERT(VARCHAR(3), 'A') AS GroupName
	UNION ALL SELECT 772168,'A'
	UNION ALL SELECT 4240930,'A'
	UNION ALL SELECT 13304899,'A'
	UNION ALL SELECT 10576839,'A'
	UNION ALL SELECT 1277571,'B'
	UNION ALL SELECT 32324416,'B'
	UNION ALL SELECT 4210756,'B'
	UNION ALL SELECT 12667,'B'
	UNION ALL SELECT 1274,'B'

GO

