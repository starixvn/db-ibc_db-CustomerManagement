/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/

CREATE FUNCTION [dbo].[f_GetFIPermission]()
RETURNS TABLE 
/*
    Created: 20200211@Tiara
    Task: Arrange detail permission for finance account
    DB: DBCUST/CustDB, DBONUSER/ON_USER, DBAGE/bodb02
    Original versions:                
    Revision:
		- 20200211@Tiara: Arrange detail permission for finance account [Redmine: #128128]

    Parameter's Explanation:

*/
RETURN
	SELECT CONVERT(VARCHAR(3), 'A') AS GroupName
	, CONVERT (VARCHAR(5),'All') AS Permission
	UNION ALL SELECT 'B', 'B'

GO

