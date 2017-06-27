ALTER PROCEDURE	dbo.Age_CustomerSelWinlimitInfo
					@CustId			INT
				,	@BetType		SMALLINT
				,	@mrecommend		INT				= 0
				,	@recommend		INT				= 0
				,	@username		NVARCHAR(50)	= ''
				,	@PageSize		INT				= 500
				,	@PageIndex		INT				= 1
				,	@TotalRows		INT				= 0			OUTPUT
AS
/*
	Create:		20150715@Patrick
	Task:		Member win limit of Super
	DB:			DBTXN/CustDB
	Original:	Age_CustomerSelCreditBalanceList_SAg
	
	Revisions:
		- 20160118@Patrick:	inlcude ticket from bettransRnG table
		- 20160219@Billy:	Add filter by username - apply for AllBet - [Redmine: #52268]
		- 20160318@Billy:	Include tickets from [bettransLC] table - [Redmine: #54306]
		- 20170116@Helen:  Alpha - Member Win Limit report - Current Win Loss amount and Balance show zero while member actually has tickets on RNG - [Redmine:70397]

	
	Param's Explanation:
		- @CustID: SAgentID
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @RoleId TINYINT, @RowCount INT, @RowStart INT, @RowEnd INT, @srecommend INT
		, @yesterday SMALLDATETIME

	SELECT @PageIndex = @PageIndex - 1
		, @RowStart = @PageSize * @PageIndex + 1
		, @RowEnd = @RowStart + @PageSize - 1

	IF	@username = ''
		SELECT	@username = NULL

	CREATE TABLE #MemberBalance (CustId INT, Balance MONEY)

	SELECT @RoleId = RoleId, @srecommend = srecommend
	FROM dbo.CustInfo c WITH(NOLOCK)
	WHERE CustId = @CustId

	SELECT @yesterday = CAST(DATEADD(dd, -1, GETDATE()) AS DATE)
	
	CREATE TABLE #Cust_tmp (CustID INT PRIMARY KEY,rownumber INT)
	
	CREATE TABLE #Cust_Downline (CustID INT PRIMARY KEY,enabled BIT, closed BIT,reject BIT, username NVARCHAR(50))
	
	IF @RoleId = 4
	BEGIN
		INSERT INTO #Cust_Downline(CustId,enabled,closed,reject,username)
		SELECT c.custid,c.enabled, c.closed, ISNULL(c.reject, 0), c.username
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.srecommend = @CustId
			AND roleid = 1
			AND c.mrecommend = @mrecommend
			AND (@recommend = 0 OR (@recommend <> 0 AND c.recommend = @recommend))
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND c.Enabled = 1
			
	END
	ELSE IF @RoleId = 3
	BEGIN
		INSERT INTO #Cust_Downline(CustId,enabled,closed,reject,username)
		SELECT c.custid,c.enabled, c.closed, ISNULL(c.reject, 0), c.username
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.mrecommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend 
			AND c.recommend = @recommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND c.Enabled = 1
		
	END
	ELSE IF @RoleId = 2
	BEGIN
		INSERT INTO #Cust_Downline(CustId,enabled,closed,reject,username)
		SELECT c.custid,c.enabled, c.closed, ISNULL(c.reject, 0), c.username
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.recommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND c.Enabled = 1
	END
	
	
	 DECLARE @isTest BIT = 0
	 SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	 
	 CREATE TABLE #SportBettype (ProductID INT, Bettype INT,EventType INT, SubProduct VARCHAR(500), RefTable TINYINT, CasinoType TINYINT)
	 INSERT INTO #SportBettype ( ProductID, Bettype, EventType, SubProduct, RefTable, CasinoType)
	 SELECT ProductID,
			Bettype,
			EventType,
			SubProduct,
			RefTable,
			CasinoType
	FROM bodb02.dbo.f_SportBettypeMatrix_Sel (0, 0, 0, 2, '', '', @isTest)
	WHERE RefTable IN (1,2) -- IN bettransRNG & BettransLC
    
	INSERT INTO #Cust_tmp (CustId,rownumber)
	SELECT CustID, rownumber
	FROM (
		SELECT CUSTID, ROW_NUMBER() OVER (ORDER BY a.enabled DESC, a.closed, a.reject, a.username) AS RowNumber
		FROM #Cust_Downline a
		) AS T
	WHERE T.RowNumber BETWEEN @RowStart AND @RowEnd	
	
	
	INSERT INTO #MemberBalance(CustId, Balance)
	SELECT c.custid, ISNULL(SUM(CASE WHEN s.Bettype IS NOT NULL AND winlostdate >= @yesterday THEN 0
							ELSE winlost - actual_stake + playercomm END), 0) AS Balance
	FROM #Cust_tmp c WITH(NOLOCK)
		INNER LOOP JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON c.CustId = b.CustId
		LEFT JOIN #SportBettype s ON s.bettype = b.Bettype
	
	WHERE b.statusID NOT IN (0,1,101,102)	
	GROUP BY c.custid

	--get data from bettransRnG table within 2 days: today & yesterday
	UNION ALL
	SELECT c.custid, SUM(winlost - actual_stake + playercomm) AS Balance
	FROM #Cust_tmp c WITH(NOLOCK)
		INNER JOIN bodb02.dbo.bettransRNG b WITH(NOLOCK) ON c.CustId = b.CustId 
	WHERE  b.statusID NOT IN (0,1,101,102)	AND winlostdate >= @yesterday	
	GROUP BY c.custid
	
	-- 20160318@Billy: Get tickets from [bettransLC] table within 2 days: today & yesterday
	UNION ALL
	SELECT	ci.custid, SUM(blc.winlost - blc.actual_stake + blc.playercomm) AS Balance
	FROM	#Cust_tmp AS ci WITH (NOLOCK)
		INNER JOIN	bodb02.dbo.bettransLC AS blc WITH (NOLOCK)	ON	blc.custid = ci.custid 	
	WHERE	blc.statusID NOT IN (0, 1, 101, 102) AND	blc.winlostdate >= @yesterday
	GROUP BY ci.custid
	
	OPTION (MAXDOP 8)
	
	--Calc total rows
	SELECT @TotalRows = COUNT(1)
	FROM #Cust_Downline

	CREATE TABLE #TempData(RowNumber INT, CustId INT, Balance MONEY)
	INSERT INTO #TempData(RowNumber, CustId, Balance)
	SELECT 	a.rownumber,a.CustId
			, ISNULL(SUM(b.Balance),0) AS Balance
		FROM #Cust_tmp a
			LEFT JOIN #MemberBalance b ON b.CustId = a.CustId
	GROUP BY a.CustId,a.rownumber
	
	SELECT bc.RowNumber, bc.Balance, bc.CustId, CreditBalance, DebitBalance
	FROM (
		SELECT d.RowNumber, d.CustId, d.Balance
			, ISNULL(SUM(bc.Balance),0)  AS CreditBalance
		FROM #TempData d
			LEFT JOIN bodb02.dbo.BalanceCreditGame bc WITH(NOLOCK) ON d.CustId = bc.custid AND bc.bettype = @BetType 
		GROUP BY d.RowNumber, d.CustId, d.Balance
	)bc
	INNER JOIN (
		SELECT d.RowNumber, d.CustId, d.Balance
			, ISNULL(SUM(bd.Balance),0)  AS DebitBalance
		FROM #TempData d
			LEFT JOIN bodb02.dbo.BalanceDebitGame bd WITH(NOLOCK) ON d.CustId = bd.custid AND bd.bettype = @BetType
		GROUP BY d.RowNumber, d.CustId, d.Balance
	)bd ON bc.CustId = bd.CustId
	ORDER BY RowNumber

	DROP TABLE #MemberBalance
	DROP TABLE #TempData
	DROP TABLE #Cust_tmp
	DROP TABLE #SportBettype
	DROP TABLE #Cust_Downline
	
END

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelWinlimitInfo] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelWinlimitInfo] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelWinlimitInfo] TO vnteam