/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustSubSel
	@custid INT
AS
/*
	Created: 20190329
	Task : Sub-account List
	DB: DBCust/CustDB

	Revisions:    
		- 20190329@Elodie: Initial SP [Redmine:#110497]
		- 20190715@Elodie: Sub account management [Redmine:#116825] 
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	SELECT subaccid, username, n.NickName, firstname, createdate, PageAccess, Closed
	FROM custsub sb WITH(NOLOCK)
		CROSS APPLY (SELECT NickName FROM dbo.f_CS_GetNickName(sb.username2,0)) n
	WHERE custid = @custid AND sb.IsDeleted = 0
	ORDER BY username
END
