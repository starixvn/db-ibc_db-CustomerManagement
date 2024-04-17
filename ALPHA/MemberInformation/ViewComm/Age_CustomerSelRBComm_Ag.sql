
ALTER PROCEDURE [dbo].[Age_CustomerSelRBComm_Ag]
	@Recommend INT
AS
/*
	Created: 20110311@Lukas
	Task : Select member commission information
	DB: DBCUST.CustDB
	Original: [Age_CustomerSelComm_Ag]
	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
*/
BEGIN
	SET NOCOUNT ON	

	SELECT 
		ci.enabled, 
		ci.closed, 
		isnull(ci.reject, 0) as suspended, 
		m.username, 
		m.custid, 
		m.ugroup, 
		m.firstname, 
		m.lastname,
		
		max(case when cs3rd.bettype = 31 and cs3rd.sporttype=151 then cs3rd.adiscount else 0 end)*100		as v151adiscount_31,
		max(case when cs3rd.bettype = 31 and cs3rd.sporttype=151 then cs3rd.discount else 0 end)*100		as v151discount_31,
		max(case when cs3rd.bettype = 31 and cs3rd.sporttype=151 then cs3rd.playerdiscount else 0 end)*100	as v151playerdiscount_31,	
		
		max(case when cs3rd.bettype = 41 and cs3rd.sporttype=151 then cs3rd.adiscount else 0 end)*100		as v151adiscount_41,
		max(case when cs3rd.bettype = 41 and cs3rd.sporttype=151 then cs3rd.discount else 0 end)*100		as v151discount_41,
		max(case when cs3rd.bettype = 41 and cs3rd.sporttype=151 then cs3rd.playerdiscount else 0 end)*100	as v151playerdiscount_41,	

		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=151 then cs3rd.adiscount else 0 end)*100		as v151adiscount_51,
		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=151 then cs3rd.discount else 0 end)*100		as v151discount_51,
		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=151 then cs3rd.playerdiscount else 0 end)*100	as v151playerdiscount_51,	

		max(case when cs3rd.bettype = 41 and cs3rd.sporttype=152 then cs3rd.adiscount else 0 end)*100		as v152adiscount_41,
		max(case when cs3rd.bettype = 41 and cs3rd.sporttype=152 then cs3rd.discount else 0 end)*100		as v152discount_41,
		max(case when cs3rd.bettype = 41 and cs3rd.sporttype=152 then cs3rd.playerdiscount else 0 end)*100	as v152playerdiscount_41,	

		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=152 then cs3rd.adiscount else 0 end)*100		as v152adiscount_51,
		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=152 then cs3rd.discount else 0 end)*100		as v152discount_51,
		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=152 then cs3rd.playerdiscount else 0 end)*100	as v152playerdiscount_51,	

		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=153 then cs3rd.adiscount else 0 end)*100		as v153adiscount_51,
		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=153 then cs3rd.discount else 0 end)*100		as v153discount_51,
		max(case when cs3rd.bettype = 51 and cs3rd.sporttype=153 then cs3rd.playerdiscount else 0 end)*100	as v153playerdiscount_51,		
		
		ci.credit
	FROM 
		customer AS m with (NOLOCK)
		INNER JOIN CustInfo as ci with (NOLOCK) on m.CustID = ci.CustID
		INNER JOIN CustSetting3rd as cs3rd with (NOLOCK) on m.custID = cs3rd.CustID 
	WHERE 
		m.Recommend = @recommend 
		AND m.roleid = 1 
		AND cs3rd.sporttype BETWEEN 151 AND 153
	group by
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
			when isnull(ci.enabled, 0) = 0 then 3 
			when isnull(ci.closed, 0) = 1 then 2 
			when isnull(ci.reject, 0) = 1 then 1 
			else 0 
		end, 
		m.username
END



GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelRBComm_Ag] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelRBComm_Ag] TO [bodbDownlineNetView,wsv_alpv]
Go
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelRBComm_Ag] TO [vnteam]
