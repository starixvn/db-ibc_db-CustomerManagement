/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_CustomerSelPositionTakingBySAg]
(
	@SRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 100,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
	Task : Select Master Agent PT List
	DB: DBCUST.CustDB

	Revisions:
		- 20090331@Kiwi: Improve Reads by removing inner join customer
		- 20091204@Kiwi: Retrieve data from CustSetting3rd.
		- 20100311@Jamie: Edit to get HR Settings 
		- 20100916@Kiwi: Retrieve data for Mix Parlay of Mixed Sports and remove Mix Parlay Basketball
		- 20100917@Kaden: Remove Mix Parlay of Basketball (field v2spositiontaking_9).
		- 20110323@Lukas: Remove horse racing & FI
		- 20111128@Lukas: Add paging
		- 20131021@Kathy: Add HR Fixed Odds (154) [Redmine:#6505]
		- 20140630@Logan: Add BetRadar(9999) for Soccer and Tennis [Redmine: #18413]
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160114@Helen: Cricket - [Redmine: #50027]
		- 20160627@Helen: Provide dedicated Outright PT for each sport - [Redmine: 59438]
		- 20170302@Helen: BAIO - Cust setting - [Redmine: 71609]
		- 20170622@Winnie: Color for closed accounts  [RedmineID: #74494]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20190910@Winnie: Other Sports - Add New "Others" PT Setting for Badminton [redmine: #119713]
		- 20191031@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20221101@Elodie: Enhance SP [Redmine: #179269]
		- 20230327@Tacy: Alpha - Enhance to show First/Last name in reports [RedmineID: #185313]

	Param's Explanation:
	• @SRecommend: Super Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM 
		custinfo AS ci WITH (NOLOCK)		
	WHERE 
		ci.SRecommend = @SRecommend AND ci.roleid=3
		
	SELECT * 
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER(ORDER BY CASE WHEN ISNULL(ci.enabled,0) = 0 THEN 3 
											WHEN ISNULL(ps.closed,0) = 1 THEN 2 
											WHEN ISNULL(ps.reject,0) = 1 THEN 1 
											ELSE 0 
										END, ci.username) AS RowNumber,
			ps.closed, ci.enabled, 
			ISNULL(ps.reject,0) AS suspended,
			ci.username, 
			c.firstname,
			c.lastname,
			ci.custid, 
				
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_4,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_5,
			MAX(CASE WHEN cs.bettype = 6 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_6,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_8,
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_9,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_10,
			-- Outright PT
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=3 THEN cs.spositiontaking ELSE 0 END) AS v3spositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=5 THEN cs.spositiontaking ELSE 0 END) AS v5spositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=8 THEN cs.spositiontaking ELSE 0 END) AS v8spositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=10 THEN cs.spositiontaking ELSE 0 END) AS v10spositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=11 THEN cs.spositiontaking ELSE 0 END) AS v11spositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_10,
			
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=1 THEN cs.spositiontaking ELSE 0 END) AS spositiontaking_9999,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.slivepositiontaking ELSE 0 END) AS slivepositiontaking_1,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=1 THEN cs.slivepositiontaking ELSE 0 END) AS slivepositiontaking_3,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=1 THEN cs.slivepositiontaking ELSE 0 END) AS slivepositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=1 THEN cs.slivepositiontaking ELSE 0 END) AS slivepositiontaking_8,

			--basketball
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_8,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=2 THEN cs.spositiontaking ELSE 0 END) AS v2spositiontaking_9999,

			-- football
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=3 THEN cs.spositiontaking ELSE 0 END) AS v3spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=3 THEN cs.spositiontaking ELSE 0 END) AS v3spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=3 THEN cs.spositiontaking ELSE 0 END) AS v3spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=3 THEN cs.spositiontaking ELSE 0 END) AS v3spositiontaking_20,

			-- Tennis
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=5 THEN cs.spositiontaking ELSE 0 END) AS v5spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=5 THEN cs.spositiontaking ELSE 0 END) AS v5spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=5 THEN cs.spositiontaking ELSE 0 END) AS v5spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=5 THEN cs.spositiontaking ELSE 0 END) AS v5spositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=5 THEN cs.spositiontaking ELSE 0 END) AS v5spositiontaking_9999,

			-- Baseball
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=8 THEN cs.spositiontaking ELSE 0 END) AS v8spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=8 THEN cs.spositiontaking ELSE 0 END) AS v8spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=8 THEN cs.spositiontaking ELSE 0 END) AS v8spositiontaking_20,

			-- Golf
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=10 THEN cs.spositiontaking ELSE 0 END) AS v10spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=10 THEN cs.spositiontaking ELSE 0 END) AS v10spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=10 THEN cs.spositiontaking ELSE 0 END) AS v10spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=10 THEN cs.spositiontaking ELSE 0 END) AS v10spositiontaking_20,

			-- Motosport
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=11 THEN cs.spositiontaking ELSE 0 END) AS v11spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=11 THEN cs.spositiontaking ELSE 0 END) AS v11spositiontaking_20,

			-- Other sports
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_9999,
			
			-- Mix Parlay of Mixed Sports
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_9,

			ISNULL(cl.ClosedReason,0) AS ClosedReason,
			ISNULL(ps.Locked,0)	AS Locked	
		FROM 
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ci.custid
			INNER JOIN CustSetting AS cs WITH (NOLOCK) ON ci.custid = cs.custid	
			CROSS APPLY  (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS ps
			OUTER APPLY (SELECT TOP 1 ClosedReason FROM CustLoginInfo WITH(NOLOCK) WHERE custid=ci.CustID) cl
		WHERE ci.SRecommend = @SRecommend AND ci.roleid=3
		GROUP BY
			ci.enabled, ps.closed, ps.reject, ci.username, c.firstname, c.lastname, ci.custid,cl.ClosedReason, ps.Locked
	) t 
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
 
	
END


GO
