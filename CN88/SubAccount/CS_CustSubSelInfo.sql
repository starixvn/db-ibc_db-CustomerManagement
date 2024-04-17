/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE  CS_CustSubSelInfo
	@custid int,
	@subaccid int

AS
/*
	Created: 20190329
	Task : Sub-account Select
	DB: DBCust/CustDB

	Revisions:    
		- 20190329@Elodie: Initial SP [Redmine:#110497]
		- 20190715@Elodie: Sub account management [Redmine:#116825] 
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	SELECT username, firstname, PageAccess
	FROM custsub WITH(NOLOCK)
	WHERE custid = @custid
		AND subaccid = @subaccid AND IsDeleted = 0
END