/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet" isFunction="0" isNested="0"></info>*/
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
	CREATE TABLE #tempProblemAccount (custId INT, username NVARCHAR(50), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 NVARCHAR(50), numberOfDownline INT, createdDate DATETIME, isReviewed BIT, ClosedReason TINYINT)
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
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0)
		FROM  dbo.custinfo ci WITH (NOLOCK)
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid																				
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
		WHERE c.srecommend IN (SELECT custId 
								FROM @tmpSuper
								WHERE 1 = CASE WHEN (@UplineID IS NOT NULL AND custId= @UplineID) OR @UplineID IS NULL THEN 1 ELSE 0 END
								)
			AND ci.CustomerClass BETWEEN 8 AND 13					
			AND c.roleid = 3
			AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			--AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			
		SELECT @TotalRows = @@ROWCOUNT

		UPDATE t 
		SET t.numberOfDownline = pa.numberOfDownline
		FROM #tempProblemAccount t 			
			CROSS APPLY (SELECT ci.mrecommend, COUNT(1) AS numberOfDownline
						FROM dbo.custInfo ci WITH (NOLOCK) 							
						WHERE ci.mrecommend = t.custid 
							AND ci.roleid = 2
							AND ci.CustomerClass BETWEEN 8 AND 13	
							--AND pa.ReasonId IS NOT NULL
						GROUP BY ci.mrecommend) AS pa		
	END
	ELSE IF @SearchRoleId = 2 	
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0)
		FROM  dbo.custinfo ci WITH (NOLOCK)
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
		WHERE 1 = CASE WHEN @UplineID IS NULL OR (@UplineID IS NOT NULL AND c.mrecommend = @UplineID) THEN 1 ELSE 0 END
			AND c.srecommend IN (SELECT custid FROM @tmpSuper)
			AND c.roleid = 2
			AND ci.CustomerClass BETWEEN 8 AND 13	
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
						WHERE ci.recommend = t.custid 
							AND ci.roleid = 1
							AND ci.CustomerClass BETWEEN 8 AND 13
							--AND (pa.ReasonId IS NOT NULL OR pa.IsAbnormalMember = 1)
						GROUP BY ci.recommend) AS pa	
	END
	ELSE IF @SearchRoleId = 1
	BEGIN		
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.ModifiedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0)
		FROM  dbo.custinfo ci WITH (NOLOCK)
			INNER JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
		WHERE 1 = CASE WHEN @UplineID IS NULL OR (@UplineID IS NOT NULL AND c.recommend = @UplineID) THEN 1 ELSE 0 END
			AND c.srecommend IN (SELECT custid FROM @tmpSuper)
			AND c.roleid = 1
			AND (p.ModifiedDate >= @FromDate AND p.ModifiedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			AND ci.CustomerClass BETWEEN 8 AND 13
			--AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
		
		SELECT @TotalRows = @@ROWCOUNT
	END
	
	/* ===== Paging ===== */
	--@Status: 1: Open, 2:Suppended, 3: Closed, 4: Disabled
	SELECT custId, username, firstname, lastname, username2, ISNULL(numberOfDownline, 0) AS numberOfDownline, status, createdDate, isReviewed, ClosedReason
	FROM (
		SELECT t.custId, t.username, t.firstname, t.lastname, t.username2, t.numberOfDownline, t.ClosedReason,
			CASE WHEN ci.Enabled = 1 THEN CASE WHEN ci.closed = 1 THEN 3 WHEN ci.reject = 1 THEN 2 ELSE 1 END ELSE 4 END AS Status,
			t.createdDate, t.isReviewed, ROW_NUMBER() OVER (ORDER BY t.isReviewed ASC, t.createdDate DESC, t.username ASC) AS RowId
		FROM #tempProblemAccount t
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = t.custId
	) AS Result
	WHERE RowId BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageSize * @PageIndex)

	DROP TABLE #tempProblemAccount
END
