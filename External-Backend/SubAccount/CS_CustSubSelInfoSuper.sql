/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustSubSelInfoSuper
	@username VARCHAR(50)
AS
/*
	Created: 20190719
	Task: Get sub account information of Super CN88 only
	DB: DBCust/CustDB

	Revisions:    
		- 20190719@Kan: Sub-Account Permission on downline [Redmine:#116825]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @db_Username2 VARCHAR(50)
	SELECT @db_Username2 = Nickname FROM dbo.f_CS_GetNickName(@username, 1)

	SELECT c.username AS SMAUsername, cn.NickName AS SMANickname,
		sb.subaccid, sb.custid, sb.username, n.NickName, sb.PageAccess, sb.firstname
	FROM custsub sb WITH(NOLOCK)
		INNER JOIN Customer c WITH(NOLOCK) ON c.custid = sb.custid
		CROSS APPLY (SELECT NickName FROM dbo.f_CS_GetNickName(c.username2, 0)) cn
		CROSS APPLY (SELECT NickName FROM dbo.f_CS_GetNickName(sb.username2, 0)) n
	WHERE (sb.username = @username OR sb.UserName2 = @db_Username2)
		AND ISNULL(sb.IsDeleted, 0) = 0
		AND c.roleid = 4
		AND c.site = 'CN88'
END
