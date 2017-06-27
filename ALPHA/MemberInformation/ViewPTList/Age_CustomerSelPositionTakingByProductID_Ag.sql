SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelPositionTakingByProductID_Ag]
(
	@ProductID	TINYINT,
	@Recommend	INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 100,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
    Created: 20151028@Billy
	Task: Select Member PT List for given Product ID [Redmine: #46099]
	DB: DBCUST/CustDB

	Revisions:
		- 20160322@Billy: Fix bug return multiple PT value - [Redmine: #54529]

	Param's Explanation:
	• @Recommend: Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT	SportType, BetType, IsLive
	INTO	#SportBettype
	FROM	ProductSettingDetail WITH(NOLOCK)
	WHERE	ProductID = @ProductID
	AND		SettingType = 1	-- PT

	SELECT  @TotalPages = COUNT(ci.custid),
            @TotalPages = @TotalPages / @PageSize 
                        + CASE WHEN @TotalPages % @PageSize > 0 THEN 1 ELSE 0 END
	FROM    custInfo AS ci WITH(NOLOCK)		
	WHERE   ci.Recommend = @Recommend 
      AND   ci.roleid = 1

	SELECT	*
	FROM (
		SELECT	ROW_NUMBER() OVER(ORDER BY CASE WHEN ISNULL(ci.enabled, 0) = 0 THEN 3 
											    WHEN ISNULL(ci.closed,  0) = 1 THEN 2 
											    WHEN ISNULL(ci.reject,  0) = 1 THEN 1 
											                                   ELSE 0 
										        END, 
                                           ci.username) AS RowNumber,
			    ci.closed, 
                ci.enabled, 
			    ISNULL(ci.reject,0) AS suspended,
			    ci.username, 
			    ci.custid
		FROM        custInfo                AS ci WITH(NOLOCK)
		WHERE   ci.Recommend = @Recommend 
          AND   ci.roleid = 1
		GROUP BY    ci.enabled, ci.closed, ci.reject, ci.username, ci.custid
	) info
	CROSS APPLY (
		SELECT 2 AS roleid
		UNION ALL
		SELECT 3 AS roleid
		UNION ALL 
		SELECT 4 AS roleid
	) r
	CROSS APPLY (
		SELECT		cptgs3.SportType,
					cptgs3.BetType,
					cptgs3.IsLive,
					CASE WHEN roleid = 2 THEN cptgs3.AgentPT
						  WHEN roleid = 3 THEN cptgs3.MasterPT
						  WHEN roleid = 4 THEN cptgs3.SuperPT
										  ELSE NULL
				   END  AS positiontaking
		FROM		CustSettingMode3rd				AS csm3 WITH(NOLOCK)
		INNER JOIN	CustPTGroupSetting3rd_Member	AS cptgs3 WITH(NOLOCK)
				ON	cptgs3.AgentID = @Recommend
				AND	csm3.IsGrouped = 1
		INNER JOIN	#SportBettype AS sbt
				ON	cptgs3.SportType = sbt.SportType
				AND	cptgs3.BetType = sbt.BetType
				AND	cptgs3.IsLive = sbt.IsLive
		WHERE csm3.CustID = info.custid
		
		UNION ALL
		
		SELECT	sbt.SportType
			,	sbt.BetType
			,	sbt.IsLive
			,	CASE	WHEN roleid = 2 THEN cpts3.AgentPT
						WHEN roleid = 3 THEN cpts3.MasterPT
						WHEN roleid = 4 THEN cpts3.SuperPT
						ELSE NULL
				END AS positiontaking
		FROM		#SportBettype AS sbt
		INNER JOIN	CustPTSetting3rd_Member AS cpts3 WITH(NOLOCK)
				ON	sbt.SportType = cpts3.SportType
				AND	sbt.BetType = cpts3.BetType
				AND	sbt.IsLive = cpts3.IsLive
		INNER JOIN	CustSettingMode3rd csm3 WITH(NOLOCK)
				ON 	csm3.CustID = cpts3.CustID
				AND	csm3.IsGrouped = 0
		WHERE	csm3.CustID = info.custid
	) pt
	WHERE	RowNumber >= (@PageIndex - 1) * @PageSize + 1 AND RowNumber <= @PageIndex * @PageSize
	ORDER BY RowNumber, SportType, islive, BetType, roleid
END	
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_Ag] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelPositionTakingByProductID_Ag] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_Ag] TO [Dot_Admin]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_Ag] TO [bodbAdminNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_Ag] TO [bodbDownlineNet]
GO 
