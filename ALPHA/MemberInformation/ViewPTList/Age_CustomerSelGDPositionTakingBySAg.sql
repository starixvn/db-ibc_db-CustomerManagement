/*<info serverAlias="DBCust-CustDB" executers="wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelGDPositionTakingBySAg]
(
	@SRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
	Created: 20150507@Sophia
	Task : Select Gold Deluxe of Masters
	DB: DBCUST/CustDB
	Original: Age_CustomerSelLiveCSPositionTakingBySAg

	Revisions: 
		- 20150616@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20170627@Winnie: Apply color for closed account [RedmineID: #74494]
	Param's Explanation:
	• @SRecommend: Super Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM
		dbo.custinfo AS ci WITH (NOLOCK)
		INNER JOIN dbo.CustSettingGame AS cg WITH (NOLOCK) ON ci.custid = cg.custid	
	WHERE ci.SRecommend = @SRecommend AND ci.roleid=3 AND cg.sporttype = 255
 
	SELECT *
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER( ORDER BY CASE WHEN ISNULL(ci.enabled,0) = 0 THEN 3 
											WHEN ISNULL(ci.closed,0) = 1 THEN 2 
											WHEN ISNULL(ci.reject,0) = 1 THEN 1 
											ELSE 0 
										END, ci.username) AS RowNumber,
			ci.closed, ci.enabled, 
			ci.DisableGoldDeluxe,
			ISNULL(ci.reject,0) AS suspended,
			ci.username, 
			ci.custid,
			MAX(CASE WHEN cg.sporttype=255 THEN cg.spositiontaking ELSE 0 END) v255spositiontaking,
			ISNULL(cl.ClosedReason,0) AS ClosedReason
		FROM
			dbo.custinfo AS ci WITH (NOLOCK)
			INNER JOIN dbo.CustSettingGame AS cg WITH (NOLOCK) ON ci.custid = cg.custid
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE ci.SRecommend = @SRecommend AND ci.roleid=3 AND cg.sporttype = 255
		GROUP BY
			ci.enabled, ci.closed, ci.DisableGoldDeluxe, ci.reject, ci.username, ci.custid, cl.ClosedReason
	) t
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize

END
GO