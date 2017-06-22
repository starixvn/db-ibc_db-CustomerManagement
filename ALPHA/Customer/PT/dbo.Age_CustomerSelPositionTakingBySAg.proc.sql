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
	
	DECLARE @IsIMBC BIT = 0
	
	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @SRecommend AND [Site] = 'IMBC')
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
			ISNULL(ci.reject,0) AS suspended,
			ci.username, 
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

			-- Financial
		--	MAX(CASE WHEN cs3rd.bettype = 3 AND cs3rd.sporttype=201 THEN cs3rd.spositiontaking ELSE 0 END) v201spositiontaking_3,
		--	MAX(CASE WHEN cs3rd.bettype = 2 AND cs3rd.sporttype=201 THEN cs3rd.spositiontaking ELSE 0 END) v201spositiontaking_2,

			-- Horse
		--	MAX(CASE WHEN cs3rd.bettype = 31 AND cs3rd.sporttype=151 THEN cs3rd.spositiontaking ELSE 0 END) v151spositiontaking_31,
		--	MAX(CASE WHEN cs3rd.bettype = 32 AND cs3rd.sporttype=151 THEN cs3rd.spositiontaking ELSE 0 END) v151spositiontaking_32,
		--	MAX(CASE WHEN cs3rd.bettype = 41 AND cs3rd.sporttype=151 THEN cs3rd.spositiontaking ELSE 0 END) v151spositiontaking_41,
		--	MAX(CASE WHEN cs3rd.bettype = 42 AND cs3rd.sporttype=151 THEN cs3rd.spositiontaking ELSE 0 END) v151spositiontaking_42,

			-- Other sports
			MAX(CASE WHEN cs.bettype = 1 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_1,
			MAX(CASE WHEN cs.bettype = 2 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_2,
			MAX(CASE WHEN cs.bettype = 3 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_3,
			MAX(CASE WHEN cs.bettype = 20 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_20,
			
			-- Mix Parlay of Mixed Sports
			MAX(CASE WHEN cs.bettype = 9 AND cs.sporttype=99 THEN cs.spositiontaking ELSE 0 END) AS v99spositiontaking_9,

			-- HR Fixed Odds
			max(case when cs.bettype = 20 and cs.sporttype = 154 then cs.spositiontaking else 0 end) as v154spositiontaking_20,
			
			-- Cricket
			MAX(CASE WHEN pt.bettype = 501 and pt.IsLive = 1 THEN CAST(pt.SuperPT AS SMALLMONEY) /100 ELSE 0 END) AS v50spositiontaking_501_Live, 
			MAX(CASE WHEN pt.bettype = 501 and pt.IsLive = 0 THEN CAST(pt.SuperPT AS SMALLMONEY) /100 ELSE 0 END) AS v50spositiontaking_501_NonLive,
			MAX(CASE WHEN pt.bettype = 599 and pt.IsLive = 1 THEN CAST(pt.SuperPT AS SMALLMONEY) /100 ELSE 0 END) AS v50spositiontaking_599_Live,
			MAX(CASE WHEN pt.bettype = 599 and pt.IsLive = 0 THEN CAST(pt.SuperPT AS SMALLMONEY) /100 ELSE 0 END) AS v50spositiontaking_599_NonLive

		FROM 
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN CustSetting AS cs WITH (NOLOCK) ON ci.custid = cs.custid	
			LEFT JOIN CustPTSetting3rd_Agent pt WITH (NOLOCK) ON pt.CustID = ci.custid 
								AND pt.SportType = 50 AND pt.BetType IN (501,599) AND @IsIMBC = 1 
		WHERE ci.SRecommend = @SRecommend AND ci.roleid=3
		GROUP BY
			ci.enabled, ci.closed, ci.reject, ci.username, ci.custid
	) t 
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
 
	
END


GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingBySAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingBySAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelPositionTakingBySAg] TO [VNTeam]
GO 

