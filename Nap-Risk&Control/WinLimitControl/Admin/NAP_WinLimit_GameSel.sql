USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_GameSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_GameSel];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE dbo.NAP_WinLimit_GameSel @FromDate SMALLDATETIME
	, @ToDate SMALLDATETIME
	, @UserName VARCHAR(50) = ''
	, @ExchangeID INT = 0
	, @ProductID TINYINT = 0
	, @ExcludeTestData BIT = 1
	
	, @PageIndex INT = 1
	, @PageSize INT = 50
	, @TotalRow INT = 0 OUTPUT
AS
	/*
		Created: 20150630@Phillip	
		Task: Get All users from Winlimit_Game table.
		DB: DBTXN/bodb02
		Revisions:
			- 20160507@Patrick: #57213 - Voidbridge integration
			- 20160520@Helen: Company Winlimit - Member reach red level, block Licensee only, not Credit [Redmine: 57680]
		Parameters Explanation:	
	*/
BEGIN
	SET NOCOUNT ON

	IF ISNULL(@ExchangeID, 0) = 0
		SET @ExchangeID = 0
	IF ISNULL(@ProductID, 0) = 0
		SET @ProductID = 0
	
	DECLARE @tempProduct TABLE (bettype SMALLINT, ProductName VARCHAR(100))

	INSERT INTO @tempProduct(bettype, ProductName)
	SELECT BetType, ProductName
	FROM dbo.f_Winlimit_GetProductSetting() p
	WHERE @ProductID = 0 OR ProductID = @ProductID

	DECLARE @CustId INT
	
	IF ISNULL(@UserName, '') = ''
		SET @UserName = ''
	ELSE
		SELECT @CustId = CustId
		FROM CustDB.dbo.Customer c WITH(NOLOCK) WHERE UserName = @UserName

	CREATE TABLE #tempResult (RowNum INT, CustID INT, ProductID TINYINT, MaxWinLimit MONEY, BlockedWinAmt MONEY
		, TotalWinAmt MONEY, BlockedDate DATETIME, IsBlocked BIT, CreatedBy INT, UserName VARCHAR(50)
		, Currency TINYINT, ProductName VARCHAR(50), IsNotified BIT, ModifiedDate DATETIME, WinlostDate SMALLDATETIME,IsDep BIT)

	IF @UserName = ''
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.CustInfo c WITH(NOLOCK) ON g.CustId = c.CustId
			INNER JOIN @tempProduct p ON g.Bettype = p.bettype
		WHERE WinlostDate BETWEEN @FromDate AND @ToDate
			AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
			AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
	
		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.BlockedDate DESC, g.IsBlocked DESC) AS RowNum
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
				, g.IsNotified
				, g.UnBlockedDate
				, g.WinlostDate
				, CASE WHEN CS.custid IS NOT NULL THEN 1 ELSE 0 END AS IsDep
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN @tempProduct p ON g.Bettype = p.bettype
				INNER JOIN CustDB.dbo.CustInfo c WITH(NOLOCK) ON g.CustId = c.CustId
				LEFT JOIN CustDB.dbo.Dep_CustSuper CS WITH (NOLOCK) ON CS.custid = C.srecommend
				
			WHERE WinlostDate BETWEEN @FromDate AND @ToDate
				AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
				AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
		)
		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, ModifiedDate, WinlostDate,IsDep)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, UnBlockedDate, WinlostDate,IsDep
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END
	ELSE
	BEGIN
		SELECT @TotalRow = COUNT(1)
		FROM dbo.WinLimit_Game g WITH (NOLOCK)
			INNER JOIN CustDB.dbo.CustInfo c WITH(NOLOCK) ON g.CustId = c.CustId
			INNER JOIN @tempProduct p ON g.Bettype = p.bettype
		WHERE g.CustId = @CustId
			AND WinlostDate BETWEEN @FromDate AND @ToDate
			AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
			AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
		
		;WITH DataTmp AS (
			SELECT ROW_NUMBER() OVER (ORDER BY g.BlockedDate DESC, g.IsBlocked DESC) AS RowNum
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
				, g.IsNotified
				, g.UnBlockedDate
				, g.WinlostDate
				, CASE WHEN CS.custid IS NOT NULL THEN 1 ELSE 0 END AS IsDep
			FROM dbo.WinLimit_Game g WITH (NOLOCK)
				INNER JOIN @tempProduct p ON g.Bettype = p.bettype
				INNER JOIN CustDB.dbo.CustInfo c WITH(NOLOCK) ON g.CustId = c.CustId
				LEFT JOIN CustDB.dbo.Dep_CustSuper CS WITH (NOLOCK) ON CS.custid = C.srecommend
			WHERE g.CustId = @CustId
				AND WinlostDate BETWEEN @FromDate AND @ToDate
				AND (@ExchangeID = 0 OR @ExchangeID = c.currency)
				AND (@ExcludeTestData = 0 OR c.currency NOT IN (20,27,28))
		)

		INSERT INTO #tempResult(RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, ModifiedDate, WinlostDate,IsDep)
		SELECT RowNum, CustID, ProductID, MaxWinLimit, BlockedWinAmt, TotalWinAmt, BlockedDate, IsBlocked
			, CreatedBy, UserName, Currency, ProductName, IsNotified, UnBlockedDate, WinlostDate, IsDep
		FROM DataTmp
		WHERE RowNum BETWEEN ((@PageIndex - 1) * @PageSize + 1) AND (@PageIndex * @PageSize)
	END
		
	SELECT rs.RowNum, rs.CustID, rs.username, e.ExchangeId, e.currency, rs.ProductId, rs.ProductName, ISNULL(rs.IsBlocked,0) AS IsBlocked
		, rs.MaxWinLimit AS WinLimit
		, rs.BlockedWinAmt AS BlockedWinningAmount
		, rs.TotalWinAmt AS TotalWinningAmount
		, rs.BlockedDate AS BlockedTime
		, rs.CreatedBy AS BlockedBy
		, c.UserName AS BlockedByUserName
		, CASE 
				WHEN IsDep = 1 THEN CAST(CASE WHEN DATEADD(MINUTE, -3, GETDATE()) < BlockedDate AND rs.IsBlocked = 1 THEN 1 ELSE 0 END AS BIT) 
				ELSE CAST(CASE WHEN DATEADD(MINUTE, -3, GETDATE()) < BlockedDate THEN 1 ELSE 0 END AS BIT)  END AS IsNotified
		, WinlostDate
	FROM #tempResult rs
		INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON rs.Currency = e.ExchangeId
		LEFT JOIN CustDB.dbo.Customer c WITH(NOLOCK) ON rs.CreatedBy = c.CustId
	ORDER BY RowNum ASC
			
	DROP TABLE #tempResult
END
GO

GRANT EXECUTE ON [dbo].[NAP_WinLimit_GameSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_GameSel] TO [vnteam]
GO