/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CS_ProblemAccount_CustomerList]
	@FromDate			DATETIME,
	@ToDate				DATETIME,
	@CustId				INT,
	@SubAccId			INT = 0,
	@IsAllDownline		BIT = 0,
	@UplineUsername		NVARCHAR(50) = '',
	@SearchRoleId		TINYINT,
	@SearchUsername		NVARCHAR(50) = '',
	@ReviewStatusId		TINYINT = 0,
	@PageIndex			INT = 1,
	@PageSize			INT = 500,
	@TotalRows			INT = 0 OUTPUT
AS

/*
	Created: 20190806@Alvin
	DB: DBCUST/CustDB
	Task: Problem Accounts

	Revisions:
		- 20190806@Alvin: Initialize SP [RedmineID: #116814]
		
	Param's Explanation:
		@CustId: Super login
		@SubAccId: SubAccount Id
		@IsAllDownline: is view all downlines
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
	
	CREATE TABLE #tempProblemAccount (custId INT, uplineUsername NVARCHAR(50),username NVARCHAR(50), firstname NVARCHAR(50), username2 NVARCHAR(50), numberOfDownline INT, createdDate datetime, isReviewed bit)

	-- Sarch master problem account
	IF @SearchRoleId = 3
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, firstname, username2, createdDate, isReviewed)
		SELECT c.custid, c.username, c.firstname, c.username2, p.CreatedDate, p.IsReviewed
		FROM  dbo.CS_ProblemAccount p WITH (NOLOCK)
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
		WHERE c.srecommend = @CustId
			AND (@IsAllDownline = 1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
			AND c.roleid = @SearchRoleId
			AND (p.CreatedDate >= @FromDate AND p.CreatedDate < DATEADD(DAY, 1, @ToDate))
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			AND (
				c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				OR c.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
				OR c.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			)
		
		SELECT @TotalRows = @@ROWCOUNT

		UPDATE t 
		SET t.numberOfDownline = pa.numberOfDownline
		FROM #tempProblemAccount t 			
			CROSS APPLY (SELECT ci.mrecommend, COUNT(1) AS numberOfDownline
						FROM dbo.custInfo ci WITH (NOLOCK) 
							INNER JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON pa.CustId = ci.custid
						WHERE ci.mrecommend = t.custid AND ci.roleid = 2
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
		END

		IF @SearchRoleId = 2
		BEGIN
			INSERT INTO #tempProblemAccount(custId, uplineUsername, username, firstname, username2, createdDate, isReviewed)
			SELECT c.custid, u.username, c.username, c.firstname, c.username2, p.CreatedDate, p.IsReviewed
			FROM  dbo.CS_ProblemAccount p WITH (NOLOCK)
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
				CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.mrecommend) AS u
			WHERE ((ISNULL(@UplineUsername, '') = '' AND c.srecommend = @CustId) OR c.mrecommend = @UplineId)
				AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.mrecommend))
				AND c.roleid = @SearchRoleId
				AND (p.CreatedDate >= @FromDate AND p.CreatedDate < DATEADD(DAY, 1, @ToDate))
				AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
				AND (
					c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
					OR c.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
					OR c.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				)

			SELECT @TotalRows = @@ROWCOUNT

			UPDATE t 
			SET t.numberOfDownline = pa.numberOfDownline
			FROM #tempProblemAccount t 			
				CROSS APPLY (SELECT ci.recommend, COUNT(1) AS numberOfDownline
							FROM dbo.custInfo ci WITH (NOLOCK) 
								INNER JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON pa.CustId = ci.custid
							WHERE ci.recommend = t.custid AND ci.roleid = 1
							GROUP BY ci.recommend) AS pa

			
		END
		ELSE IF @SearchRoleId = 1
		BEGIN
			INSERT INTO #tempProblemAccount(custId, uplineUsername, username, firstname, username2, createdDate, isReviewed)
			SELECT c.custid, u.username, c.username, c.firstname, c.username2, p.CreatedDate, p.IsReviewed
			FROM  dbo.CS_ProblemAccount p WITH (NOLOCK)
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
				CROSS APPLY (SELECT username FROM dbo.custInfo ci WITH (NOLOCK) WHERE ci.custid = c.recommend) AS u
			WHERE ((ISNULL(@UplineUsername, '') = '' AND c.srecommend = @CustId) OR c.recommend = @UplineId)
				AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.mrecommend))
				AND c.roleid = @SearchRoleId
				AND (p.CreatedDate >= @FromDate AND p.CreatedDate < DATEADD(DAY, 1, @ToDate))
				AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
				AND (
					c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
					OR c.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
					OR c.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				)

			SELECT @TotalRows = @@ROWCOUNT
		END
	END

	/* ===== Paging ===== */
	SELECT custId, uplineUsername, username, firstname as Name, n.NickName, ISNULL(numberOfDownline, 0) AS numberOfDownline, status, createdDate, isReviewed
	FROM (
		SELECT t.custId, t.uplineUsername, t.username, t.firstname, t.username2, t.numberOfDownline, cs.CustStatus as status, t.createdDate, t.isReviewed, ROW_NUMBER() OVER (ORDER BY t.isReviewed, t.username) AS RowId
		FROM #tempProblemAccount t
		CROSS APPLY dbo.f_CS_GetCustomerStatus(t.custid) cs
	) AS Result
		CROSS APPLY (SELECT * FROM dbo.f_CS_GetNickName(Result.username2, 0)) n
	WHERE RowId BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageSize * @PageIndex)

	DROP TABLE #tempProblemAccount
END