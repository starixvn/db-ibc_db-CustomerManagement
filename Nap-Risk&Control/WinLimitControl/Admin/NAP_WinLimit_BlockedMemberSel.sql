USE [bodb02]
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_BlockedMemberSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_BlockedMemberSel];

GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_BlockedMemberSel]
	@UserName			VARCHAR(100)	= '',
	@ExchangeID			INT				= 0,
	@ProductID			TINYINT			= 0,
	@ExcludeTestData	BIT				= 1,
	@PageIndex			INT				= 1,
	@PageSize			INT				= 50,
	@TotalRow			INT				= 0		OUTPUT
AS
	/*
		Created: Phillip	
		Date: 2015-06-30
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		DB: DBTXN/bodb02
		Description: Get All blocked users from Winlimit_Game table.
		Revisions:
		
		Parameters Explanation:	
			@UserName	: User Name.
			@ExchangeID : Currency ID.
			@IsBlocked	: Is blocked player.
			@ProductID	: Game ID.
			@PageIndex	: Current page.
			@PageSize	: Page size.
			@TotalRow	: Total Rows.
	*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT ProductID, ProductName
	INTO #tempProduct
	FROM dbo.f_Winlimit_GetProductSetting() p
	WHERE p.IsActive_Company= 1
		AND (@ProductID = 0 OR ProductID = @ProductID)

	DECLARE @CustId INT
	IF ISNULL(@UserName, '') = ''
	BEGIN
		SET @UserName = ''
	END
	ELSE
	BEGIN
		SELECT @CustId = CustId, @ExchangeID = Currency
		FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE UserName = @UserName
	END

	IF ISNULL(@ExchangeID, 0) = 0
	BEGIN
		SET @ExchangeID = 0
	END

	IF ISNULL(@ProductID, 0) = 0
	BEGIN
		SET @ProductID = 0
	END

	CREATE TABLE #tempResult (RowNum INT, CustID INT, ProductID TINYINT, MaxWinLimit MONEY, BlockedWinAmt MONEY
		, TotalWinAmt MONEY, BlockedDate DATETIME, IsBlocked BIT, CreatedBy INT, UserName VARCHAR(50)
		, Currency TINYINT, ProductName VARCHAR(50))

	IF @UserName = ''
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
			INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
		WHERE g.IsBlocked = 1
			--AND (@UserName = '' OR @UserName = c.UserName)
			AND (@ExchangeID = 0 OR @ExchangeID = c.currency)

		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.BlockedDate DESC) AS RowNum
				, g.CustID
				, g.ProductID
				, g.MaxWinLimit
				, g.BlockedWinAmt
				, g.TotalWinAmt
				, g.BlockedDate
				, g.IsBlocked
				, g.CreatedBy
				, c.UserName
				, c.Currency
				, p.ProductName
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
				INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
			WHERE g.IsBlocked = 1
				--AND (@UserName = '' OR @UserName = c.UserName)
				AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
		)
		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName
		--INTO #tempResult
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END
	ELSE
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
			INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
		WHERE g.IsBlocked = 1
			AND g.CustId = @CustId-- @UserName = c.UserName
			AND @ExchangeID = c.currency

		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.BlockedDate DESC) AS RowNum
				, g.CustID
				, g.ProductID
				, g.MaxWinLimit
				, g.BlockedWinAmt
				, g.TotalWinAmt
				, g.BlockedDate
				, g.IsBlocked
				, g.CreatedBy
				, c.UserName
				, c.Currency
				, p.ProductName
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
				INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
			WHERE g.IsBlocked = 1
				AND g.CustId = @CustId --@UserName = c.UserName
				AND @ExchangeID = c.currency
		)

		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName
		--INTO #tempResult
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END
		
	SELECT rs.RowNum, rs.CustID, rs.username, e.ExchangeId, e.currency, rs.ProductId, rs.ProductName, rs.IsBlocked
		, rs.MaxWinLimit AS WinLimit
		, rs.BlockedWinAmt AS BlockedWinningAmount
		, rs.TotalWinAmt AS TotalWinningAmount
		, rs.BlockedDate AS BlockedTime
		, rs.CreatedBy AS BlockedBy
		, c.UserName AS BlockedByUserName
	FROM #tempResult rs
		INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON rs.Currency = e.ExchangeId AND (@ExcludeTestData = 0 OR e.currency NOT IN ('UUS'))
		LEFT JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON rs.CreatedBy = c.CustId
	ORDER BY RowNum ASC
	
	DROP TABLE #tempProduct
	DROP TABLE #tempResult
	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[NAP_WinLimit_BlockedMemberSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_BlockedMemberSel] TO [vnteam]
GO