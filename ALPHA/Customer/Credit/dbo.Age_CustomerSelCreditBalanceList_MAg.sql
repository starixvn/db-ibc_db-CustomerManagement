USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelCreditBalanceList_MAg]
	@CustID		INT,
	@PageSize	INT = 500,
	@PageIndex	INT = 1,
	@Username	VARCHAR(30) = NULL,
	@Enabled	BIT = NULL,
	@Closed		BIT = NULL,
	@Suspended	BIT = NULL,
	@TotalPages INT = 0 OUTPUT
AS 
/*
Task : Credit/Balance of Master Agent
DB: DB052.bodb02
Original: CustAccountSelCreditList_MAg_1

Revisions:
    - 20060222: remove refno  
	- 20060320: split table Customer
	- 20080102@Vinh: add yesterday balance column
	- 20090212@Phuc: paging
	- 20090214@AnhPham: added getting data by username and status
	- 20090710@Phuc: unhide IP for TB currency.
	- 20090812@Phuc: add new filter enabled.
	- 20110516@Johnson: Apply new arrange bettype
	- 20110617@Amy: modify to convert NULL for lastlogged
	- 20110823@Sophia: Count Negative stake as positive turnover
	- 20140304@Kathy: modify formula of Outstanding amount to be calculated based on table Bettrans and TransLog [Redmine:#11550]
	- 20150707@Jim: exclude Metric Gaming running ticket from bettrans (Feature #38789)
	- 20151222@Percy: exclude Cockfighting running ticket from bettrans [Redmine: #48601]
	- 20160112@Percy: Expand new bettype for RNG Casino [Redmine: #48283]
	- 20160222@Percy: Change formula when calculating bet credit [Redmine: #52653]
	- 20160215@Percy: Support AllBet Live Casino [Redmine: #50605]
	- 20160322@Percy:
		1. Change formula turnover [Redmine: #32974]
		2. Remove @ABSDate
	- 20160413@Percy: Support Voidbridge single wallet [Redmine: #55259]
	- 20161028@Percy: Support Fishing World [RedmineID: #65731]
	
Param's Explanation:
• @CustID: MAgentID
*/

SET NOCOUNT ON

DECLARE @isTest BIT
SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)

CREATE TABLE #SportBettype (bettype INT, RefTable TINYINT)
INSERT INTO #SportBettype (bettype, RefTable)
SELECT bettype, RefTable FROM dbo.f_SportBettypeMatrix_Sel(0, 0, 0, 2, '', '', @isTest)

DECLARE /* @ABSDate DATETIME,*/
		@today DATE,
		@yesterday DATE

-- SET @ABSDate = '2011-09-01'
SELECT @today = CONVERT(DATE, GETDATE())
SELECT @yesterday = DATEADD(DD, -1, @today)	

DECLARE @RowCount INT, @RowStart INT, @RowEnd INT
SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

CREATE TABLE #tmp_customer
(
	[custid]		INT PRIMARY KEY,
	[enabled]		BIT,
	[username]		VARCHAR(30),
	[iplogin]		NVARCHAR(20) NULL,
	[closed]		BIT,
	[suspended]		BIT,
	[firstname]		NVARCHAR(50) NULL,
	[lastname]		NVARCHAR(50) NULL,
	[credit]		MONEY NULL,
	[lastlogged]	SMALLDATETIME NULL,
	[usedCredit]	MONEY NULL
)

CREATE TABLE #balance  
(
	custid		INT PRIMARY KEY,
	outstanding MONEY,		
	balance		MONEY,
	turnover	MONEY
)

