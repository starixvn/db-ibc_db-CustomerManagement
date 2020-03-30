/*<info serverAlias="DBCust-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/

/****** Object:  Stored Procedure dbo.Age_CustomerSelPositionTakingByProductID_SAg    Script Date: 10/29/2015 9:34:05 AM ******/

ALTER PROCEDURE [dbo].[Age_CustomerSelPositionTakingByProductID_SAg]
(
	@ProductID	TINYINT,
	@SRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 100,
	@TotalPages	INT = 0 OUTPUT
)
AS
/*
    Created: 20151028@Billy
	Task: Select Master Agent PT List for given Product ID [Redmine: #46099]
	DB: DBCUST/CustDB

	Revisions:
		- 20170627@Winnie: Apply color for closed account [RedmineID: #74494]
		- 20200321@Tiara: Handle dummy product for Sexy Gaming/Allbet/SA Gaming [Redmine: #130678]
	Param's Explanation:
	• @SRecommend: Super Agent ID
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @SportType INT
	CREATE TABLE #SportBettype
	(	SportType INT, 
		BetType INT, 
		IsLive BIT
	)		
	IF @ProductID IN (39,45,21) --Handle dummy product 41
	BEGIN
		SELECT DISTINCT @SportType = S.SportType
		FROM DBAGE.bodb02.dbo.SportBettypeMatrix S WITH(NOLOCK)
		WHERE ProductID = @ProductID

		INSERT INTO #SportBettype (SportType, BetType, IsLive)
		SELECT	SportType, BetType, IsLive
		FROM	ProductSettingDetail WITH(NOLOCK)
		WHERE	ProductID = 41 AND SportType = @SportType
		AND		SettingType = 1	-- PT
	END
	ELSE
	BEGIN
		INSERT INTO #SportBettype (SportType, BetType, IsLive)
		SELECT	SportType, BetType, IsLive
		FROM	ProductSettingDetail WITH(NOLOCK)
		WHERE	ProductID = @ProductID
		AND		SettingType = 1	-- PT
	END
	SELECT  @TotalPages = COUNT(ci.custid),
            @TotalPages = @TotalPages / @PageSize 
                        + CASE WHEN @TotalPages % @PageSize > 0 THEN 1 ELSE 0 END
	FROM    custInfo AS ci WITH(NOLOCK)		
	WHERE   ci.SRecommend = @SRecommend 
      AND   ci.roleid = 3

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
			    ci.custid,
				ISNULL(cl.ClosedReason,0) AS ClosedReason
		FROM        custInfo                AS ci WITH(NOLOCK)
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE   ci.SRecommend = @SRecommend 
          AND   ci.roleid = 3
		GROUP BY    ci.enabled, ci.closed, ci.reject, ci.username, ci.custid,cl.ClosedReason
	) info
	CROSS APPLY (
		SELECT 4 AS roleid
	) r
	CROSS APPLY (
		SELECT		cpts3.SportType,
					cpts3.BetType,
					cpts3.IsLive,
					CASE WHEN roleid = 4	THEN cpts3.SuperPT 
											ELSE NULL 
											END AS positiontaking
		FROM		CustPTSetting3rd_Agent  AS cpts3 WITH(NOLOCK)
		INNER JOIN	#SportBettype AS sbt
				ON	cpts3.SportType = sbt.SportType
				AND	cpts3.BetType = sbt.BetType
				AND	cpts3.IsLive = sbt.IsLive
		WHERE	cpts3.CustID = info.custid
	) pt
	WHERE RowNumber >= (@PageIndex - 1) * @PageSize + 1 AND RowNumber <= @PageIndex * @PageSize
	ORDER BY RowNumber, SportType, isLive, BetType, roleid
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_SAg] TO [vnteam]
GO 
 GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelPositionTakingByProductID_SAg] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_SAg] TO [Dot_Admin]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_SAg] TO [bodbAdminNet]
GO 
 GRANT EXECUTE ON [dbo].[Age_CustomerSelPositionTakingByProductID_SAg] TO [bodbDownlineNet]
GO 
