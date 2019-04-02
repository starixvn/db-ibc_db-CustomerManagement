/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE CS_CustSubSel
	@custid INT
AS
/*
	Created: 20190329
	Task : Sub-account List
	DB: DBCust/CustDB

	Revisions:    
		- 20190329@Elodie: Initial SP [Redmine:#110497]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	SELECT subaccid, username, firstname, createdate, PageAccess
	FROM custsub WITH(NOLOCK)
	WHERE custid = @custid
	ORDER BY username
END
