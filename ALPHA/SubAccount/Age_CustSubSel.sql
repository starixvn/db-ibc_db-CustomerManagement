/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustSubSel] 
	@custid int
AS
--Agent site
--original SP: CustSubSel
/*
	DB: DBCUST.CustDB
	 Revisions:
		- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
		- 20190515@Kan: Add username2 as nickname in select list [Redmine:#112287]
*/
SET NOCOUNT ON

Select subaccid, username, username2 as nickname, firstname, lastname, createdate, isnull(closed, 0) closed, PageAccess
from custsub with (nolock)
where custid = @custid
order by closed, username

GO
