ALTER PROCEDURE [dbo].[Age_CustomerSelLiveCSPositionTakingByMAg]
(
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*

	Created: 20120201@Sophia
	Date:  
	Task : Select Live Casino for PT List from custsettinggame
	DB: DBCUST.CustDB
	Original: Age_CustomerSelPositionTakingByMAg

	Revisions: 
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)

	Param's Explanation:
	• @MRecommend: Master Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM custinfo AS ci WITH (NOLOCK)
	WHERE ci.MRecommend = @MRecommend AND ci.roleid = 2 

	SELECT * 
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER( ORDER BY CASE WHEN ISNULL(ci.enabled,0) = 0 THEN 3 
											WHEN ISNULL(ci.closed,0) = 1 THEN 2 
											WHEN ISNULL(ci.reject,0) = 1 THEN 1 
											ELSE 0 
											END, ci.username) AS RowNumber,
			ci.closed, 
			ci.enabled, 
			ci.DisableLiveCasino, 
			ci.SyncLiveCasino,
			ISNULL(ci.reject,0) AS suspended,
			ci.username, 
			ci.custid,
			MAX(CASE WHEN cg.sporttype = 162 THEN cg.mpositiontaking ELSE 0 END) v162mpositiontaking,
			MAX(CASE WHEN cg.sporttype = 162 THEN cg.apositiontaking ELSE 0 END) v162apositiontaking
		FROM
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN custSettingGame AS cg WITH (NOLOCK) ON ci.custid = cg.custid	
		WHERE ci.MRecommend = @MRecommend 
			AND ci.roleid = 2 
			AND cg.sporttype = 162
		GROUP BY
			ci.enabled, 
			ci.closed, 
			ci.DisableLiveCasino, 
			ci.SyncLiveCasino, 
			ci.reject, 
			ci.username, 
			ci.custid	
	) t 
	WHERE RowNumber >= (@PageIndex - 1) * @PageSize + 1 AND RowNumber <= @PageIndex * @PageSize
END




GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCSPositionTakingByMAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCSPositionTakingByMAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelLiveCSPositionTakingByMAg] TO [VNTeam]
GO  