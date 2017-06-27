/*<info serverAlias="DBCust-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelGDPositionTakingByMAg]
(
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*

	Created: 20150507@Sophia  
	Task :	Select Gold Deluxe of Agents
	DB:		DBCUST.CustDB
	Original: Age_CustomerSelLiveCSPositionTakingByMAg

	Revisions: 
		- 20150616@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)

	Param's Explanation:
	• @MRecommend: Master Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM
		dbo.custinfo AS ci WITH (NOLOCK)
		INNER JOIN dbo.custSettingGame AS cg WITH (NOLOCK) ON ci.custid = cg.custid	
	WHERE ci.MRecommend = @MRecommend AND ci.roleid = 2 AND cg.sporttype = 255
	
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

			MAX(CASE WHEN cg.sporttype=255 THEN cg.mpositiontaking ELSE 0 END) v255mpositiontaking,
			MAX(CASE WHEN cg.sporttype=255 THEN cg.apositiontaking ELSE 0 END) v255apositiontaking
			
		FROM
			dbo.custinfo AS ci WITH (NOLOCK)
			INNER JOIN dbo.custSettingGame AS cg WITH (NOLOCK) ON ci.custid = cg.custid	
		WHERE ci.MRecommend = @MRecommend AND ci.roleid=2 AND cg.sporttype = 255
		GROUP BY
			ci.enabled, ci.closed, ci.DisableGoldDeluxe, ci.reject, ci.username, ci.custid	
	) t 
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
END