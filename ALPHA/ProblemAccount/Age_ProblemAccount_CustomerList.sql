/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ProblemAccount_CustomerList]
	@FromDate			DATETIME,
	@ToDate				DATETIME,
	@CustId				INT,
	@SubAccId			INT = 0,
	@UplineUsername		VARCHAR(50) = '',
	@SearchRoleId		TINYINT,
	@SearchUsername		NVARCHAR(50) = '',
	@ReviewStatusId		TINYINT = 0,
	@PageIndex			INT = 1,
	@PageSize			INT = 5000,
	@TotalRows			INT = 0 OUTPUT
	
AS

/*
	Created: 20200210@Elodie
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20200210@Elodie: Initial SP [Redmine:#127446]
		- 20200306@Elodie: Allow view problem account for master and agent [Redmine:#129881]
		- 20210422@Johnson: get problem account from Custinfo.CustomerClass 8->13 [redmine:#153059]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20211014@Elodie: No paging [Redmine:#163177]
		- 20220228@Johnson: add new category for good/bad robot[redmine:#167726]
		- 20220418@Johnson: Change datasource for problem account [redmine:#170692]
		- 20221017@Tacy: Hide Display for Credit Prolem Accounts (Group Betting, Robot User) [RedmineID: #178796]
		- 20230630@Elodie: Enhance SP [Redmine:#190527]
		- 20240410@Kelvin: Alpha - Link WL Detail to My Watchlist [Redmine:#201733]
		- 20241118@Tacy: New CC for SMA [Redmine: #212681]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]
	Param's Explanation:
		@CustId: Customer login
		@SubAccId: SubAccount Id
		@UplineUsername: search downlines under @UplineUsername, not required
		@SearchRoleId:
			3: Master Agent
			2: Agent
			1: Member
		@SearchUsername: search username
		@ReviewStatusId:
			0: Not Reviewed
			1: Reviewed
			2: All
*/

BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #tempProblemAccount (custId INT, username NVARCHAR(50), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 NVARCHAR(50), numberOfDownline INT, createdDate DATETIME, 
									  isReviewed BIT, ClosedReason TINYINT, Locked TINYINT, IsExistedWatchList TINYINT)
	
	CREATE TABLE #tmpCategoryConfig (
			CategoryID		INT,
			CustomerClass	INT,
			HiddenSite		TINYINT
	)

	INSERT INTO #tmpCategoryConfig(CustomerClass, CategoryID, HiddenSite)
	SELECT c.CustomerClass
		,CategoryID = CASE c.CategoryID --temp mapping
							WHEN 32700 THEN 120100
							WHEN 32701 THEN 120200
							WHEN 32702 THEN 120300
							WHEN 32703 THEN 120400
							WHEN 32704 THEN 120500
							WHEN 32705 THEN 120600
							WHEN 32706 THEN 120800
							WHEN 32707 THEN 121100
							WHEN 32708 THEN 125100
							WHEN 32709 THEN 125200
							WHEN 32710 THEN 125300
							WHEN 32711 THEN 125400
							WHEN 32712 THEN 125500
							WHEN 32713 THEN 125600
							WHEN 32714 THEN 125800
							WHEN 32715 THEN 126100
							ELSE c.CategoryID
						END
		,c.HiddenSite
	FROM CategoryConfig c WITH (NOLOCK)

	DECLARE @RoleId TINYINT, @_CustId INT

	SELECT @RoleId = roleid FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @CustId
	SELECT @_CustId = @CustId

	IF @SearchRoleId = 3 AND @RoleId = 4 --Super view master
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked, 0) Locked
		FROM  dbo.CustomerClassSetting_Agent ca WITH (NOLOCK)
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ca.custid = p.custid
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON ca.CustId = c.CustId
			INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
			LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
			INNER JOIN #tmpCategoryConfig t ON t.CategoryID=ca.CategoryID AND ca.CustomerClass=t.CustomerClass
											AND t.HiddenSite NOT IN (1,3)
		WHERE c.srecommend = @_CustId 
			AND c.roleid = 3
			AND ca.SportType=0
			AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			--AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
		
		SELECT @TotalRows = @@ROWCOUNT

		;WITH CTE_PAdownlines AS (
			SELECT ci.mrecommend, COUNT(1) AS numberOfDownline
			FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.CustomerClassSetting_Agent ca WITH (NOLOCK) ON ca.custid=ci.custid AND ca.Sporttype=0
			INNER JOIN #tempProblemAccount t ON ci.mrecommend = t.custid 
			INNER JOIN #tmpCategoryConfig tc ON tc.CategoryID=ca.CategoryID AND ca.CustomerClass=tc.CustomerClass
											AND tc.HiddenSite NOT IN (1,3)
			WHERE ci.roleID=2
			GROUP BY ci.mrecommend
		) 
		UPDATE t 
		SET t.numberOfDownline = pa.numberOfDownline
		FROM #tempProblemAccount t 			
			INNER JOIN CTE_PAdownlines pa ON pa.mrecommend=t.custId		
	END
	ELSE
	BEGIN
		-- get @UplineId if @UplineUsername isn't empty
		DECLARE @UplineId INT
		IF @UplineUsername <> '' AND @RoleId > @SearchRoleId + 1
		BEGIN
			SELECT @UplineId = custid FROM dbo.Customer WITH (NOLOCK)
			WHERE username = @UplineUsername AND roleid = @SearchRoleId + 1 
				AND CASE WHEN @RoleId = 4 THEN srecommend 
						WHEN @RoleId = 3 THEN mrecommend 
						WHEN @RoleId = 2 THEN recommend END = @CustId
		END
		
		IF @SearchRoleId = 2 
		BEGIN
			IF @RoleId = 3 --Master view agent
			BEGIN
				INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
				SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
				FROM dbo.CustomerClassSetting_Agent ca WITH (NOLOCK)
					INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ca.custid = p.custid
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON ca.CustId = c.CustId
					INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
					LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
					INNER JOIN #tmpCategoryConfig t ON t.CategoryID=ca.CategoryID AND ca.CustomerClass=t.CustomerClass
													AND t.HiddenSite NOT IN (1,3)
				WHERE c.mrecommend = @_CustId
					AND c.roleid = 2
					AND ca.SportType=0
					AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
					AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
					--AND p.ReasonId IS NOT NULL
					AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			END
			ELSE IF @RoleId = 4 AND @UplineUsername = '' --Super view agent
			BEGIN
				INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
				SELECT c.custid, c.username, c.firstname, c.lastname, c.username2,  p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
				FROM  dbo.CustomerClassSetting_Agent ca WITH (NOLOCK)
					INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ca.custid = p.custid					
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
					INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
					LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
					CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.mrecommend) AS u
					INNER JOIN #tmpCategoryConfig t ON t.CategoryID=ca.CategoryID AND ca.CustomerClass=t.CustomerClass
													AND t.HiddenSite NOT IN (1,3)
				WHERE c.roleid = 2
					AND ca.SportType=0
					AND c.srecommend = @_CustId
					AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
					AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
					--AND p.ReasonId IS NOT NULL
					AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'	
			END	
			ELSE IF @RoleId = 4 AND @UplineUsername <> '' AND @UplineId IS NOT NULL--Super view agent
			BEGIN
				INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
				SELECT c.custid, c.username, c.firstname, c.lastname, c.username2,  p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
				FROM  dbo.CustomerClassSetting_Agent ca WITH (NOLOCK)
					INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ca.custid = p.custid					
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
					INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
					LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
					CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.mrecommend) AS u
					INNER JOIN #tmpCategoryConfig t ON t.CategoryID=ca.CategoryID AND ca.CustomerClass=t.CustomerClass
													AND t.HiddenSite NOT IN (1,3)
				WHERE c.roleid = 2
					AND ca.SportType=0
					AND c.mrecommend = @UplineId
					AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
					AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
					--AND p.ReasonId IS NOT NULL
					AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'	
			END	
			SELECT @TotalRows = @@ROWCOUNT

			UPDATE t 
			SET t.numberOfDownline = pa.numberOfDownline
			FROM #tempProblemAccount t 			
				CROSS APPLY (SELECT ci.recommend, COUNT(1) AS numberOfDownline
							FROM dbo.custInfo ci WITH (NOLOCK) 		
							WHERE ci.recommend = t.custid 
								AND ci.roleid = 1
								--AND (pa.ReasonId IS NOT NULL OR pa.IsAbnormalMember = 1)
								AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WHERE HiddenSite NOT IN (1,3))
							GROUP BY ci.recommend) AS pa	
		END
		ELSE IF @SearchRoleId = 1
		BEGIN				
			IF @RoleId = 2 --Agent view member
			BEGIN
				INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked, IsExistedWatchList)
				SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
					, ISNULL(wl.IsExistedWatchList,0) IsExistedWatchList
				FROM dbo.custinfo ci WITH (NOLOCK)
					INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid										
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
					INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
					LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
					OUTER APPLY (SELECT 1 AS IsExistedWatchList FROM WLMonitored_Player wl WITH (NOLOCK) WHERE wl.CustID = c.custid AND wl.Sporttype = 0) AS wl
				WHERE c.recommend = @_CustId
					AND c.roleid = 1
					AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WHERE HiddenSite NOT IN (1,3))
					AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
					AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
					--AND p.ReasonId IS NOT NULL
					AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			END
			ELSE 
			BEGIN
				IF @RoleId = 3 AND @UplineUsername = '' --Master view member
				BEGIN
					INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
					SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
					FROM  dbo.custinfo ci WITH (NOLOCK)
						INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid															
						INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
						INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
						LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
						--CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.recommend) AS u
					WHERE c.roleid = 1
						AND c.mrecommend = @_CustId
						AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
						AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WHERE HiddenSite NOT IN (1,3))
						AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
						--AND (p.ReasonId IS NOT NULL OR p.IsAbnormalMember = 1)
						AND  c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				END
				ELSE IF @RoleId = 4 AND @UplineUsername = '' --Super view member
				BEGIN
					INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
					SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
					FROM  dbo.custinfo ci WITH (NOLOCK)
						INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid															
						INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
						INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
						LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
						--CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.recommend) AS u
					WHERE c.roleid = 1
						AND c.srecommend = @_CustId
						AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
						AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WHERE HiddenSite NOT IN (1,3))
						AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
						--AND (p.ReasonId IS NOT NULL OR p.IsAbnormalMember = 1)
						AND  c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				END	
				ELSE IF @UplineUsername <> '' AND @UplineId IS NOT NULL
				BEGIN
					INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
					SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
					FROM  dbo.custinfo ci WITH (NOLOCK)
						INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid															
						INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
						INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
						LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
						CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.recommend) AS u
					WHERE c.roleid = 1
						AND c.recommend = @UplineId
						AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
						AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WHERE HiddenSite NOT IN (1,3))
						AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
						--AND (p.ReasonId IS NOT NULL OR p.IsAbnormalMember = 1)
						AND  c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				END
			END
			SELECT @TotalRows = @@ROWCOUNT
		END
	END

	/* ===== Paging ===== */
	--@Status: 1: Open, 2:Suppended, 3: Closed, 4: Disabled
	SELECT custId, username, firstname, lastname, username2, ISNULL(numberOfDownline, 0) AS numberOfDownline, status, createdDate, isReviewed, ClosedReason, Locked, IsExistedWatchList, AgentID 
	FROM (
		SELECT t.custId, t.username, t.firstname, t.lastname, t.username2, t.numberOfDownline, t.ClosedReason,
			CASE WHEN ci.Enabled = 1 THEN CASE WHEN cs.closed = 1 THEN 3 WHEN cs.reject = 1 THEN 2 ELSE 1 END ELSE 4 END AS Status,
			t.createdDate, t.isReviewed, ROW_NUMBER() OVER (ORDER BY t.isReviewed, t.username) AS RowId, Locked, IsExistedWatchList,
			CASE WHEN ci.roleid = 1 AND ci.recommend IN (-3,-4) THEN ci.recommend ELSE 0 END AS AgentID
		FROM #tempProblemAccount t
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = t.custId
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cs
	) AS Result
	WHERE RowId BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageSize * @PageIndex)

	DROP TABLE #tempProblemAccount, #tmpCategoryConfig
END