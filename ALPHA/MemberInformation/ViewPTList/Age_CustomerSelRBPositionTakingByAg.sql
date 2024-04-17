/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelRBPositionTakingByAg]
(
	@Recommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
	Created: 20110311@Lukas
	Date: 20110311
	Task : Select Racebook for PT List from custsetting3rd
	DB: DBCUST.CustDB
	Original: DB052.bodb02.dbo.Age_CustomerSelPositionTakingByAg

	Revisions: 
		- 20111128@Lukas: Add paging
		- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
		- 20170622@Winnie: Color for closed accounts  [RedmineID: #74494]
	Param's Explanation:
	• @Recommend: Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM 
		custinfo AS ci WITH (NOLOCK)		
	WHERE 
		ci.Recommend = @Recommend AND ci.roleid=1

	SELECT *
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY CASE WHEN ISNULL(ci.enabled,0) = 0 THEN 3 
											WHEN ISNULL(ci.closed,0) = 1 THEN 2 
											WHEN ISNULL(ci.reject,0) = 1 THEN 1 
											ELSE 0 
										END, ci.username) AS RowNumber,
			ci.closed, ci.enabled, 
			ISNULL(ci.reject,0) AS suspended,
			ci.username, 
			ci.custid,
			
			-- Horse
			MAX(CASE WHEN cs3.bettype = 31 AND cs3.sporttype=151 THEN cs3.spositiontaking ELSE 0 END) v151spositiontaking_31,
			MAX(CASE WHEN cs3.bettype = 32 AND cs3.sporttype=151 THEN cs3.spositiontaking ELSE 0 END) v151spositiontaking_32,
			MAX(CASE WHEN cs3.bettype = 41 AND cs3.sporttype=151 THEN cs3.spositiontaking ELSE 0 END) v151spositiontaking_41,
			MAX(CASE WHEN cs3.bettype = 42 AND cs3.sporttype=151 THEN cs3.spositiontaking ELSE 0 END) v151spositiontaking_42,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=151 THEN cs3.spositiontaking ELSE 0 END) v151spositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=151 THEN cs3.spositiontaking ELSE 0 END) v151spositiontaking_52,
			MAX(CASE WHEN cs3.bettype = 41 AND cs3.sporttype=152 THEN cs3.spositiontaking ELSE 0 END) v152spositiontaking_41,
			MAX(CASE WHEN cs3.bettype = 42 AND cs3.sporttype=152 THEN cs3.spositiontaking ELSE 0 END) v152spositiontaking_42,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=152 THEN cs3.spositiontaking ELSE 0 END) v152spositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=152 THEN cs3.spositiontaking ELSE 0 END) v152spositiontaking_52,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=153 THEN cs3.spositiontaking ELSE 0 END) v153spositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=153 THEN cs3.spositiontaking ELSE 0 END) v153spositiontaking_52,

			MAX(CASE WHEN cs3.bettype = 31 AND cs3.sporttype=151 THEN cs3.apositiontaking ELSE 0 END) v151apositiontaking_31,
			MAX(CASE WHEN cs3.bettype = 32 AND cs3.sporttype=151 THEN cs3.apositiontaking ELSE 0 END) v151apositiontaking_32,
			MAX(CASE WHEN cs3.bettype = 41 AND cs3.sporttype=151 THEN cs3.apositiontaking ELSE 0 END) v151apositiontaking_41,
			MAX(CASE WHEN cs3.bettype = 42 AND cs3.sporttype=151 THEN cs3.apositiontaking ELSE 0 END) v151apositiontaking_42,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=151 THEN cs3.apositiontaking ELSE 0 END) v151apositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=151 THEN cs3.apositiontaking ELSE 0 END) v151apositiontaking_52,
			MAX(CASE WHEN cs3.bettype = 41 AND cs3.sporttype=152 THEN cs3.apositiontaking ELSE 0 END) v152apositiontaking_41,
			MAX(CASE WHEN cs3.bettype = 42 AND cs3.sporttype=152 THEN cs3.apositiontaking ELSE 0 END) v152apositiontaking_42,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=152 THEN cs3.apositiontaking ELSE 0 END) v152apositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=152 THEN cs3.apositiontaking ELSE 0 END) v152apositiontaking_52,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=153 THEN cs3.apositiontaking ELSE 0 END) v153apositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=153 THEN cs3.apositiontaking ELSE 0 END) v153apositiontaking_52,

			MAX(CASE WHEN cs3.bettype = 31 AND cs3.sporttype=151 THEN cs3.mpositiontaking ELSE 0 END) v151mpositiontaking_31,
			MAX(CASE WHEN cs3.bettype = 32 AND cs3.sporttype=151 THEN cs3.mpositiontaking ELSE 0 END) v151mpositiontaking_32,
			MAX(CASE WHEN cs3.bettype = 41 AND cs3.sporttype=151 THEN cs3.mpositiontaking ELSE 0 END) v151mpositiontaking_41,
			MAX(CASE WHEN cs3.bettype = 42 AND cs3.sporttype=151 THEN cs3.mpositiontaking ELSE 0 END) v151mpositiontaking_42,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=151 THEN cs3.mpositiontaking ELSE 0 END) v151mpositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=151 THEN cs3.mpositiontaking ELSE 0 END) v151mpositiontaking_52,
			MAX(CASE WHEN cs3.bettype = 41 AND cs3.sporttype=152 THEN cs3.mpositiontaking ELSE 0 END) v152mpositiontaking_41,
			MAX(CASE WHEN cs3.bettype = 42 AND cs3.sporttype=152 THEN cs3.mpositiontaking ELSE 0 END) v152mpositiontaking_42,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=152 THEN cs3.mpositiontaking ELSE 0 END) v152mpositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=152 THEN cs3.mpositiontaking ELSE 0 END) v152mpositiontaking_52,
			MAX(CASE WHEN cs3.bettype = 51 AND cs3.sporttype=153 THEN cs3.mpositiontaking ELSE 0 END) v153mpositiontaking_51,
			MAX(CASE WHEN cs3.bettype = 52 AND cs3.sporttype=153 THEN cs3.mpositiontaking ELSE 0 END) v153mpositiontaking_52,
			ISNULL(cl.ClosedReason,0) AS ClosedReason	
		FROM																									   
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN CustSetting3rd AS cs3 WITH (NOLOCK) ON ci.custid = cs3.custid
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON ci.custid=cl.CustID	
		WHERE ci.Recommend = @Recommend AND ci.roleid=1 AND cs3.sporttype BETWEEN 151 AND 153
		GROUP BY
			ci.enabled, ci.closed, ci.reject, ci.username, ci.custid,cl.ClosedReason
	) t 
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
	
END

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelRBPositionTakingByAg] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelRBPositionTakingByAg] TO [wsv_alpv] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelRBPositionTakingByAg] TO [vnteam] AS [dbo]