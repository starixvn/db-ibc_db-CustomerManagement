/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_CustomerSelPositionTakingByMAg]
(
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 100,
	@TotalPages	INT = 0 OUTPUT
)
AS

/*
	Task : Select Agent PT List
	DB: DBCUST.CustDB
	Revisions:
		- 20090331@Kiwi: Improve Reads by removing inner join customer
		- 20091204@Kiwi: Retrieve data from CustSetting3rd.
		- 20100311@Jamie: Edit to get HR Settings
		- 20100916@Kiwi: Retrieve data for Mix Parlay of Mixed Sports and remove Mix Parlay Basketball 
		- 20100917@Kaden: Remove Mix Parlay of Basketball (field v2mpositiontaking_9, v2apositiontaking_9).).
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
	• @MRecommend: Master Agent ID
*/
BEGIN

	SET NOCOUNT ON
	
	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM 
		custinfo AS ci WITH (NOLOCK)		
	WHERE 
		ci.MRecommend = @MRecommend AND ci.roleid=2 
	
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
			ISNULL(ps.reject,0) suspended,
			ci.username, 
			c.firstname,
			c.lastname,
			ci.custid, 
			
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_4,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_5,
			MAX(CASE WHEN cs.bettype = 6 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_6,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_8,
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_9,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_10,
			-- Outright PT for sports
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=3 THEN cs.apositiontaking ELSE 0 END) AS v3apositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=5 THEN cs.apositiontaking ELSE 0 END) AS v5apositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=8 THEN cs.apositiontaking ELSE 0 END) AS v8apositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=10 THEN cs.apositiontaking ELSE 0 END) AS v10apositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=11 THEN cs.apositiontaking ELSE 0 END) AS v11apositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_10,
			
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=1 THEN cs.apositiontaking ELSE 0 END) AS apositiontaking_9999,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.alivepositiontaking ELSE 0 END) AS alivepositiontaking_1,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=1 THEN cs.alivepositiontaking ELSE 0 END) AS alivepositiontaking_3,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=1 THEN cs.alivepositiontaking ELSE 0 END) AS alivepositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=1 THEN cs.alivepositiontaking ELSE 0 END) AS alivepositiontaking_8,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 4 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_4,
			MAX(CASE WHEN cs.bettype = 5 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_5,
			MAX(CASE WHEN cs.bettype = 6 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_6,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_8,
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_9,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_10,
			
			-- Outright PT for sports
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=3 THEN cs.mpositiontaking ELSE 0 END) AS v3mpositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=5 THEN cs.mpositiontaking ELSE 0 END) AS v5mpositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=8 THEN cs.mpositiontaking ELSE 0 END) AS v8mpositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=10 THEN cs.mpositiontaking ELSE 0 END) AS v10mpositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=11 THEN cs.mpositiontaking ELSE 0 END) AS v11mpositiontaking_10,
			MAX(CASE WHEN cs.bettype = 10 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_10,
			
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=1 THEN cs.mpositiontaking ELSE 0 END) AS mpositiontaking_9999,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=1 THEN cs.mlivepositiontaking ELSE 0 END) AS mlivepositiontaking_1,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=1 THEN cs.mlivepositiontaking ELSE 0 END) AS mlivepositiontaking_3,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=1 THEN cs.mlivepositiontaking ELSE 0 END) AS mlivepositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=1 THEN cs.mlivepositiontaking ELSE 0 END) AS mlivepositiontaking_8,

			--basketball
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_8,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=2 THEN cs.apositiontaking ELSE 0 END) AS v2apositiontaking_9999,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 7 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_7,
			MAX(CASE WHEN cs.bettype = 8 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_8,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=2 THEN cs.mpositiontaking ELSE 0 END) AS v2mpositiontaking_9999,

			--football
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=3 THEN cs.apositiontaking ELSE 0 END) AS v3apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=3 THEN cs.apositiontaking ELSE 0 END) AS v3apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=3 THEN cs.apositiontaking ELSE 0 END) AS v3apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=3 THEN cs.apositiontaking ELSE 0 END) AS v3apositiontaking_20,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=3 THEN cs.mpositiontaking ELSE 0 END) AS v3mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=3 THEN cs.mpositiontaking ELSE 0 END) AS v3mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=3 THEN cs.mpositiontaking ELSE 0 END) AS v3mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=3 THEN cs.mpositiontaking ELSE 0 END) AS v3mpositiontaking_20,

			--Tennis
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=5 THEN cs.apositiontaking ELSE 0 END) AS v5apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=5 THEN cs.apositiontaking ELSE 0 END) AS v5apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=5 THEN cs.apositiontaking ELSE 0 END) AS v5apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=5 THEN cs.apositiontaking ELSE 0 END) AS v5apositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=5 THEN cs.apositiontaking ELSE 0 END) AS v5apositiontaking_9999,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=5 THEN cs.mpositiontaking ELSE 0 END) AS v5mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=5 THEN cs.mpositiontaking ELSE 0 END) AS v5mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=5 THEN cs.mpositiontaking ELSE 0 END) AS v5mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=5 THEN cs.mpositiontaking ELSE 0 END) AS v5mpositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=5 THEN cs.mpositiontaking ELSE 0 END) AS v5mpositiontaking_9999,

			--baseball
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=8 THEN cs.apositiontaking ELSE 0 END) AS v8apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=8 THEN cs.apositiontaking ELSE 0 END) AS v8apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=8 THEN cs.apositiontaking ELSE 0 END) AS v8apositiontaking_20,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=8 THEN cs.mpositiontaking ELSE 0 END) AS v8mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=8 THEN cs.mpositiontaking ELSE 0 END) AS v8mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=8 THEN cs.mpositiontaking ELSE 0 END) AS v8mpositiontaking_20,

			--Golf
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=10 THEN cs.apositiontaking ELSE 0 END) AS v10apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=10 THEN cs.apositiontaking ELSE 0 END) AS v10apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=10 THEN cs.apositiontaking ELSE 0 END) AS v10apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=10 THEN cs.apositiontaking ELSE 0 END) AS v10apositiontaking_20,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=10 THEN cs.mpositiontaking ELSE 0 END) AS v10mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=10 THEN cs.mpositiontaking ELSE 0 END) AS v10mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=10 THEN cs.mpositiontaking ELSE 0 END) AS v10mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=10 THEN cs.mpositiontaking ELSE 0 END) AS v10mpositiontaking_20,

			--Motosports
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=11 THEN cs.apositiontaking ELSE 0 END) AS v11apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=11 THEN cs.apositiontaking ELSE 0 END) AS v11apositiontaking_20,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=11 THEN cs.mpositiontaking ELSE 0 END) AS v11mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=11 THEN cs.mpositiontaking ELSE 0 END) AS v11mpositiontaking_20,
	
			--Other sports
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_9999,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_20,
			MAX(CASE WHEN cs.bettype = 9999 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_9999,

			--Mix Parlay of Mixed Sports
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_9,
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_9,

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
		WHERE ci.MRecommend = @MRecommend AND ci.roleid=2 
		GROUP BY
			ci.enabled,
			ps.closed,
			ps.reject, 	
			ci.username,
			c.firstname,
			c.lastname,
			ci.custid,
			cl.ClosedReason,
			ps.Locked
	) t
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
		
END



GO
