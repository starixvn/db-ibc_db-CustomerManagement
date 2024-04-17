/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelLiveCSPositionTakingBySAg]
(
	@SRecommend INT,
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
	Original: Age_CustomerSelPositionTakingBySAg
	Revisions: 
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
			ci.closed, 
			ci.enabled, 
			ci.DisableLiveCasino, 
			ci.SyncLiveCasino,
			ISNULL(ci.reject, 0) AS suspended,
			ci.username, 
			ci.custid,
			MAX(CASE WHEN cg.sporttype = 162 THEN cg.spositiontaking ELSE 0 END) v162spositiontaking,
			ISNULL(cl.ClosedReason,0) AS ClosedReason
		FROM
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN CustSettingGame AS cg WITH (NOLOCK) ON ci.custid = cg.custid	
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE 
			ci.SRecommend = @SRecommend 
			AND ci.roleid = 3 
			AND cg.sporttype = 162
		GROUP BY
			ci.enabled, 
			ci.closed, 
			ci.DisableLiveCasino, 
			ci.SyncLiveCasino, 
			ci.reject, 
			ci.username, 
			ci.custid,
			cl.ClosedReason
	) t
	WHERE RowNumber >= (@PageIndex - 1) * @PageSize + 1 AND RowNumber <= @PageIndex * @PageSize

END




GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCSPositionTakingBySAg] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelLiveCSPositionTakingBySAg] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelLiveCSPositionTakingBySAg] TO [VNTeam]
GO  