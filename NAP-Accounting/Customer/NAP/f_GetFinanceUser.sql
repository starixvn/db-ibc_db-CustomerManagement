/*<info serverAlias="DBCUST-CustDB" executers="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_GetFinanceUser]()
RETURNS TABLE 
/*
    Created: 20200210@Tiara
    Task: Arrange detail permission for finance account
    DB: DBCUST/CustDB
    Original versions:                
    Revision:
		- 20200210@Tiara: Arrange detail permission for finance account [Redmine: #128128]

    Parameter's Explanation:

*/
RETURN
	SELECT CONVERT (INT,36992242) AS CustID
	,CONVERT(VARCHAR(3), 'A') AS GroupName
	UNION ALL SELECT 39333414,'A'
	UNION ALL SELECT 40289263,'A'
	UNION ALL SELECT 39552204,'A'
	UNION ALL SELECT 37189685,'A'
	UNION ALL SELECT 40993048,'A'
	UNION ALL SELECT 37031637,'B'
	UNION ALL SELECT 38994136,'B'
	UNION ALL SELECT 38075058,'B'
	UNION ALL SELECT 41288140,'B'
	UNION ALL SELECT 40013533,'B'
	UNION ALL SELECT 40685637,'B'

GO


