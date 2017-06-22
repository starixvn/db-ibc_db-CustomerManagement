/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

	DECLARE @IsIMBC BIT = 0
	
	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @MRecommend AND [Site] = 'IMBC')
		SET @IsIMBC = 1
	
	SELECT *, @IsIMBC AS IsIMBC
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER(ORDER BY CASE WHEN ISNULL(ci.enabled,0) = 0 THEN 3 
											WHEN ISNULL(ci.closed,0) = 1 THEN 2 
							 				WHEN ISNULL(ci.reject,0) = 1 THEN 1 
											ELSE 0 
										END, ci.username) AS RowNumber,
			ci.closed, ci.enabled, 
			ISNULL(ci.reject,0) suspended,
			ci.username, 
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

			--finance
		--	MAX(CASE WHEN cs3rd.bettype = 3 AND cs3rd.sporttype=201 THEN cs3rd.apositiontaking ELSE 0 END) v201apositiontaking_3,
		--	MAX(CASE WHEN cs3rd.bettype = 3 AND cs3rd.sporttype=201 THEN cs3rd.mpositiontaking ELSE 0 END) v201mpositiontaking_3,
		--
		--	MAX(CASE WHEN cs3rd.bettype = 2 AND cs3rd.sporttype=201 THEN cs3rd.apositiontaking ELSE 0 END) v201apositiontaking_2,
		--	MAX(CASE WHEN cs3rd.bettype = 2 AND cs3rd.sporttype=201 THEN cs3rd.mpositiontaking ELSE 0 END) v201mpositiontaking_2,
				
			--Horse
		--	MAX(CASE WHEN cs3rd.bettype = 31 AND cs3rd.sporttype=151 THEN cs3rd.apositiontaking ELSE 0 END) v151apositiontaking_31,
		--	MAX(CASE WHEN cs3rd.bettype = 32 AND cs3rd.sporttype=151 THEN cs3rd.apositiontaking ELSE 0 END) v151apositiontaking_32,
		--	MAX(CASE WHEN cs3rd.bettype = 41 AND cs3rd.sporttype=151 THEN cs3rd.apositiontaking ELSE 0 END) v151apositiontaking_41,
		--	MAX(CASE WHEN cs3rd.bettype = 42 AND cs3rd.sporttype=151 THEN cs3rd.apositiontaking ELSE 0 END) v151apositiontaking_42,
		--		
		--	MAX(CASE WHEN cs3rd.bettype = 31 AND cs3rd.sporttype=151 THEN cs3rd.mpositiontaking ELSE 0 END) v151mpositiontaking_31,
		--	MAX(CASE WHEN cs3rd.bettype = 32 AND cs3rd.sporttype=151 THEN cs3rd.mpositiontaking ELSE 0 END) v151mpositiontaking_32,	
		--	MAX(CASE WHEN cs3rd.bettype = 41 AND cs3rd.sporttype=151 THEN cs3rd.mpositiontaking ELSE 0 END) v151mpositiontaking_41,
		--	MAX(CASE WHEN cs3rd.bettype = 42 AND cs3rd.sporttype=151 THEN cs3rd.mpositiontaking ELSE 0 END) v151mpositiontaking_42,
			
			--Other sports
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_20,

			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_20,
			
			--Mix Parlay of Mixed Sports
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=99 THEN cs.apositiontaking ELSE 0 END) AS v99apositiontaking_9,
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=99 THEN cs.mpositiontaking ELSE 0 END) AS v99mpositiontaking_9,

			max(case when cs.bettype = 20 and cs.sporttype = 154 then cs.apositiontaking else 0 end) as v154apositiontaking_20,
			max(case when cs.bettype = 20 and cs.sporttype = 154 then cs.mpositiontaking else 0 end) as v154mpositiontaking_20,
			
			-- Cricket
			MAX(CASE WHEN pt.bettype = 501 and pt.IsLive = 1 THEN CAST(pt.AgentPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50apositiontaking_501_Live, 
			MAX(CASE WHEN pt.bettype = 501 and pt.IsLive = 1 THEN CAST(pt.MasterPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50mpositiontaking_501_Live, 
			
			MAX(CASE WHEN pt.bettype = 501 and pt.IsLive = 0 THEN CAST(pt.AgentPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50apositiontaking_501_NonLive, 
			MAX(CASE WHEN pt.bettype = 501 and pt.IsLive = 0 THEN CAST(pt.MasterPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50mpositiontaking_501_NonLive, 
			
			MAX(CASE WHEN pt.bettype = 599 and pt.IsLive = 1 THEN CAST(pt.AgentPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50apositiontaking_599_Live, 
			MAX(CASE WHEN pt.bettype = 599 and pt.IsLive = 1 THEN CAST(pt.MasterPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50mpositiontaking_599_Live, 
			
			MAX(CASE WHEN pt.bettype = 599 and pt.IsLive = 0 THEN CAST(pt.AgentPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50apositiontaking_599_NonLive, 
			MAX(CASE WHEN pt.bettype = 599 and pt.IsLive = 0 THEN CAST(pt.MasterPT AS SMALLMONEY) / 100 ELSE 0 END) AS v50mpositiontaking_599_NonLive,
			ISNULL(cl.ClosedReason,0) AS ClosedReason			
		FROM 
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN CustSetting AS cs WITH (NOLOCK) ON ci.custid = cs.custid
			LEFT JOIN CustPTSetting3rd_Agent pt WITH (NOLOCK) ON pt.CustID = ci.custid 
								AND pt.SportType = 50 AND pt.BetType IN (501,599) AND @IsIMBC = 1 
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE ci.MRecommend = @MRecommend AND ci.roleid=2 
		GROUP BY
			ci.enabled,
			ci.closed,
			ci.reject, 	
			ci.username, 
			ci.custid,
			cl.ClosedReason
	) t
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
		
END



GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByMAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByMAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelPositionTakingByMAg] TO [VNTeam]