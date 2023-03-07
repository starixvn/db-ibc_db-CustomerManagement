/*<info serverAlias="DBCust-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_CustomerSelPositionTakingByProductID_MAg]
(
	@ProductID	TINYINT,
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 100,
	@TotalPages	INT = 0 OUTPUT,
	@SettingStatus TINYINT = 0
)
AS
/*
    Created: 20151028@Billy
	Task: Select Agent PT List for given Product ID [Redmine: #46099]
	DB: DBCUST/CustDB

	Revisions:
		- 20170627@Winnie: Apply color for closed account [RedmineID: #74494]
		- 20200321@Tiara: Handle dummy product for Sexy Gaming/Allbet/SA Gaming [Redmine: #130678]
		- 20200406@Elodie: Add BBIN Product [Redmine: #131363]
		- 20200403@Elodie: Add Table Games Product [Redmine: #129440]
		- 20200615@Elodie: Implement new setting type 18 [Redmine: #135363]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20221027@Elodie: Filter by setting status [Redmine: #179335]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]

	Param's Explanation:
	• @MRecommend: Master Agent ID
*/
BEGIN

	SET NOCOUNT ON
	DECLARE @SportType INT, @BetType INT
	CREATE TABLE #SportBettype
	(	SportType INT, 
		BetType INT, 
		IsLive BIT
	)		

	INSERT INTO #SportBettype (SportType, BetType, IsLive)
	SELECT SportType, BetType, IsLive 
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus)
	WHERE RealProductId = @ProductID
	UNION ALL 
	SELECT SportType, BetType, IsLive 
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus)
	WHERE RealProductId = @ProductID

	SELECT  @TotalPages = COUNT(ci.custid),
            @TotalPages = @TotalPages / @PageSize 
                        + CASE WHEN @TotalPages % @PageSize > 0 THEN 1 ELSE 0 END
	FROM    custInfo AS ci WITH(NOLOCK)		
	WHERE   ci.MRecommend = @MRecommend 
      AND   ci.roleid = 2

	SELECT	*
	FROM (
		SELECT	ROW_NUMBER() OVER(ORDER BY CASE WHEN ISNULL(ci.enabled, 0) = 0 THEN 3 
											    WHEN ISNULL(ps.closed,  0) = 1 THEN 2 
											    WHEN ISNULL(ps.reject,  0) = 1 THEN 1 
											                                   ELSE 0 
										        END, 
                                           ci.username) AS RowNumber,
			    ps.closed, 
                ci.enabled, 
			    ISNULL(ps.reject,0) AS suspended,
			    ci.username, 
			    ci.custid,
				ISNULL(cl.ClosedReason,0) AS ClosedReason,
				ps.Locked
		FROM custInfo AS ci WITH(NOLOCK)
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS closed
							, CASE WHEN SuspendInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS ps
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE   ci.MRecommend = @MRecommend 
          AND   ci.roleid = 2
		GROUP BY    ci.enabled, ps.closed, ps.reject, ci.username, ci.custid,cl.ClosedReason, ps.Locked
	) info
	CROSS APPLY (
		SELECT 2 AS roleid
		UNION ALL
		SELECT 3 AS roleid
	) r
	CROSS APPLY (
		SELECT		cpts3.SportType,
					cpts3.BetType,
					cpts3.IsLive,
					CASE WHEN roleid = 2	THEN cpts3.AgentPT
						 WHEN roleid = 3	THEN cpts3.MasterPT
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