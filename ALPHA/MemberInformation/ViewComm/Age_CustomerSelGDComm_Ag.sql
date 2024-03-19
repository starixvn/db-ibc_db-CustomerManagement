ALTER PROCEDURE [dbo].[Age_CustomerSelGDComm_Ag]
	@recommend INT
AS

/*
	Created:	20150506@Sophia
	TASk :		Select commission information for Gold Deluxe
	DB:			DBCUST.CustDB
	Original:	Age_CustomerSelLiveCasinoComm_Ag
	Revisions: 
		- 20150616@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/

SET NOCOUNT ON

BEGIN 
	SELECT  ci.closed, ci.enabled, ISNULL(ci.reject, 0) AS suspended, m.username, m.custid, m.ugroup, 
			m.firstname, m.lastname, ci.credit,	
			MAX(CASE WHEN cs.sporttype = 255 THEN cs.adiscount ELSE 0 END) * 100 AS adiscount,
			MAX(CASE WHEN cs.sporttype = 255 THEN cs.discount ELSE 0 END) * 100 AS discount,
			MAX(CASE WHEN cs.sporttype = 255 THEN cs.playerdiscount ELSE 0 END) * 100 AS playerdiscount
	FROM  dbo.customer AS m WITH (NOLOCK)
		INNER JOIN dbo.CustInfo AS ci WITH (NOLOCK)	
			ON m.CustID = ci.CustID
		INNER JOIN dbo.CustSettingGame AS cs WITH (NOLOCK) 
			ON m.CustID = cs.CustID
	WHERE	m.recommend = @recommend and m.roleid = 1 
	GROUP BY ci.enabled, ci.closed, ci.reject, m.username, m.custid, m.ugroup, 
			 m.firstname, m.lastname, ci.credit
	ORDER BY 
		CASE 
			WHEN ISNULL(ci.enabled, 0) = 0 THEN 3 
			WHEN ISNULL(ci.closed, 0) = 1 THEN 2 
			WHEN ISNULL(ci.reject, 0) = 1 THEN 1 
			ELSE 0 
		END, 
		m.username

END


GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelGDComm_Ag] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelGDComm_Ag] TO [bodbDownlineNetView,wsv_alpv]
Go 