;WITH rt AS
(
	SELECT recommend AS custid,
		-- ISNULL(SUM(case when ruben=0 then CASE WHEN winlostdate >= @ABSDate THEN ABS(actual_stake) ELSE actual_stake END * apositiontaking else 0 end),0) AS outstanding,
		ISNULL(SUM(CASE WHEN ruben = 0 THEN ABS(actual_stake) * apositiontaking ELSE 0 END), 0) AS outstanding,
		ISNULL(SUM(CASE WHEN custid = recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END), 0) AS balance,
		-- ISNULL(SUM(case when matchid > 0 then CASE WHEN winlostdate >= @ABSDate THEN ABS(actual_stake) ELSE actual_stake END else 0 end), 0) as turnover
		ISNULL(SUM(CASE WHEN matchid > 0 THEN ABS(stake) ELSE 0 END), 0) AS turnover
	FROM  bettrans WITH (NOLOCK)
	WHERE mrecommend = @CustID
		AND (
				(bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable <> 0) AND ruben =0)
				OR ruben <> 0
			)
		AND (
				(CONVERT(DATE, winlostdate) >= @yesterday AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN(0,3)))
				OR CONVERT(DATE, winlostdate) < @yesterday
			)
	GROUP BY recommend
	UNION ALL
	SELECT recommend AS custid,
		-- ISNULL(SUM(CASE WHEN winlostdate >= @ABSDate THEN ABS(actual_stake) ELSE actual_stake END * apositiontaking),0) AS outstanding, 
		ISNULL(SUM(ABS(actual_stake) * apositiontaking),0) AS outstanding, 
		0 balance,
		0 turnover
	FROM  translog WITH (NOLOCK)
	WHERE mrecommend = @CustID
		AND statusid = 0
	GROUP BY recommend
	UNION ALL
	SELECT
		recommend AS custid,
		ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) * apositiontaking ELSE 0 END),0) outstanding, 
		ISNULL(SUM(CASE WHEN statusID NOT IN (0, 1) THEN CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END),0) AS balance,
		ISNULL(SUM(ABS(stake)), 0) AS turnover
	FROM  bettransRNG WITH (NOLOCK)
	WHERE mrecommend = @CustID
		--AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
		AND (
				statusID IN (0, 1)
				OR (statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
			)
	GROUP BY recommend
	UNION ALL
	SELECT
		recommend AS custid,
		ISNULL(SUM(CASE WHEN statusID IN (0, 1) THEN ABS(actual_stake) * apositiontaking ELSE 0 END),0) outstanding, 
		ISNULL(SUM(CASE WHEN statusID NOT IN (0, 1) THEN CASE WHEN custid=recommend THEN winlost-actual_stake ELSE awinlost+comm-playercomm END ELSE 0 END),0) AS balance,
		ISNULL(SUM(ABS(stake)), 0) AS turnover
	FROM  bettransLC WITH (NOLOCK)
	WHERE mrecommend = @CustID
		--AND gameID BETWEEN 2401 AND 2499
		AND (
				statusID IN (0, 1)
				OR (statusID NOT IN (0, 1) AND CONVERT(DATE, winlostdate) >= @yesterday)
			)
	GROUP BY recommend
)
INSERT INTO #balance
SELECT custid,
	SUM(outstanding),
	SUM(balance),
	SUM(turnover)
FROM rt
GROUP BY custid

CREATE TABLE #today_balance
(
	custid	INT PRIMARY KEY,
	balance MONEY
)

