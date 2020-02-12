/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_GetFinanceUser]()
RETURNS TABLE 
/*
    Created: 20200210@Tiara
    Task: Arrange detail permission for finance account
    DB: DBCUST/CustDB, DBONUSER/ON_USER, DBAGE/bodb02
    Original versions:                
    Revision:
		- 20200210@Tiara: Arrange detail permission for finance account [Redmine: #128128]

    Parameter's Explanation:

*/
RETURN
	SELECT CONVERT (INT,676156) AS CustID
	,CONVERT(VARCHAR(3), 'A') AS GroupName
	UNION ALL SELECT 675758, 'A'
	UNION ALL SELECT 676178, 'A'
	UNION ALL SELECT 676537, 'A'
	UNION ALL SELECT 676788, 'A'
	UNION ALL SELECT 676793, 'B'
	UNION ALL SELECT 676878, 'B'

GO


