ALTER PROCEDURE [dbo].[Age_CustomerSelComm_MAg]
	@MRecommend int
AS
BEGIN
/*
Created: 
Task : Select member commission information
DB: DBCUST.CustDB
Original: CustomerSelCommByMAg
Revisions:
	- 20091204@Kiwi: Retrieve data from CustSetting3rd for Financials.
	- 20100603@Jamie: Fix getting 3rd commission
	- 20100904@Kiwi: Get NumberGame Commission.
	- 20110323@Lukas: Remove horse racing
	- 20120928@Sophia: Get DoubleCommLosing
	- 20131021@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20160114@Helen: Cricket - [Redmine: #50027]
*/

	SET NOCOUNT ON
				
	SELECT 
		ci.closed,ci.enabled, isnull(ci.reject,0) as suspended, m.username, m.custid, m.ugroup, 
		m.firstname, m.lastname, ci.credit, ci.DoubleCommLosing,
		max(case when cs.bettype = 1 and cs.sporttype=1 then cs.adiscount else 0 end)*100 as adiscount,
		max(case when cs.bettype = 1 and cs.sporttype=1 then cs.discount else 0 end)*100 as discount,
		max(case when cs.bettype = 1 and cs.sporttype=1 then cs.playerdiscount else 0 end)*100 as playerdiscount,

		max(case when cs.bettype = 4 and cs.sporttype=1 then cs.adiscount else 0 end)*100 as adiscountcs,
		max(case when cs.bettype = 4 and cs.sporttype=1 then cs.discount else 0 end)*100 as discountcs,
		max(case when cs.bettype = 4 and cs.sporttype=1 then cs.playerdiscount else 0 end)*100 as playerdiscountcs,

		--Get 1x2
		max(case when cs.bettype = 5 and cs.sporttype=1 then cs.adiscount else 0 end)*100 as adiscount1x2,
		max(case when cs.bettype = 5 and cs.sporttype=1 then cs.discount else 0 end)*100 as discount1x2,
		max(case when cs.bettype = 5 and cs.sporttype=1 then cs.playerdiscount else 0 end)*100 as playerdiscount1x2,

		-- Myanmar Odds
		ISNULL(ccr.adiscount,0) * 100 AS adiscountMyanmarOdds,
		ISNULL(ccr.discount,0) * 100 AS discountMyanmarOdds,
		ISNULL(ccr.playerdiscount,0) * 100 AS playerdiscountMyanmarOdds, 
		--Get Horse Racing for Tote and Fixed odd
	--	max(case when cs3rd.bettype = 31 and cs3rd.sporttype=151 then cs3rd.adiscount else 0 end)*100 adiscount_hr_to,
	--	max(case when cs3rd.bettype = 31 and cs3rd.sporttype=151 then cs3rd.discount else 0 end)*100 discount_hr_to,
	--	max(case when cs3rd.bettype = 31 and cs3rd.sporttype=151 then cs3rd.playerdiscount else 0 end)*100 playerdiscount_hr_to,	
	--	
	--	max(case when cs3rd.bettype = 41 and cs3rd.sporttype=151 then cs3rd.adiscount else 0 end)*100 adiscount_hr_fo,
	--	max(case when cs3rd.bettype = 41 and cs3rd.sporttype=151 then cs3rd.discount else 0 end)*100 discount_hr_fo,
	--	max(case when cs3rd.bettype = 41 and cs3rd.sporttype=151 then cs3rd.playerdiscount else 0 end)*100 playerdiscount_hr_fo,
	--	
		--Get Financial commission 	
	--	max(case when cs3rd.bettype = 3 and cs3rd.sporttype=201 then cs3rd.adiscount else 0 end)*100 adiscount_financial,
	--	max(case when cs3rd.bettype = 3 and cs3rd.sporttype=201 then cs3rd.discount else 0 end)*100 discount_financial,
	--	max(case when cs3rd.bettype = 3 and cs3rd.sporttype=201 then cs3rd.playerdiscount else 0 end)*100 playerdiscount_financial,
		
		-- HR Fixed Odds
		max(case when cs.bettype = 20 and cs.sporttype = 154 then cs.adiscount else 0 end) * 100 as adiscountHRFixedOdds,
		max(case when cs.bettype = 20 and cs.sporttype = 154 then cs.discount else 0 end) * 100 as discountHRFixedOdds,
		max(case when cs.bettype = 20 and cs.sporttype = 154 then cs.playerdiscount else 0 end) * 100 as playerdiscountHRFixedOdds,

		--Get NumberGame commission 	
		max(case when cs3rd.bettype = 81 and cs3rd.sporttype=161 then cs3rd.adiscount else 0 end)*100 adiscount_numbergame,
		max(case when cs3rd.bettype = 81 and cs3rd.sporttype=161 then cs3rd.discount else 0 end)*100 discount_numbergame,
		max(case when cs3rd.bettype = 81 and cs3rd.sporttype=161 then cs3rd.playerdiscount else 0 end)*100 playerdiscount_numbergame,
		--End
		-- Cricket
		ISNULL(cdm.MasterDiscount,0) * 100 adiscount_cricket,
		ISNULL(cdm.AgentDiscount,0) * 100 discount_cricket,
		ISNULL(cdm.playerdiscount,0) * 100 playerdiscount_cricket
		
	FROM 
		customer AS m with (NOLOCK)
		INNER JOIN CustInfo as ci with (NOLOCK) on m.CustID = ci.CustID
		INNER JOIN CustSetting as cs with (NOLOCK) on m.CustID = cs.CustID
		INNER JOIN CustSetting3rd as cs3rd with (NOLOCK) on m.custID = cs3rd.CustID
		LEFT JOIN CustCommRate ccr WITH (NOLOCK) ON CCR.CustId = CI.custid AND CCR.Sporttype = 1 AND CCR.Bettype = 301
		LEFT JOIN CustDiscount3rd_Member cdm WITH (NOLOCK) ON  cdm.CustID = ci.custid AND cdm.SportType = 50 AND cdm.BetType = 501
	WHERE m.MRecommend = @MRecommend and m.roleid=1 
	GROUP BY
		ci.enabled, ci.closed, ci.reject, m.username, m.custid, m.ugroup, 
		m.firstname, m.lastname, ci.credit, ci.DoubleCommLosing,ccr.adiscount,ccr.discount,ccr.playerdiscount,cdm.AgentDiscount,cdm.MasterDiscount,cdm.PlayerDiscount
	ORDER BY 
	case when isnull(ci.enabled,0) = 0 then 3 when isnull(ci.closed,0) = 1 then 2 when isnull(ci.reject,0) = 1 then 1 else 0 end, 
	m.username


END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelComm_MAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelComm_MAg] TO [bodbDownlineNetView]
Go
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelComm_MAg] TO [vnteam]
