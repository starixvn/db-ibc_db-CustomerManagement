ALTER PROCEDURE [dbo].[Age_CustomerSelLiveCasinoComm_Ag]
	@Recommend INT
AS

/*
	Created: 20120201@Sophia
	Task : Select member commission information for Live Casino
	DB: DBCUST.CustDB
	Original: CustomerSelCommByAg
	Revisions: 
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/

SET NOCOUNT ON

SELECT 
	ci.closed,
	ci.enabled, 
	ISNULL(ci.reject, 0) AS suspended, 
	m.username, 
	m.custid, 
	m.ugroup, 
	m.firstname, 
	m.lastname, 
	ci.credit,
	MAX(CASE WHEN cs.sporttype = 162 THEN cs.adiscount ELSE 0 END) * 100 AS adiscount,
	MAX(CASE WHEN cs.sporttype = 162 THEN cs.discount ELSE 0 END) * 100 AS discount,
	MAX(CASE WHEN cs.sporttype = 162 THEN cs.playerdiscount ELSE 0 END) * 100 AS playerdiscount
FROM 
	customer AS m WITH (NOLOCK)
	INNER JOIN CustInfo AS ci WITH (NOLOCK) ON m.CustID = ci.CustID
	INNER JOIN CustSettingGame AS cs WITH (NOLOCK) ON m.CustID = cs.CustID
WHERE m.Recommend = @Recommend and m.roleid = 1 
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
	CASE 
		WHEN ISNULL(ci.enabled, 0) = 0 THEN 3 
		WHEN ISNULL(ci.closed, 0) = 1 THEN 2 
		WHEN ISNULL(ci.reject, 0) = 1 THEN 1 
		ELSE 0 
	END, 
	m.username



GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCasinoComm_Ag] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCasinoComm_Ag] TO [bodbDownlineNetView,wsv_alpv]
Go
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelLiveCasinoComm_Ag] TO [vnteam]
 