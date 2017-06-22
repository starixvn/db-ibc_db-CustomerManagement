ALTER PROCEDURE [dbo].[Age_CustSubSel] 
	@custid int
AS
--Agent site
--original SP: CustSubSel
/*
	DB: DBCUST.CustDB
	 Revisions:
		- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
*/
SET NOCOUNT ON

Select subaccid, username, firstname, lastname,createdate, isnull(closed,0) closed, PageAccess
from custsub with (nolock)
where custid = @custid
order by closed, username

GO
GRANT EXECUTE ON [dbo].[Age_CustSubSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustSubSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubSel] TO [vnteam] AS [dbo]