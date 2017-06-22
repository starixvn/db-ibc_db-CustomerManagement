ALTER PROCEDURE  [dbo].[Age_CustSubSelInfo]
	@custid int,
	@subaccid int

AS
/*
	DB: DBCUST.CustDB
	 Revisions:
		- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
*/
--original SP: CustSubSelInfo
SET NOCOUNT ON


Select subaccid, username, firstname, lastname, isnull(closed, 0) closed, PageAccess
from custsub with (nolock)
where custid = @custid
	and subaccid = @subaccid
order by closed, username

GO
GRANT EXECUTE ON [dbo].[Age_CustSubSelInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustSubSelInfo] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubSelInfo] TO [vnteam] AS [dbo]