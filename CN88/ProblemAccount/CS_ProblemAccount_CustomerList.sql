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
	
	CREATE TABLE #tempProblemAccount (custId INT, username NVARCHAR(50), name NVARCHAR(50), numberOfDownline INT, status TINYINT, createdDate datetime, isReviewed bit)

	-- Sarch master problem account
	IF @SearchRoleId = 3
	BEGIN
		INSERT INTO #tempProblemAccount(custId, username, name, numberOfDownline, status, createdDate, isReviewed)
		SELECT c.custid, c.username, c.username2, d.NumberOfDownline, cs.CustStatus, p.CreatedDate, p.IsReviewed
		FROM  dbo.CS_ProblemAccount p WITH (NOLOCK)
			INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
			CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
			OUTER APPLY (
				SELECT COUNT(1) AS NumberOfDownline
				FROM dbo.CS_ProblemAccount dp WITH (NOLOCK)
					INNER JOIN dbo.Customer dc WITH (NOLOCK) ON dp.CustId = dc.custid
				WHERE dc.mrecommend = c.custid AND dc.roleid = 2
			) AS d
		WHERE c.srecommend = @CustId
			AND (@IsAllDownline = 1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
			AND c.roleid = @SearchRoleId
			AND p.CreatedDate BETWEEN @FromDate AND @ToDate
			AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
			AND (
				c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				OR c.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
				OR c.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			)
			
		SELECT @TotalRows = @@ROWCOUNT
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
			INSERT INTO #tempProblemAccount(custId, username, name, numberOfDownline, status, createdDate, isReviewed)
			SELECT c.custid, c.username, c.username2, d.NumberOfDownline, cs.CustStatus, p.CreatedDate, p.IsReviewed
			FROM  dbo.CS_ProblemAccount p WITH (NOLOCK)
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
				CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
				OUTER APPLY (
					SELECT COUNT(1) AS NumberOfDownline
					FROM dbo.CS_ProblemAccount dp WITH (NOLOCK)
						INNER JOIN dbo.Customer dc WITH (NOLOCK) ON dp.CustId = dc.custid
					WHERE dc.recommend = c.custid AND dc.roleid = 1
				) AS d
			WHERE ((@SearchUsername = '' AND c.srecommend = @CustId) OR c.mrecommend = @UplineId)
				AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
				AND c.roleid = @SearchRoleId
				AND p.CreatedDate BETWEEN @FromDate AND @ToDate
				AND (@ReviewStatusId = 2 OR p.IsReviewed = @ReviewStatusId)
				AND (
					c.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
					OR c.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
					OR c.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				)

			SELECT @TotalRows = @@ROWCOUNT
		END
		ELSE IF @SearchRoleId = 1
		BEGIN
			INSERT INTO #tempProblemAccount(custId, username, name, status, createdDate, isReviewed)
			SELECT c.custid, c.username, c.username2, cs.CustStatus, p.CreatedDate, p.IsReviewed
			FROM  dbo.CS_ProblemAccount p WITH (NOLOCK)
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON p.CustId = c.CustId
				CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
			WHERE ((@SearchUsername = '' AND c.srecommend = @CustId) OR c.recommend = @UplineId)
				AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
				AND c.roleid = @SearchRoleId
				AND p.CreatedDate BETWEEN @FromDate AND @ToDate
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
	SELECT custId, username, name, n.NickName, numberOfDownline, status, createdDate, isReviewed
	FROM (
		SELECT custId, username, name, numberOfDownline, status, createdDate, isReviewed, ROW_NUMBER() OVER (ORDER BY username) AS RowId
		FROM #tempProblemAccount
	) AS Result
		CROSS APPLY (SELECT * FROM dbo.f_CS_GetNickName(Result.username,0)) n
	WHERE RowId BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageSize * @PageIndex)

	DROP TABLE #tempProblemAccount
END