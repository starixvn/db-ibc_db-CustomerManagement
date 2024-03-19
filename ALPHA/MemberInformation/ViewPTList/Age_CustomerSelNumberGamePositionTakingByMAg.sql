/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelNumberGamePositionTakingByMAg]
(
	@MRecommend INT,
	@PageIndex	INT = 1,
	@PageSize	INT = 10000,
	@TotalPages	INT = 0 OUTPUT
)
AS

/*
	Created: 20100904@Kiwi
	Task : Select Number Game for PT List from custsetting3rd
	DB: DBCUST.CustDB

	Revisions:
		- 20110801@Sophia: Add bettype 88,89,90
		- 20111128@Lukas: Add paging
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20170622@Winnie: Color for closed accounts  [RedmineID: #74494]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20230327@Tacy: Alpha - Enhance to show First/Last name in reports [RedmineID: #185313]

	Param's Explanation:
	• @MRecommend: Master Agent ID
*/
BEGIN

	SET NOCOUNT ON

	SELECT 
		@TotalPages = COUNT(ci.custid),@TotalPages = @TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM custinfo AS ci WITH (NOLOCK)
	WHERE ci.MRecommend = @MRecommend AND ci.roleid = 2 

	SELECT * 
	FROM 
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY CASE WHEN ISNULL(ci.enabled, 0) = 0 THEN 3 
											WHEN ISNULL(ps.closed, 0) = 1 THEN 2 
											WHEN ISNULL(ps.reject, 0) = 1 THEN 1 
											ELSE 0 
										END, ci.username) AS RowNumber,
			ps.closed, ci.enabled, 
			ISNULL(ps.reject, 0) suspended,
			ci.username, 
			c.firstname,
			c.lastname,
			ci.custid, 
				
			--Deadball NumberGame
			MAX(CASE WHEN cs3rd.bettype = 81 AND cs3rd.sporttype=161 THEN cs3rd.apositiontaking ELSE 0 END) v161apositiontaking_81,
			MAX(CASE WHEN cs3rd.bettype = 83 AND cs3rd.sporttype=161 THEN cs3rd.apositiontaking ELSE 0 END) v161apositiontaking_83,
			MAX(CASE WHEN cs3rd.bettype = 85 AND cs3rd.sporttype=161 THEN cs3rd.apositiontaking ELSE 0 END) v161apositiontaking_85,
			MAX(CASE WHEN cs3rd.bettype = 86 AND cs3rd.sporttype=161 THEN cs3rd.apositiontaking ELSE 0 END) v161apositiontaking_86,
			MAX(CASE WHEN cs3rd.bettype = 88 AND cs3rd.sporttype=161 THEN cs3rd.apositiontaking ELSE 0 END) v161apositiontaking_88,
				
			MAX(CASE WHEN cs3rd.bettype = 81 AND cs3rd.sporttype=161 THEN cs3rd.mpositiontaking ELSE 0 END) v161mpositiontaking_81,
			MAX(CASE WHEN cs3rd.bettype = 83 AND cs3rd.sporttype=161 THEN cs3rd.mpositiontaking ELSE 0 END) v161mpositiontaking_83,	
			MAX(CASE WHEN cs3rd.bettype = 85 AND cs3rd.sporttype=161 THEN cs3rd.mpositiontaking ELSE 0 END) v161mpositiontaking_85,
			MAX(CASE WHEN cs3rd.bettype = 86 AND cs3rd.sporttype=161 THEN cs3rd.mpositiontaking ELSE 0 END) v161mpositiontaking_86,	
			MAX(CASE WHEN cs3rd.bettype = 88 AND cs3rd.sporttype=161 THEN cs3rd.mpositiontaking ELSE 0 END) v161mpositiontaking_88,	
			
			--Deadball NumberGame
			MAX(CASE WHEN cs3rd.bettype = 85 AND cs3rd.sporttype=161 THEN cs3rd.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_85,
			MAX(CASE WHEN cs3rd.bettype = 86 AND cs3rd.sporttype=161 THEN cs3rd.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_86,
			MAX(CASE WHEN cs3rd.bettype = 87 AND cs3rd.sporttype=161 THEN cs3rd.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_87,
			MAX(CASE WHEN cs3rd.bettype = 89 AND cs3rd.sporttype=161 THEN cs3rd.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_89,
			MAX(CASE WHEN cs3rd.bettype = 90 AND cs3rd.sporttype=161 THEN cs3rd.alivepositiontaking ELSE 0 END) AS v161alivepositiontaking_90,

			MAX(CASE WHEN cs3rd.bettype = 85 AND cs3rd.sporttype=161 THEN cs3rd.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_85,
			MAX(CASE WHEN cs3rd.bettype = 86 AND cs3rd.sporttype=161 THEN cs3rd.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_86,
			MAX(CASE WHEN cs3rd.bettype = 87 AND cs3rd.sporttype=161 THEN cs3rd.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_87,
			MAX(CASE WHEN cs3rd.bettype = 89 AND cs3rd.sporttype=161 THEN cs3rd.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_89,
			MAX(CASE WHEN cs3rd.bettype = 90 AND cs3rd.sporttype=161 THEN cs3rd.mlivepositiontaking ELSE 0 END) AS v161mlivepositiontaking_90,
			ISNULL(cl.ClosedReason,0) AS ClosedReason,
			ISNULL(ps.Locked,0) Locked
		FROM 
			custinfo AS ci WITH (NOLOCK)
			INNER JOIN Customer c WITH (NOLOCK) ON c.custid=ci.custid
			INNER JOIN CustSetting3rd AS cs3rd WITH (NOLOCK) ON ci.custid = cs3rd.custid 
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS ps
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON ci.custid=cl.CustID
		WHERE ci.MRecommend = @MRecommend AND ci.roleid=2 
		GROUP BY
			ci.enabled,
			ps.closed,
			ps.reject, 	
			ci.username, 
			c.firstname, 
			c.lastname, 
			ci.custid,
			cl.ClosedReason,
			ps.Locked				
	) t
	WHERE RowNumber >= (@PageIndex-1)*@PageSize + 1 AND RowNumber <= @PageIndex*@PageSize
END
GO
