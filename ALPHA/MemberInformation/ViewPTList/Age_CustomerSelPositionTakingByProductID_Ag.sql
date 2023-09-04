/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView,bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelPositionTakingByProductID_Ag]
(
	@ProductID	TINYINT,
	@Recommend	INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 100,
	@TotalPages	INT = 0 OUTPUT,
	@SettingStatus TINYINT = 0
)
AS
/*
    Created: 20151028@Billy
	Task: Select Member PT List for given Product ID [Redmine: #46099]
	DB: DBCUST/CustDB

	Revisions:
		- 20160322@Billy: Fix bug return multiple PT value - [Redmine: #54529]
		- 20170627@Winnie: Apply color for closed account [RedmineID: #74494]
		- 20200321@Tiara: Handle dummy product for Sexy Gaming/Allbet/SA Gaming [Redmine: #130678]
		- 20200406@Elodie: Add BBIN Product [Redmine: #131363]
		- 20200403@Elodie: Add Table Games Product [Redmine: #129440]
		- 20200615@Elodie: Implement new setting type 18 [Redmine: #135363]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20221027@Elodie: Filter by setting status [Redmine: #179335]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230327@Tacy: Alpha - Enhance to show First/Last name in reports [RedmineID: #185313]
		- 20230728@Helios: Customer Setting - Simplify Live Casino Customer Setting [RedmineID: #189389]

	Param's Explanation:
	• @Recommend: Agent ID
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @SportType INT, @BetType INT
	CREATE TABLE #SportBettype
	(	SportType INT, 
		BetType INT, 
		IsLive BIT,
		RealProductID TINYINT
	)		


	INSERT INTO #SportBettype (SportType, BetType, IsLive, RealProductID)
	SELECT SportType, BetType, IsLive , RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus)
	--WHERE RealProductId = @ProductID
	UNION ALL 
	SELECT SportType, BetType, IsLive , RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus)
	--WHERE RealProductId = @ProductID

	SELECT  @TotalPages = COUNT(ci.custid),
            @TotalPages = @TotalPages / @PageSize 
                        + CASE WHEN @TotalPages % @PageSize > 0 THEN 1 ELSE 0 END
	FROM    custInfo AS ci WITH(NOLOCK)		
	WHERE   ci.Recommend = @Recommend 
      AND   ci.roleid = 1

	UPDATE sb	
	SET sb.RealProductID = m.RealProductId
	FROM #SportBettype sb
	INNER JOIN SportBettypeSettingMatrix m WITH (NOLOCK) ON sb.SportType = m.SportType AND sb.BetType = m.BetType AND sb.RealProductID = m.ProductID AND m.isLicensee = 0 AND m.Site = 'All'
	WHERE m.ProductID IS NOT NULL

	DELETE FROM #SportBettype WHERE ISNULL(RealProductID , 0) <> @ProductID 

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
				c.firstname,
				c.lastname,
			    ci.custid,
				ISNULL(cl.ClosedReason,0) AS ClosedReason,
				ISNULL(ps.Locked,0) Locked
		FROM custInfo AS ci WITH(NOLOCK)
			INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ci.custid
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS closed
							, CASE WHEN SuspendInfo > 0 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS ps
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE   ci.Recommend = @Recommend 
          AND   ci.roleid = 1
		GROUP BY    ci.enabled, ps.closed, ps.reject, ci.username, c.firstname, c.lastname, ci.custid,cl.ClosedReason,ps.Locked
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
		--AND RealProductID = @ProductID
	) pt
	WHERE	RowNumber >= (@PageIndex - 1) * @PageSize + 1 AND RowNumber <= @PageIndex * @PageSize
	ORDER BY RowNumber, SportType, islive, BetType, roleid
END	
GO