;WITH today_balance AS (
	SELECT recommend AS custid,	SUM(awinlost+comm-playercomm) AS balance
	FROM   bettrans with (NOLOCK)
	WHERE  mrecommend = @CustID AND ruben = 1 AND bettype < 19001 AND bettype NOT IN (SELECT bettype FROM #SportBettype WHERE RefTable NOT IN(0,3))
		AND CONVERT(DATE, winlostdate) = @today
	GROUP BY recommend
	UNION ALL
	SELECT recommend AS custid,	SUM(awinlost+comm-playercomm) AS balance
	FROM   bettransRNG with (NOLOCK)
	WHERE  mrecommend = @CustID AND statusID NOT IN (0, 1) --AND (gameID BETWEEN 2101 AND 2399 OR gameID BETWEEN 4001 AND 7999)
		AND CONVERT(DATE, winlostdate) = @today
	GROUP BY recommend
	UNION ALL
	SELECT recommend AS custid,	SUM(awinlost+comm-playercomm) AS balance
	FROM   bettransLC with (NOLOCK)
	WHERE  mrecommend = @CustID AND statusID NOT IN (0, 1) --AND gameID BETWEEN 2401 AND 2499
		AND CONVERT(DATE, winlostdate) = @today
	GROUP BY recommend
)
INSERT INTO #today_balance
SELECT	custid, SUM(balance) AS balance
FROM	today_balance
GROUP BY custid

SET @Username = ISNULL(@Username, '')
--Filter user
IF @Username = ''
	INSERT INTO #tmp_customer 
	SELECT	c.custid,
			ci.enabled,
			c.username,
			c.iplogin,
			ci.closed,
			ISNULL(ci.reject, 0) AS suspended,
			c.firstname,
			c.lastname,
			ci.credit,
			c.lastlogged,
			(SELECT SUM(credit) FROM custInfo WITH(NOLOCK) WHERE roleid = 1 AND recommend = ci.custid) AS usedCredit
	FROM	CustInfo AS ci WITH (NOLOCK, INDEX = ix_custinfo)
		INNER JOIN Customer AS c (nolock) ON ci.custid = c.custid
	WHERE	ci.roleid = 2
		AND ci.mrecommend=@CustID 
		AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
		and	isnull(ci.closed,0) = case when @Suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end
		and isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@Suspended, isnull(ci.reject, 0))end
ELSE
	INSERT INTO #tmp_customer 
	SELECT 
		c.custid, ci.enabled, c.username, c.iplogin, ci.closed, isnull(ci.reject,0) as suspended, c.firstname, c.lastname, ci.credit, c.lastlogged,
		(SELECT SUM(credit) FROM custInfo WITH(NOLOCK) WHERE roleid = 1 AND recommend = ci.custid) AS usedCredit
	FROM
		CustInfo as ci with (NOLOCK,index=ix_custinfo) inner join Customer c (nolock) on ci.custid = c.custid
	WHERE 
		ci.roleid=2 and ci.mrecommend=@CustID and ci.username like '%' + @Username + '%' 
		AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
		and	isnull(ci.closed,0) = case when @Suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end
		and isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@Suspended, isnull(ci.reject, 0))end

IF @TotalPages = 0
BEGIN
	SELECT 
		@TotalPages = count(1),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize>0 then 1 else 0 end
	FROM
		#tmp_customer
END

SELECT * FROM 
(
	SELECT ROW_NUMBER() OVER (ORDER BY c.enabled desc, c.closed, suspended, c.username) as RowNumber,
		c.username,c.enabled,
		isnull(c.iplogin, '')as iplogin, 
		c.custid, 		
		c.closed closed,		
		suspended,
		c.firstname, 
		c.lastname, 
		isnull(balance.outstanding,0) AS outstanding, 
		isnull(balance.balance,0) AS balance, 
		isnull(balance.balance,0) - isnull(today_balance.balance,0) yesterday_balance,
		isnull(c.credit,0) - isnull(c.usedCredit,0) betCredit,
		isnull(balance.turnover,0) AS turnover,
		isnull(c.credit,0) credit,		
		CONVERT(nvarchar(30), c.lastlogged, 121) as lastlogged
	FROM #tmp_customer c
		LEFT JOIN #balance AS balance ON c.custid = balance.custid 
		LEFT JOIN #today_balance AS today_balance on c.custid = today_balance.custid 
		--Members'Bet is settled today @Phuong20080930 
)a
WHERE a.RowNumber BETWEEN @RowStart AND @RowEND

drop table #balance
drop table #today_balance
drop table #tmp_customer
DROP TABLE #SportBettype
GO

GRANT EXECUTE ON [dbo].[Age_CustomerSelCreditBalanceList_MAg] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Age_CustomerSelCreditBalanceList_MAg] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelCreditBalanceList_MAg] TO [vnteam] AS [dbo]
GO