/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_Customer_DownlineList_Sel]
	@CustId				INT,
	@SubAccId			INT = 0,
	@DownlineUsername	NVARCHAR(50) = '',
	@SearchRoleId		TINYINT,
	@SearchUsername		NVARCHAR(50),
	@SearchStatusId		TINYINT = 0,
	@UplineId			INT = 0 OUTPUT,
	@UplineStatus		TINYINT = 4 OUTPUT,
	@IsUplineClosed		BIT = 1 OUTPUT,
	@PageIndex			INT = 1,
	@PageSize			INT = 500,
	@TotalRows			INT = 0 OUTPUT
AS

/*
	Created: 20181218@Percy
	DB: DBAGE.bodb02
	Task: Member Information >> Downline List

	Revisions:
		- 20181218@Percy: Initialize SP [RedmineID: #105338]
		- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
		- 20190514@Paul: Apply new status [RedmineID: #113198]
		- 20190720@Percy: Add sub account - permission on downlines [RedmineID: #116825]

	Param's Explanation:
		@CustId: SMA login
		@DownlineUsername: search downlines under @DownlineUsername, if search direct downline: no need
		@SearchRoleId:
			3: Master List (Super Login)
			2: Agent List (Super/Master Login)
			1: Member List (Super/Master/Agent Login)
		@SearchStatusId:
			0: All
			4: Active
			3: View Only
			2: Suspended
			1: Inactive
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @RoleId TINYINT
	SELECT  @RoleId = roleId FROM dbo.custInfo WITH (NOLOCK) WHERE custId = @custId

	-- Check Sub Account is view all downlines or not
	DECLARE @IsAllDownline BIT

	IF ISNULL(@SubAccId, 0) <> 0
	BEGIN
		SELECT @IsAllDownline = IsAllDownline FROM dbo.custSub WITH (NOLOCK)
		WHERE subaccid = @SubAccId

		SELECT @IsAllDownline = ISNULL(@IsAllDownline, 0)
	END
	ELSE
	BEGIN
		SELECT @IsAllDownline = 1
	END

	-- Search direct downline
	IF @RoleId = @SearchRoleId + 1
	BEGIN
		SELECT @UplineId = @CustId
	END
	-- Search in-direct downline
	ELSE
	BEGIN
		IF @RoleId = 4 AND @SearchRoleId < 3
		BEGIN
			SELECT @UplineId = custid FROM dbo.custInfo WITH (NOLOCK)
			WHERE username = @DownlineUsername AND srecommend = @CustId AND roleId = @SearchRoleId + 1
		END
		ELSE IF @RoleId = 3 AND @SearchRoleId < 2
		BEGIN
			SELECT @UplineId = custid FROM dbo.custInfo WITH (NOLOCK)
			WHERE username = @DownlineUsername AND mrecommend = @CustId AND roleId = @SearchRoleId + 1
		END

		IF @IsAllDownline = 0
		BEGIN
			IF NOT EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) WHERE DownlineId = @UplineId)
			BEGIN
				SELECT @UplineId = NULL
			END
		END 
	END

	SELECT @IsUplineClosed = closed
	FROM dbo.custInfo ci WITH (NOLOCK)
	WHERE ci.CustId = @UplineId

	SELECT @UplineStatus = CustStatus
	FROM dbo.f_CS_GetCustomerStatus(@UplineId)

	CREATE TABLE #CustInfo (custId INT, username NVARCHAR(50), credit MONEY, Status TINYINT, IsClosed BIT)

	IF @SearchRoleId = 3
	BEGIN
		INSERT INTO #CustInfo (custId, username, credit, Status, IsClosed)
		SELECT ci.custid, ci.username, ISNULL(ci.credit, 0),
				cs.CustStatus, ci.closed
		FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.Customer cu WITH (NOLOCK) ON ci.custid = cu.custid
			CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
		WHERE ci.srecommend = @UplineId
			AND (@IsAllDownline = 1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = ci.custid))
			AND ci.roleId = 3
			AND (
				ci.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				OR cu.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
				OR cu.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			)
			AND (
				@SearchStatusId = 0
				OR (@SearchStatusId = 4 AND cs.CustStatus = 4)
				OR (@SearchStatusId = 3 AND cs.CustStatus = 3)
				OR (@SearchStatusId = 2 AND cs.CustStatus = 2)
				OR (@SearchStatusId = 1 AND cs.CustStatus = 1)
			)

		SELECT @TotalRows = @@ROWCOUNT
	END
	ELSE IF @SearchRoleId = 2
	BEGIN
		INSERT INTO #CustInfo (custId, username, credit, Status, IsClosed)
		SELECT ci.custid, ci.username, ISNULL(ci.credit, 0),
				cs.CustStatus, ci.closed
		FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.Customer cu WITH (NOLOCK) ON ci.custid = cu.custid
			CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
		WHERE ci.mrecommend = @UplineId
			AND (@IsAllDownline = 1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = ci.custid))
			AND ci.roleId = 2
			AND (
				ci.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				OR cu.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
				OR cu.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			)
			AND (
				@SearchStatusId = 0
				OR (@SearchStatusId = 4 AND cs.CustStatus = 4)
				OR (@SearchStatusId = 3 AND cs.CustStatus = 3)
				OR (@SearchStatusId = 2 AND cs.CustStatus = 2)
				OR (@SearchStatusId = 1 AND cs.CustStatus = 1)
			)

		SELECT @TotalRows = @@ROWCOUNT
	END
	ELSE IF @SearchRoleId = 1
	BEGIN
		INSERT INTO #CustInfo (custId, username, credit, Status, IsClosed)
		SELECT ci.custid, ci.username, ISNULL(ci.credit, 0),
				cs.CustStatus, ci.closed
		FROM dbo.custInfo ci WITH (NOLOCK)
			INNER JOIN dbo.Customer cu WITH (NOLOCK) ON ci.custid = cu.custid
			CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
		WHERE ci.recommend = @UplineId
			AND (@IsAllDownline = 1 OR EXISTS (SELECT DownlineId FROM dbo.CS_f_GetDownlineBySubAcc(@SubAccId) s WHERE s.DownlineId = ci.custid))
			AND ci.roleId = 1
			AND (
				ci.username LIKE '%' + ISNULL(@SearchUsername, '') + '%'
				OR cu.username2 LIKE 'CN88$%' + ISNULL(@SearchUsername, '') + '%'
				OR cu.firstname LIKE '%' + ISNULL(@SearchUsername, '') + '%'
			)
			AND (
				@SearchStatusId = 0
				OR (@SearchStatusId = 4 AND cs.CustStatus = 4)
				OR (@SearchStatusId = 3 AND cs.CustStatus = 3)
				OR (@SearchStatusId = 2 AND cs.CustStatus = 2)
				OR (@SearchStatusId = 1 AND cs.CustStatus = 1)
			)

		SELECT @TotalRows = @@ROWCOUNT
	END

	/* ===== Paging ===== */
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= (@PageIndex - 1) * @PageSize + 1,
			@RowEnd		= @RowStart + @PageSize - 1

	SELECT custid, username, n.NickName AS nickname, firstname, credit, [group], CreatedDate, Status, IsClosed
	FROM (
		SELECT	ci.custid, ci.username, cu.username2, cu.firstname, ci.credit, cu.ugroup AS [group],
				cu.creatdate AS CreatedDate, ci.Status, ci.IsClosed,
				ROW_NUMBER() OVER(ORDER BY ci.Status DESC, ci.username) AS RowId
		FROM #CustInfo ci
			INNER JOIN dbo.Customer cu WITH (NOLOCK) ON ci.custid = cu.custid
	) AS Result
		CROSS APPLY (SELECT NickName FROM dbo.f_CS_GetNickName(Result.username2,0)) n
	WHERE RowId BETWEEN @RowStart AND @RowEnd

	DROP TABLE #CustInfo
END
GO