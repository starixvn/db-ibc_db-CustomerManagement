/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelNumberGamePositionTakingBySAg]
(
	@SRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
	Created: 20100904@Kiwi
	Task : Select Number Game for PT List from custsetting3rd
	DB: DBCUST.CustDB

	Revisions:
		- 20110801@Sophia: Add bettype 88,89,90
		- 20111128@Lukas: Add paging
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20170622@Winnie: Color for closed accounts  [RedmineID: #74494]
	Param's Explanation:
	• @SRecommend: Super Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM custinfo AS ci WITH (NOLOCK)
	WHERE ci.SRecommend = @SRecommend AND ci.roleid = 3

	SELECT *
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER( ORDER BY CASE WHEN ISNULL(ci.enabled, 0) = 0 THEN 3 
											WHEN ISNULL(ci.closed, 0) = 1 THEN 2 
											WHEN ISNULL(ci.reject, 0) = 1 THEN 1 
											ELSE 0 
										END, ci.username) AS RowNumber,
			ci.closed, ci.enabled, 
			ISNULL(ci.reject,0) AS suspended,
			ci.username, 
			ci.custid, 
			
			-- Deadball NumberGame
			MAX(CASE WHEN cs3rd.bettype = 81 AND cs3rd.sporttype=161 THEN cs3rd.spositiontaking ELSE 0 END) v161spositiontaking_81,
			MAX(CASE WHEN cs3rd.bettype = 83 AND cs3rd.sporttype=161 THEN cs3rd.spositiontaking ELSE 0 END) v161spositiontaking_83,
			MAX(CASE WHEN cs3rd.bettype = 85 AND cs3rd.sporttype=161 THEN cs3rd.spositiontaking ELSE 0 END) v161spositiontaking_85,
			MAX(CASE WHEN cs3rd.bettype = 86 AND cs3rd.sporttype=161 THEN cs3rd.spositiontaking ELSE 0 END) v161spositiontaking_86,
			MAX(CASE WHEN cs3rd.bettype = 88 AND cs3rd.sporttype=161 THEN cs3rd.spositiontaking ELSE 0 END) v161spositiontaking_88,
		 
			--LiveBall NumberGame
			MAX(CASE WHEN cs3rd.bettype = 85 AND cs3rd.sporttype=161 THEN cs3rd.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_85,
			MAX(CASE WHEN cs3rd.bettype = 86 AND cs3rd.sporttype=161 THEN cs3rd.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_86,
			MAX(CASE WHEN cs3rd.bettype = 87 AND cs3rd.sporttype=161 THEN cs3rd.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_87,
			MAX(CASE WHEN cs3rd.bettype = 89 AND cs3rd.sporttype=161 THEN cs3rd.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_89,
			MAX(CASE WHEN cs3rd.bettype = 90 AND cs3rd.sporttype=161 THEN cs3rd.slivepositiontaking ELSE 0 END) AS v161slivepositiontaking_90,
			ISNULL(cl.ClosedReason,0) AS ClosedReason	
		FROM
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN CustSetting3rd AS cs3rd WITH (NOLOCK) ON ci.custid = cs3rd.custid	
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE ci.SRecommend = @SRecommend AND ci.roleid=3
		GROUP BY
			ci.enabled, ci.closed, ci.reject, ci.username, ci.custid,cl.ClosedReason		
	) t
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize

END





GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelNumberGamePositionTakingBySAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelNumberGamePositionTakingBySAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelNumberGamePositionTakingBySAg] TO [VNTeam]
GO 