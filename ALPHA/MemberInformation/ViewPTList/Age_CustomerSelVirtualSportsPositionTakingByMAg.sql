/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelVirtualSportsPositionTakingByMAg]
(
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*

	Created: 20120809@Sophia
	Date:  
	Task : Select Virtual Sports for PT List from custsettinggame
	DB: DBCUST.CustDB
	Original: Age_CustomerSelPositionTakingByMAg

	Revisions: 
		- 20121204@Tom: Add  virtual tennis setting (sporttype : 186 , bettype : 1220)
		- 20130305@Johnson: add virtual horse racing setting (sporttype: 181)
		- 20131126@Kathy: Add Virtual Greyhounds/Motor Racing (182, 184) [Redmine:#7234]
		- 20140402@Dom: Add Virtual Speedway/ Cycling setting (sporttype: 183,185)
		- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
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
			ci.DisableVirtualSports, ci.HideVirtualSports,
			ISNULL(ci.reject,0) AS suspended,
			ci.username, 
			ci.custid,

			MAX(CASE WHEN cg.sporttype=180 THEN cg.mpositiontaking ELSE 0 END) v180mpositiontaking,
			MAX(CASE WHEN cg.sporttype=180 THEN cg.apositiontaking ELSE 0 END) v180apositiontaking,
			
			MAX(CASE WHEN cg.sporttype=181 THEN cg.mpositiontaking ELSE 0 END) v181mpositiontaking,
			MAX(CASE WHEN cg.sporttype=181 THEN cg.apositiontaking ELSE 0 END) v181apositiontaking,

			MAX(CASE WHEN cg.sporttype=182 THEN cg.mpositiontaking ELSE 0 END) v182mpositiontaking,
			MAX(CASE WHEN cg.sporttype=182 THEN cg.apositiontaking ELSE 0 END) v182apositiontaking,

			MAX(CASE WHEN cg.sporttype=184 THEN cg.mpositiontaking ELSE 0 END) v184mpositiontaking,
			MAX(CASE WHEN cg.sporttype=184 THEN cg.apositiontaking ELSE 0 END) v184apositiontaking,

			MAX(CASE WHEN cg.sporttype=183 THEN cg.mpositiontaking ELSE 0 END) v183mpositiontaking,
			MAX(CASE WHEN cg.sporttype=183 THEN cg.apositiontaking ELSE 0 END) v183apositiontaking,

			MAX(CASE WHEN cg.sporttype=185 THEN cg.mpositiontaking ELSE 0 END) v185mpositiontaking,
			MAX(CASE WHEN cg.sporttype=185 THEN cg.apositiontaking ELSE 0 END) v185apositiontaking,
			
			MAX(CASE WHEN cg.sporttype=186 THEN cg.mpositiontaking ELSE 0 END) v186mpositiontaking,
			MAX(CASE WHEN cg.sporttype=186 THEN cg.apositiontaking ELSE 0 END) v186apositiontaking,
			ISNULL(cl.ClosedReason,0) AS ClosedReason			
		FROM																									   
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN CustSetting3rd AS cg WITH (NOLOCK) ON ci.custid = cg.custid	
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID	
		WHERE ci.MRecommend = @MRecommend AND ci.roleid=2 AND cg.sporttype in (180, 181,184,182, 183, 185, 186)
		GROUP BY
			ci.enabled, ci.closed, ci.DisableVirtualSports, ci.HideVirtualSports, ci.reject, ci.username, ci.custid,cl.ClosedReason
	) t 
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
END

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelVirtualSportsPositionTakingByMAg] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelVirtualSportsPositionTakingByMAg] TO [wsv_alpv] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelVirtualSportsPositionTakingByMAg] TO [vnteam] AS [dbo]