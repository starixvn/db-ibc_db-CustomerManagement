USE [bodb02]
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_UnblockedMemberSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_UnblockedMemberSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_UnblockedMemberSel]
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
	SET NOCOUNT ON	
	DECLARE @Today DATE
	
	SELECT @ToDay = CONVERT(DATE, GETDATE())

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
		, TotalWinAmt MONEY, IsBlocked BIT, UserName VARCHAR(50), Currency TINYINT, ProductName VARCHAR(50), BlockedDate DATETIME
		, UnblockedDate DATETIME, ModifiedBy INT, BetType SMALLINT)

	IF @UserName = ''
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
			INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
		WHERE g.IsBlocked = 0
			AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
		
		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.UnBlockedDate DESC) AS RowNum
				, g.CustID
				, g.ProductID
				, g.MaxWinLimit
				, g.BlockedWinAmt
				, CASE WHEN WinlostDate = @Today THEN g.TotalWinAmt ELSE 0 END AS TotalWinAmt
				, g.BlockedDate
				, g.IsBlocked
				--, g.CreatedBy
				, g.UnblockedDate
				, g.ModifiedBy
				, g.BetType
				, c.UserName
				, c.Currency
				, p.ProductName
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
				INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
			WHERE g.IsBlocked = 0
				AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
		)
		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, IsBlocked
			, UserName, Currency, ProductName, BlockedDate, UnblockedDate, ModifiedBy, BetType)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, IsBlocked
			, UserName, Currency, ProductName, BlockedDate, UnblockedDate, ModifiedBy, BetType
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)

	END
	ELSE
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
			INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
		WHERE g.IsBlocked = 0
			AND g.CustId = @CustId
			AND @ExchangeID = c.currency

		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.UnBlockedDate DESC) AS RowNum
				, g.CustID
				, g.ProductID
				, g.MaxWinLimit
				, g.BlockedWinAmt
				, CASE WHEN WinlostDate = @Today THEN g.TotalWinAmt ELSE 0 END AS TotalWinAmt
				, g.BlockedDate
				, g.IsBlocked
				--, g.CreatedBy
				, g.UnblockedDate
				, g.ModifiedBy
				, g.BetType
				, c.UserName
				, c.Currency
				, p.ProductName
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON g.CustId = c.CustId AND c.RoleId = 1
				INNER JOIN #tempProduct p ON g.ProductId = p.ProductId
			WHERE g.IsBlocked = 0
				AND g.CustId = @CustId
				AND @ExchangeID = c.currency
		)
		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, IsBlocked
			, UserName, Currency, ProductName, BlockedDate, UnblockedDate, ModifiedBy, BetType)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, IsBlocked
			, UserName, Currency, ProductName, BlockedDate, UnblockedDate, ModifiedBy, BetType
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END

	SELECT rs.RowNum, rs.CustId, rs.UserName, e.ExchangeID, e.currency, rs.ProductId, rs.ProductName
		, rs.BlockedDate AS BlockedTime
		, rs.UnblockedDate AS UnblockedTime
		, rs.IsBlocked
		, rs.ModifiedBy AS UnblockedBy
		, CASE WHEN cw.CustId IS NOT NULL THEN cw.MaxWinLimit ELSE gs.MaxWinLimit END AS WinLimit
		, ISNULL(rs.TotalWinAmt, 0) + ISNULL(wc.Winlost, 0) - ISNULL(wd.Winlost, 0) AS TodayWinningAmount
		, rs.TotalWinAmt AS TotalWinningAmount
		, c.username AS UnblockedByUserName
	FROM #tempResult rs
		INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) 
			ON rs.Currency = e.ExchangeId AND (@ExcludeTestData = 0 OR e.currency NOT IN ('UUS'))
		LEFT JOIN dbo.WinLimit_CreditGame wc WITH (NOLOCK) 
			ON rs.CustId = wc.CustId AND rs.bettype = wc.Bettype AND wc.Winlostdate = @Today
		LEFT JOIN dbo.WinLimit_DebitGame wd WITH (NOLOCK)
			ON rs.CustId = wd.CustId AND rs.bettype = wd.Bettype AND wd.Winlostdate = @Today
		LEFT JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON rs.ModifiedBy = c.CustId
		LEFT JOIN DBCUST.CustDB.dbo.WinLimit_CustSetting cw WITH(NOLOCK) 
			ON rs.CustId = cw.CustId AND rs.ProductId = cw.ProductId
		LEFT JOIN dbo.WinLimit_GlobalSetting gs WITH(NOLOCK)
			ON rs.ProductID = gs.ProductID AND rs.Currency = gs.ExchangeId
	ORDER BY RowNum ASC
	
	DROP TABLE #tempProduct
	DROP TABLE #tempResult
	RETURN;
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_UnblockedMemberSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_UnblockedMemberSel] TO [vnteam]
GO