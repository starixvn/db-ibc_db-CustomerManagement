/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Age_ProblemAccount_CustomerListBySAg]
	@FromDate			DATETIME,
	@ToDate				DATETIME,
	@CustId				INT,
	@SubAccId			INT = 0,
	@UplineUsername		NVARCHAR(50) = '',
	@SearchRoleId		TINYINT,
	@SearchUsername		NVARCHAR(50) = '',
	@ReviewStatusId		TINYINT = 0,
	@PageIndex			INT = 1,
	@PageSize			INT = 500,
	@TotalRows			INT = 0 OUTPUT
AS

/*
	Created: 20200210@Elodie
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20200210@Elodie: Initial SP [Redmine:#127446]
		
	Param's Explanation:
		@CustId: Super login
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
	
	CREATE TABLE #tempProblemAccount (custId INT, uplineUsername NVARCHAR(50), username NVARCHAR(50), firstname NVARCHAR(50), lastname NVARCHAR(50), username2 NVARCHAR(50), numberOfDownline INT, createdDate DATETIME, isReviewed BIT, ClosedReason TINYINT)
	DECLARE @RoleId TINYINT

	SELECT @RoleId = roleid FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @CustId
	-- Sarch master problem account
	IF @SearchRoleId = 3
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason)
		SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.CreatedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0)
		FROM  dbo.ProblemAccount p WITH (NOLOCK)
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
		WHERE c.srecommend = @CustId
			AND c.roleid = @SearchRoleId
			AND (p.CreatedDate >= @FromDate AND p.CreatedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			AND p.ReasonId IS NOT NULL
			AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
		
		SELECT @TotalRows = @@ROWCOUNT

		UPDATE t 
		SET t.numberOfDownline = pa.numberOfDownline
		FROM #tempProblemAccount t 			
			CROSS APPLY (SELECT ci.mrecommend, COUNT(1) AS numberOfDownline
						FROM dbo.custInfo ci WITH (NOLOCK) 
							INNER JOIN dbo.ProblemAccount pa WITH (NOLOCK) ON pa.CustId = ci.custid
						WHERE ci.mrecommend = t.custid 
							AND ci.roleid = 2
							AND pa.ReasonId IS NOT NULL
						GROUP BY ci.mrecommend) AS pa		
	END
	ELSE
	BEGIN
		-- get @UplineId if @UplineUsername isn't empty
		DECLARE @UplineId INT
		IF @UplineUsername <> ''
		BEGIN
			SELECT @UplineId = custid FROM dbo.Customer WITH (NOLOCK)
			WHERE username = @UplineUsername AND roleid = @SearchRoleId + 1 
				AND CASE WHEN @RoleId = 4 THEN srecommend 
						WHEN @RoleId = 3 THEN mrecommend 
						WHEN @RoleId = 2 THEN recommend END = @CustId
		END

		IF @UplineId IS NULL
		BEGIN
			SELECT @TotalRows = 0
		END
		ELSE
		BEGIN
			IF @SearchRoleId = 2
			BEGIN
				INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason)
				SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.CreatedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0)
				FROM  dbo.ProblemAccount p WITH (NOLOCK)
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
					LEFT JOIN dbo.CustLoginInfo cl WITH (NOLOCK) ON cl.CustId = c.CustId
					CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.mrecommend) AS u
				WHERE ((ISNULL(@UplineUsername, '') = '' AND c.srecommend = @CustId) OR c.mrecommend = @UplineId)
					AND c.roleid = @SearchRoleId
					AND (p.CreatedDate >= @FromDate AND p.CreatedDate < DATEADD(DAY, 1, @ToDate))
					AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
					AND p.ReasonId IS NOT NULL
					AND c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'

				SELECT @TotalRows = @@ROWCOUNT

				UPDATE t 
				SET t.numberOfDownline = pa.numberOfDownline
				FROM #tempProblemAccount t 			
					CROSS APPLY (SELECT ci.recommend, COUNT(1) AS numberOfDownline
								FROM dbo.custInfo ci WITH (NOLOCK) 
									INNER JOIN dbo.ProblemAccount pa WITH (NOLOCK) ON pa.CustId = ci.custid
								WHERE ci.recommend = t.custid 
									AND ci.roleid = 1
									AND (pa.ReasonId IS NOT NULL OR pa.IsAbnormalMember = 1)
								GROUP BY ci.recommend) AS pa

			
			END
			ELSE IF @SearchRoleId = 1
			BEGIN
				INSERT INTO #tempProblemAccount(custId, username, firstname, lastname, username2, createdDate, isReviewed, ClosedReason)
				SELECT c.custid, c.username, c.firstname, c.lastname, c.username2, p.CreatedDate, p.IsReviewed, ISNULL(cl.ClosedReason,0)
				FROM  dbo.ProblemAccount p WITH (NOLOCK)
					INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
					LEFT JOIN dbo.CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustId = c.CustId
					CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.recommend) AS u
				WHERE ((ISNULL(@UplineUsername, '') = '' AND c.srecommend = @CustId) OR c.recommend = @UplineId)
					AND c.roleid = @SearchRoleId
					AND (p.CreatedDate >= @FromDate AND p.CreatedDate < DATEADD(DAY, 1, @ToDate))
					AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
					AND (p.ReasonId IS NOT NULL OR p.IsAbnormalMember = 1)
					AND  c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'

				SELECT @TotalRows = @@ROWCOUNT
			END
		END
	END

	/* ===== Paging ===== */
	--@Status: 1: Open, 2:Suppended, 3: Closed, 4: Disabled
	SELECT custId, uplineUsername, username, firstname, lastname, username2, ISNULL(numberOfDownline, 0) AS numberOfDownline, status, createdDate, isReviewed, ClosedReason
	FROM (
		SELECT t.custId, t.uplineUsername, t.username, t.firstname, t.lastname, t.username2, t.numberOfDownline, t.ClosedReason,
			CASE WHEN ci.Enabled = 1 THEN CASE WHEN ci.closed = 1 THEN 3 WHEN ci.reject = 1 THEN 2 ELSE 1 END ELSE 4 END AS Status,
			t.createdDate, t.isReviewed, ROW_NUMBER() OVER (ORDER BY t.isReviewed, t.username) AS RowId
		FROM #tempProblemAccount t
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON ci.custid = t.custId
	) AS Result
	WHERE RowId BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageSize * @PageIndex)

	DROP TABLE #tempProblemAccount
END