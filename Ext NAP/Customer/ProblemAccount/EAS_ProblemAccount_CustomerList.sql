/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_ProblemAccount_CustomerList]
	@FromDate			DATETIME,
	@ToDate				DATETIME,	
	@GroupName			VARCHAR(50) = '',
	@UplineUsername		NVARCHAR(50) = '',
	@SearchRoleId		TINYINT,
	@SearchUsername		NVARCHAR(50) = '',
	@ReviewStatusId		TINYINT = 0,
	@PageIndex			INT = 1,
	@PageSize			INT = 500,
	@TotalRows			INT = 0 OUTPUT
AS

/*
	Created: 20201009@Johnson
	DB: DBCUST/CustDB
	Task: Problem Accounts for EXT

	Revisions:
		- 20201009@Johnson: Initial SP [Redmine:#142957]
		- 20210426@Johnson: change source ProblemAccount to ProblemAccountClassification [redmine:#153059]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20220228@Johnson: add new category for good/bad robot[redmine:#167726]
		- 20220418@Johnson: Change datasource for problem account [redmine:#170692]
		- 20221017@Tacy: Hide Display for Credit Prolem Accounts (Group Betting, Robot User) [RedmineID: #178796]
		- 20241118@Tacy: New CC for SMA [Redmine: #212681]

	Parameter's Explanation:
		@GroupName: ext group
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
	
	DECLARE @UplineID INT
	CREATE TABLE #tempProblemAccount (custId INT, username NVARCHAR(50), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 NVARCHAR(50), numberOfDownline INT, createdDate DATETIME, 
									  isReviewed BIT, ClosedReason TINYINT, Locked TINYINT)
	
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

	DECLARE @tmpSuper TABLE (custid INT PRIMARY KEY)
	
	INSERT INTO @tmpSuper(custid)
	SELECT custid
	FROM dbo.Acc_CustGroup WITH(NOLOCK)
	WHERE GroupName = @GroupName
	
	IF @UplineUsername <> ''
	BEGIN
		SELECT @UplineID = custid 
		FROM custinfo WITH(NOLOCK)
		WHERE username = @UplineUsername
	END
	
	IF @SearchRoleId = 3
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
		FROM  dbo.CustomerClassSetting_Agent ca WITH (NOLOCK)
			INNER JOIN #tmpCategoryConfig t ON t.CategoryID=ca.CategoryID AND ca.CustomerClass=t.CustomerClass
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ca.custid = p.custid																				
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			INNER JOIN CustProductStatus ps WITH (NOLOCK) ON c.custid = ps.CustID
			LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
			LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON c.srecommend=cs.custid
		WHERE c.srecommend IN (SELECT custId 
								FROM @tmpSuper
								WHERE 1 = CASE WHEN (@UplineID IS NOT NULL AND custId= @UplineID) OR @UplineID IS NULL THEN 1 ELSE 0 END
								)
			AND (
					(cs.custid IS NOT NULL	AND t.HiddenSite NOT IN (2,3))	--DEPOSIT
				OR	(cs.custid IS NULL		AND t.HiddenSite NOT IN (1,3))	--CREDIT
				)
			AND ca.SportType=0
			AND c.roleid = 3
			AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			--AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			
		SELECT @TotalRows = @@ROWCOUNT

		;WITH CTE_PAdownlines AS (
			SELECT ci.mrecommend, COUNT(1) AS numberOfDownline
			FROM dbo.custInfo ci WITH (NOLOCK)
				INNER JOIN dbo.CustomerClassSetting_Agent ca WITH (NOLOCK) ON ca.custid=ci.custid AND ca.Sporttype=0
				INNER JOIN #tmpCategoryConfig tc ON tc.CategoryID=ca.CategoryID AND ca.CustomerClass=tc.CustomerClass
				INNER JOIN #tempProblemAccount t ON ci.mrecommend = t.custid 
				LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON ci.srecommend=cs.custid
			WHERE ci.roleID=2
				AND (
					(cs.custid IS NOT NULL	AND tc.HiddenSite NOT IN (2,3))		
				OR	(cs.custid IS NULL		AND tc.HiddenSite NOT IN (1,3))
				)			
			GROUP BY ci.mrecommend
		) 
		UPDATE t 
		SET t.numberOfDownline = pa.numberOfDownline
		FROM #tempProblemAccount t 			
			INNER JOIN CTE_PAdownlines pa ON pa.mrecommend=t.custId	
	END
	ELSE IF @SearchRoleId = 2 	
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked,0) Locked
		FROM  dbo.CustomerClassSetting_Agent ca WITH (NOLOCK)
			INNER JOIN #tmpCategoryConfig tc ON tc.CategoryID=ca.CategoryID AND ca.CustomerClass=tc.CustomerClass
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ca.custid = p.custid
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
			LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
			LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON c.srecommend=cs.custid
		WHERE 1 = CASE WHEN @UplineID IS NULL OR (@UplineID IS NOT NULL AND c.mrecommend = @UplineID) THEN 1 ELSE 0 END
			AND c.srecommend IN (SELECT custid FROM @tmpSuper)
			AND c.roleid = 2
			AND (
					(cs.custid IS NOT NULL	AND tc.HiddenSite NOT IN (2,3))		
				OR	(cs.custid IS NULL		AND tc.HiddenSite NOT IN (1,3))
				)
			AND ca.SportType=0
			AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			--AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			
		SELECT @TotalRows = @@ROWCOUNT

		UPDATE t 
		SET t.numberOfDownline = pa.numberOfDownline
		FROM #tempProblemAccount t 			
			CROSS APPLY (SELECT ci.recommend, COUNT(1) AS numberOfDownline
						FROM dbo.custInfo ci WITH (NOLOCK) 	
						LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON ci.srecommend=cs.custid
						WHERE ci.recommend = t.custid 
							AND ci.roleid = 1
							AND (
									(cs.custid IS NOT NULL	AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WITH(NOLOCK) WHERE HiddenSite NOT IN (2,3)))		
								OR	(cs.custid IS NULL		AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WITH(NOLOCK) WHERE HiddenSite NOT IN (1,3)))
								)
						GROUP BY ci.recommend) AS pa	
	END

	ELSE IF @SearchRoleId = 1
	BEGIN		
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason, Locked)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0) ClosedReason, ISNULL(ps.Locked, 0) Locked
		FROM  dbo.custinfo ci WITH (NOLOCK)
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ps.CustID = c.custid
			LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
			LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON ci.srecommend=cs.custid
		WHERE 1 = CASE WHEN @UplineID IS NULL OR (@UplineID IS NOT NULL AND c.recommend = @UplineID) THEN 1 ELSE 0 END
			AND c.srecommend IN (SELECT custid FROM @tmpSuper)
			AND c.roleid = 1
			AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			AND (
					(cs.custid IS NOT NULL	AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WITH(NOLOCK) WHERE HiddenSite NOT IN (2,3)))		
				OR	(cs.custid IS NULL		AND ci.CustomerClass IN (SELECT CustomerClass FROM #tmpCategoryConfig WITH(NOLOCK) WHERE HiddenSite NOT IN (1,3)))
				)
			--AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
		
		SELECT @TotalRows = @@ROWCOUNT
	END

	/* ===== Paging ===== */
	--@Status: 1: Open, 2:Suppended, 3: Closed, 4: Disabled
	SELECT custId, username, firstname, lastname, username2, ISNULL(numberOfDownline, 0) AS numberOfDownline, status, createdDate, isReviewed, ClosedReason, Locked
	FROM (
		SELECT t.custId, t.username, t.firstname, t.lastname, t.username2, t.numberOfDownline, t.ClosedReason,
			CASE WHEN ci.Enabled = 1 THEN CASE WHEN cs.closed = 1 THEN 3 WHEN cs.reject = 1 THEN 2 ELSE 1 END ELSE 4 END AS Status,
			t.createdDate, t.isReviewed, ROW_NUMBER() OVER (ORDER BY t.isReviewed ASC, t.createdDate DESC, t.username ASC) AS RowId, t.Locked
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
