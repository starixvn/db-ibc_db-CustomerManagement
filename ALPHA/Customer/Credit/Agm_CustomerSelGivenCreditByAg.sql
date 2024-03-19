USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Agm_CustomerSelGivenCreditByAg]
	@Recommend int ,
	@Username varchar(30)=null,  
	@Enabled bit = null,  
	@Closed bit=null,  
	@Suspended bit=null,  
	@PageSize int=50,
	@PageIndex int=0,
	@TotalPages int output
AS

/*

Created: 20110223@Kaden
Task: Get all member's given credit of agent custid=@Recommend. It's only use for IPhone
DB: DBAGE.bodb02

Original:
	- 20140403@Dom: Add Betcredit field
	- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
	- 20160201@Percy: expand new RNG Casino [Redmine: #51912]
	- 20160202@Percy: support new sport Cricket [Redmine: #50027]
	- 20160219@Percy: Support AllBet Live Casino [Redmine: #52553]
	- 20160413@Percy: Support Voidbridge single wallet [Redmine: #55259]
	- 20161028@Percy:
		1. Support Fishing World [RedmineID: #65731]
		2. Apply SportBettypeMatrix
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

	CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
	INSERT INTO #SportBettype (bettype, RefTable)
	SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)

	DECLARE @today     DATE,
			@yesterday DATE
	SELECT @today     = CONVERT(DATE, GETDATE())
	SELECT @yesterday = DATEADD(DD, -1, @today)

	DECLARE @RowCount int, @RowStart int, @RowEnd int  
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	SET @Username = isnull(@Username, '')

	--- Get Customer Info ---
	CREATE TABLE #custInfo (custId INT PRIMARY KEY, username NVARCHAR(100), reject BIT, closed BIT, [Enabled] BIT, givencredit MONEY, RowNum INT)

	IF @Username = '' AND @Enabled IS NULL AND @Closed IS NULL AND @Suspended IS NULL  
	BEGIN
		IF @TotalPages = 0  
		BEGIN  
			SELECT @TotalPages = COUNT(1), @TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
			FROM custinfo WITH(NOLOCK) 
			WHERE recommend=@Recommend AND roleid=1
		END

		INSERT INTO #custInfo (custId, username, reject, closed, [Enabled], givencredit, RowNum)
		SELECT custid, username, reject, closed, [Enabled], credit, RowNum
		FROM
		(
			SELECT custid, username, reject, closed, [Enabled], credit , ROW_NUMBER() OVER(ORDER BY [Enabled] DESC, closed, ISNULL(reject, 0), username) AS RowNum
			FROM custinfo WITH(NOLOCK)
			WHERE recommend = @Recommend AND roleid=1
		) AS c
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
	ELSE IF @Username = ''
	BEGIN
		IF @TotalPages = 0  
		BEGIN  
			SELECT @TotalPages = COUNT(1), @TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
			FROM Custinfo WITH(NOLOCK)
			WHERE recommend=@Recommend AND roleid=1
				AND [Enabled] = CASE WHEN COALESCE(@Closed, @Suspended) IS NOT NULL THEN 1 ELSE COALESCE(@enabled, [Enabled]) END
				AND ISNULL(closed,0) = CASE WHEN @suspended = 1 THEN 0 ELSE COALESCE(@closed, ISNULL(closed, 0)) END
				AND ISNULL(reject,0) = CASE WHEN @Closed = 0 THEN 0 ELSE COALESCE(@suspended, ISNULL(reject, 0)) END
		END
		
		INSERT INTO #custInfo (custId, username, reject, closed, [Enabled], givencredit, RowNum)
		SELECT custid, username, reject, closed, [Enabled], credit, RowNum
		FROM
		(
			SELECT custid, username, reject, closed, [Enabled], credit, ROW_NUMBER() OVER(ORDER BY [Enabled] DESC, closed, ISNULL(reject, 0), username) AS RowNum
			FROM Custinfo WITH(NOLOCK)
			WHERE recommend=@Recommend AND roleid=1
				AND [Enabled] = CASE WHEN COALESCE(@Closed, @Suspended) IS NOT NULL THEN 1 ELSE COALESCE(@enabled, [Enabled]) END
				AND ISNULL(closed,0) = CASE WHEN @suspended = 1 THEN 0 ELSE COALESCE(@closed, ISNULL(closed, 0)) END
				AND ISNULL(reject,0) = CASE WHEN @Closed = 0 THEN 0 ELSE COALESCE(@suspended, ISNULL(reject, 0)) END
		) AS c
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
	ELSE
	BEGIN
		IF @TotalPages = 0  
		BEGIN  
			SELECT @TotalPages = COUNT(1), @TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
			FROM Custinfo WITH(NOLOCK) 
			WHERE recommend=@Recommend AND roleid=1
				AND username LIKE '%' + @Username + '%'  
				AND [Enabled] = CASE WHEN COALESCE(@Closed, @Suspended) IS NOT NULL THEN 1 ELSE COALESCE(@enabled, [Enabled]) END
				AND ISNULL(closed,0) = CASE WHEN @suspended = 1 THEN 0 ELSE COALESCE(@closed, ISNULL(closed, 0)) END
				AND ISNULL(reject,0) = CASE WHEN @Closed = 0 THEN 0 ELSE COALESCE(@suspended, ISNULL(reject, 0)) END
		END
		
		INSERT INTO #custInfo (custId, username, reject, closed, [Enabled], givencredit, RowNum)
		SELECT custid, username, reject, closed, [Enabled], credit, RowNum
		FROM
		(
			SELECT custid, username, reject, closed, [Enabled], credit, ROW_NUMBER() OVER(ORDER BY [Enabled] DESC, closed, ISNULL(reject, 0), username) AS RowNum
			FROM Custinfo WITH(NOLOCK)
			WHERE recommend=@Recommend AND roleid=1
				AND username LIKE '%' + @Username + '%'  
				AND [Enabled] = CASE WHEN COALESCE(@Closed, @Suspended) IS NOT NULL THEN 1 ELSE COALESCE(@enabled, [Enabled]) END
				AND ISNULL(closed,0) = CASE WHEN @suspended = 1 THEN 0 ELSE COALESCE(@closed, ISNULL(closed, 0)) END
				AND ISNULL(reject,0) = CASE WHEN @Closed = 0 THEN 0 ELSE COALESCE(@suspended, ISNULL(reject, 0)) END
		) AS c
		WHERE RowNum BETWEEN @RowStart AND @RowEnd
	END
	--- End Get Customer Info ---

	--- Get Balance Info ---
	CREATE TABLE #BalanceInfo (custId INT, outstanding MONEY, balance MONEY)
		-- bettrans
	INSERT INTO #BalanceInfo (custId, outstanding, balance)
	SELECT
		c.custid,
		ISNULL(SUM(CASE WHEN ruben=0 THEN ABS(actual_stake) ELSE 0 END), 0) AS outstanding,
		ISNULL(SUM(CASE WHEN ruben=1 THEN winlost - actual_stake + playercomm ELSE 0 END), 0) AS balance
	FROM bettrans b WITH(NOLOCK)
		INNER JOIN #custInfo c ON b.custid = c.custId
		LEFT JOIN #SportBettype s ON b.bettype = s.bettype
	WHERE 
			(
				(ISNULL(s.RefTable, 0) = 0 AND ruben =0)
				OR ruben <> 0
			)
		AND (
				(CONVERT(DATE, winlostdate) >= @yesterday AND ISNULL(s.RefTable, 0) NOT IN (1,2))
				OR CONVERT(DATE, winlostdate) < @yesterday
			)
	GROUP BY c.custid
	
		-- bettransRnG
	INSERT INTO #BalanceInfo (custId, outstanding, balance)
	SELECT
		custid as custid,
		ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END),0) AS outstanding,
		ISNULL(SUM(CASE WHEN CONVERT(DATE, winlostdate) >= @yesterday AND statusID NOT IN (0, 1) THEN winlost - actual_stake + playercomm ELSE 0 END),0) AS balance
	FROM bettransRnG WITH(NOLOCK)
	WHERE recommend = @Recommend
	GROUP BY custid

		-- bettransLC
	INSERT INTO #BalanceInfo (custId, outstanding, balance)
	SELECT
		custid as custid,
		ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) ELSE 0 END),0) AS outstanding,
		ISNULL(SUM(CASE WHEN CONVERT(DATE, winlostdate) >= @yesterday AND statusID NOT IN (0, 1) THEN winlost - actual_stake + playercomm ELSE 0 END),0) AS balance
	FROM bettransLC WITH(NOLOCK)
	WHERE recommend = @Recommend
	GROUP BY custid

		-- translog
	INSERT INTO #BalanceInfo (custId, outstanding, balance)
	SELECT
		custid,
		ISNULL(SUM(ABS(actual_stake)), 0) AS outstanding,
		0 AS balance
	FROM translog WITH(NOLOCK)
	WHERE recommend = @Recommend
		AND statusID = 0
	GROUP BY custid
	--- End Get Balance Info ---

	--- Get netPosition Info ---
	CREATE TABLE #custNetPosition (custid INT PRIMARY KEY, netPosition MONEY)

	DECLARE @sql VARCHAR(MAX)
	SELECT  @sql = 'SELECT custid, netPosition FROM OPENQUERY(DBTXN, ''SELECT c.custid, ISNULL(SUM(b.Credit - b.Debit), 0) AS netPosition
																		FROM CustDB.dbo.Customer c WITH(NOLOCK)
																			INNER JOIN bodb02.dbo.BalNetPosition b WITH(NOLOCK) ON c.custid = b.custid
																		WHERE c.recommend = ' + CONVERT(VARCHAR(20), @Recommend) + 
																		' GROUP BY c.custid'')'
	INSERT INTO #custNetPosition (custid, netPosition)
	EXEC (@sql)
	--- End Get netPosition Info ---

	--- Return Result ---
	SELECT
		ci.custid, 
		ci.username, 
		ci.givencredit,
		ci.[enabled],
		ci.closed, 
		ci.givencredit+ISNULL(b.balance,0)-ISNULL(b.outstanding,0)+ISNULL(c.netPosition, 0) AS betcredit,
		ISNULL(ci.reject, 0) AS suspended 
	FROM #custInfo ci
		LEFT JOIN (SELECT custId, SUM(balance) AS balance, SUM(outstanding) AS outstanding FROM #BalanceInfo GROUP BY custId) b ON ci.custId = b.custId
		LEFT JOIN #custNetPosition c ON ci.custId = c.custid
	ORDER BY ci.RowNum

	DROP TABLE #SportBettype
	DROP TABLE #BalanceInfo
	DROP TABLE #custNetPosition
	DROP TABLE #custInfo

END

GO
GRANT EXECUTE ON [dbo].[Agm_CustomerSelGivenCreditByAg] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agm_CustomerSelGivenCreditByAg] TO [vnteam] AS [dbo]
GO