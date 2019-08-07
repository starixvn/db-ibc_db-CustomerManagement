/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CS_Customer_ProblemAccount_Sel]
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
	DB: DBAGE.bodb02
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
	
	CREATE TABLE #tempCustomer (custId INT, username NVARCHAR(50), name NVARCHAR(50), status TINYINT, createdDate datetime, isReviewed bit)

	-- Sarch master problem account
	IF @SearchRoleId = 3
	BEGIN
		INSERT INTO #tempCustomer(custId, username, name, status)
		SELECT c.custid, c.username, c.username2, cs.CustStatus
		FROM  dbo.Customer c
			CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
		WHERE c.srecommend = @CustId 
			AND c.roleid = @SearchRoleId
			AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
			AND (
				c.username LIKE '%' + @SearchUsername + '%'
				OR c.username2 LIKE 'CN88$%' + @SearchUsername + '%'
				OR c.firstname LIKE '%' + @SearchUsername + '%'
			)
			/*AND Review Status Condition*/

		SELECT @TotalRows = @@ROWCOUNT
	END
	ELSE
	BEGIN
		IF @UplineUsername = ''
		BEGIN
			INSERT INTO #tempCustomer(custId, username, name, status)
			SELECT c.custid, c.username, c.username2, cs.CustStatus 
			FROM  dbo.Customer c
				CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
			WHERE c.srecommend = @CustId 
				AND c.roleid = @SearchRoleId
				AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
				AND (
					c.username LIKE '%' + @SearchUsername + '%'
					OR c.username2 LIKE 'CN88$%' + @SearchUsername + '%'
					OR c.firstname LIKE '%' + @SearchUsername + '%'
				)
				/*AND Review Status Condition*/

			SELECT @TotalRows = @@ROWCOUNT
		END
		ELSE
		BEGIN
			-- get uplineId
			DECLARE @UplineId INT
			SELECT @UplineId = custid FROM dbo.Customer WITH (NOLOCK)
			WHERE username = @UplineUsername AND roleid = @SearchRoleId + 1

			IF @SearchRoleId = 2
			BEGIN
				INSERT INTO #tempCustomer(custId, username, name, status)
				SELECT c.custid, c.username, c.username2, cs.CustStatus
				FROM  dbo.Customer c
					CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
				WHERE c.mrecommend = @UplineId 
					AND c.roleid = @SearchRoleId
					AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
					AND (
						c.username LIKE '%' + @SearchUsername + '%'
						OR c.username2 LIKE 'CN88$%' + @SearchUsername + '%'
						OR c.firstname LIKE '%' + @SearchUsername + '%'
					)
					/*AND Review Status Condition*/

				SELECT @TotalRows = @@ROWCOUNT
			END
			ELSE IF @SearchRoleId = 1
			BEGIN
				INSERT INTO #tempCustomer(custId, username, name, status)
				SELECT c.custid, c.username, c.username2, cs.CustStatus
				FROM  dbo.Customer c
					CROSS APPLY dbo.f_CS_GetCustomerStatus(c.custid) cs
				WHERE c.recommend = @UplineId 
					AND c.roleid = @SearchRoleId
					AND (@IsAllDownline =1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = c.custid))
					AND (
						c.username LIKE '%' + @SearchUsername + '%'
						OR c.username2 LIKE 'CN88$%' + @SearchUsername + '%'
						OR c.firstname LIKE '%' + @SearchUsername + '%'
					)
					/*AND Review Status Condition*/

				SELECT @TotalRows = @@ROWCOUNT
			END
		END
	END

	/* ===== Paging ===== */
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= (@PageIndex - 1) * @PageSize + 1,
			@RowEnd		= @RowStart + @PageSize - 1

	SELECT custId, username, name, n.NickName, status, createdDate, isReviewed
	FROM (
		SELECT custId, username, name, status, createdDate, isReviewed, ROW_NUMBER() OVER (ORDER BY username) AS RowId
		FROM #tempCustomer
	) AS Result
		CROSS APPLY (SELECT * FROM dbo.f_CS_GetNickName(Result.username,0)) n
	WHERE RowId BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tempCustomer
END
GO