ALTER PROCEDURE [dbo].[Age_CustomerSelLiveCasinoComm_MAg]
	@MRecommend INT
AS

/*
	Created: 20120201@Sophia
	Task : Select member commission information for Live Casino
	DB: DBCUST.CustDB
	Original: CustomerSelCommByMAg
	Revisions: 
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/

SET NOCOUNT ON

SELECT 
	ci.closed,
	ci.enabled, 
	isnull(ci.reject,0) as suspended, 
	m.username, 
	m.custid, 
	m.ugroup, 
	m.firstname, 
	m.lastname, 
	ci.credit,
	max(case when cs.sporttype = 162 then cs.adiscount else 0 end) * 100 as adiscount,
	max(case when cs.sporttype = 162 then cs.discount else 0 end) * 100 as discount,
	max(case when cs.sporttype = 162 then cs.playerdiscount else 0 end) * 100 as playerdiscount
FROM 
	customer AS m with (NOLOCK)
	INNER JOIN CustInfo as ci with (NOLOCK) on m.CustID = ci.CustID
	INNER JOIN CustSettingGame as cs with (NOLOCK) on m.CustID = cs.CustID
WHERE m.MRecommend = @MRecommend and m.roleid=1 
GROUP BY
	ci.enabled, 
	ci.closed, 
	ci.reject, 
	m.username, 
	m.custid, 
	m.ugroup, 
	m.firstname, 
	m.lastname, 
	ci.credit
ORDER BY 
	case 
		when isnull(ci.enabled, 0) = 0 then 3 
		when isnull(ci.closed, 0) = 1 then 2 
		when isnull(ci.reject, 0) = 1 then 1 
		else 0 
	end, 
	m.username


GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCasinoComm_MAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCasinoComm_MAg] TO [bodbDownlineNetView]
Go
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelLiveCasinoComm_MAg] TO [vnteam]
 