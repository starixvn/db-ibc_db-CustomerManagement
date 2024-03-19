/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
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
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20190905@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]
	- 20210528@Elodie: Remove useless code [Redmine: #155825]
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
*/

	SET NOCOUNT ON

	CREATE TABLE #CustTemp(custID INT PRIMARY KEY, username VARCHAR(50), ugroup VARCHAR(10), firstname NVARCHAR(254), lastname NVARCHAR(254), enabled BIT, credit MONEY, DoubleCommLosing BIT)

	INSERT INTO #CustTemp(custid, username, ugroup, firstname, lastname, Enabled, credit, DoubleCommLosing)
	SELECT c.custid, c.username, c.ugroup, c.firstname, c.lastname, ci.Enabled, ci.credit, ci.DoubleCommLosing
	FROM Customer c WITH (NOLOCK)
		INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
	WHERE c.mrecommend = @MRecommend AND c.roleid = 1
				
	SELECT 
		cps.closed,ci.enabled, isnull(cps.reject,0) as suspended, ci.username, ci.custid, ci.ugroup, 
		ci.firstname, ci.lastname, ci.credit, ci.DoubleCommLosing,
		max(case when cs.bettype = 1 then cs.adiscount else 0 end)*100 as adiscount,
		max(case when cs.bettype = 1 then cs.discount else 0 end)*100 as discount,
		max(case when cs.bettype = 1 then cs.playerdiscount else 0 end)*100 as playerdiscount,

		max(case when cs.bettype = 4 then cs.adiscount else 0 end)*100 as adiscountcs,
		max(case when cs.bettype = 4 then cs.discount else 0 end)*100 as discountcs,
		max(case when cs.bettype = 4 then cs.playerdiscount else 0 end)*100 as playerdiscountcs,

		--Get 1x2
		max(case when cs.bettype = 5 then cs.adiscount else 0 end)*100 as adiscount1x2,
		max(case when cs.bettype = 5 then cs.discount else 0 end)*100 as discount1x2,
		max(case when cs.bettype = 5 then cs.playerdiscount else 0 end)*100 as playerdiscount1x2,
		
		-- Myanmar Odds
		ISNULL(ccr.adiscount,0) * 100 AS adiscountMyanmarOdds,
		ISNULL(ccr.discount,0) * 100 AS discountMyanmarOdds,
		ISNULL(ccr.playerdiscount,0) * 100 AS playerdiscountMyanmarOdds, 
		
		-- Cricket
		ISNULL(cdm.MasterDiscount,0) * 100 adiscount_cricket,
		ISNULL(cdm.AgentDiscount,0) * 100 discount_cricket,
		ISNULL(cdm.playerdiscount,0) * 100 playerdiscount_cricket,
		cps.Locked		,
		cl.ClosedReason
	FROM 
		#CustTemp AS ci with (NOLOCK)
		INNER JOIN CustSetting as cs with (NOLOCK) on ci.CustID = cs.CustID AND cs.bettype IN (1,4,5) AND cs.sporttype=1
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, ISNULL(Locked, 0) Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
		LEFT JOIN CustDiscount3rd_Member cdm WITH (NOLOCK) ON  cdm.CustID = ci.custid AND cdm.SportType = 50 AND cdm.BetType = 501
		LEFT JOIN CustCommRate ccr WITH (NOLOCK) ON CCR.CustId = CI.custid AND CCR.Sporttype = 1 AND CCR.Bettype = 1
		LEFT JOIN CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustID = ci.custid
	GROUP BY
		ci.enabled, cps.closed, cps.reject, cps.Locked, ci.username, ci.custid, ci.ugroup,ccr.adiscount,ccr.discount,ccr.playerdiscount, 
		ci.firstname, ci.lastname, ci.credit, ci.DoubleCommLosing,cdm.AgentDiscount,cdm.MasterDiscount,cdm.PlayerDiscount, cl.ClosedReason
	ORDER BY 
		case when isnull(ci.enabled,0) = 0 then 3 when isnull(cps.closed,0) = 1 then 2 when isnull(cps.reject,0) = 1 then 1 else 0 end, 
		ci.username
END
GO
