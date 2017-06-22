USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_ExchangeRateSelInvalid]
	@FromDate	DATETIME = NULL OUTPUT,
	@ToDate		DATETIME = NULL	
AS
/*
	Created by: 2008@[]
	Task: Show invalid exchange rate 
	DB: DBPOLICY.bodb02
	
	Revisions:
		- 20100105@Jamie: Get currency from Cache
		- 20170307@Percy: Add Forex Gain/Loss (RM) column [RedmineID: #71954]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @BalanceUpDay DATETIME, @tmpFromDate DATETIME, @tmpToDate DATETIME
	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM bettrans WITH(NOLOCK)
	WHERE bettype = 20000 AND matchid = 0 AND custid = 3

	IF @FromDate IS NULL OR @ToDate IS NULL
		SELECT	@ToDate = CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE(), 120)),
				@FromDate = DATEADD(DAY, -1, @ToDate)
	ELSE
	BEGIN
		SELECT @FromDate = CONVERT(DATETIME, CONVERT(VARCHAR(10), @FromDate, 120))--Reset into 00:00:00
		SELECT @ToDate = CONVERT(DATETIME, CONVERT(VARCHAR(10), @ToDate, 120))--Reset into 00:00:00
		SELECT @ToDate = DATEADD(DAY, 1, @ToDate)
	END

	CREATE TABLE #RefNo (RefNo BIGINT)
	CREATE TABLE #Transfer (RefNo BIGINT, custId INT, GainLoss MONEY) 
	CREATE TABLE #InvalidTransfer (RefNo BIGINT, GainLoss MONEY)

	INSERT INTO #RefNo (RefNo)
	SELECT RefNo FROM dbo.Acc_ExchangeRate_InvalidTransfer WITH (NOLOCK)
	WHERE TransDate >= @FromDate AND TransDate < @ToDate
		AND IsDeleted = 0

	IF @FromDate < @BalanceUpDay
	BEGIN
		IF @ToDate >= @BalanceUpDay
			SELECT @tmpToDate = @BalanceUpDay
		ELSE
			SELECT @tmpToDate = DATEADD(DAY, -1, @ToDate)

		INSERT INTO #Transfer(RefNo, custId, GainLoss)
		SELECT fi.RefNo, fi.custid, fi.winlost - fi.actual_stake
		FROM DBSUM.bodb_Summary.dbo.transfer_fi fi WITH (NOLOCK)
		WHERE fi.winlostdate BETWEEN @FromDate AND @tmpToDate
			AND EXISTS (SELECT 1 FROM #RefNo r WHERE r.RefNo = fi.RefNo)
			AND fi.bettype = 21003
			AND fi.custid IN (7214120, 7213887, 7214025) -- PHL-Forex G/(L), VNM-Forex G/(L), MYS-Forex G/(L)
			AND fi.currency = 2
	END

	IF @ToDate >= @BalanceUpDay
	BEGIN
		IF @FromDate < @BalanceUpDay
			SELECT @tmpFromDate = @BalanceUpDay
		ELSE
			SELECT @tmpFromDate = @FromDate

		SELECT @tmpToDate = DATEADD(DAY, -1, @ToDate)

		INSERT INTO #Transfer(RefNo, custId, GainLoss)
		SELECT b.RefNo, b.custid, b.winlost - b.actual_stake
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.winlostdate BETWEEN @tmpFromDate AND @tmpToDate
			AND EXISTS (SELECT 1 FROM #RefNo r WHERE r.RefNo = b.RefNo)
			AND b.bettype = 21003
			AND b.custid IN (7214120, 7213887, 7214025) -- PHL-Forex G/(L), VNM-Forex G/(L), MYS-Forex G/(L)
			AND b.currency = 2
	END

	;WITH CTE_2 AS
	(
		SELECT RefNo, custid, COUNT(1) AS betcount
		FROM #Transfer
		GROUP BY RefNo, custid
		HAVING COUNT(1) = 2
	)
	INSERT INTO #InvalidTransfer (RefNo, GainLoss)
	SELECT t.RefNo, SUM(t.GainLoss)
	FROM #Transfer t
	WHERE EXISTS (SELECT 1 FROM CTE_2 c WHERE c.RefNo = t.RefNo AND c.custid = t.custid)
	GROUP BY t.RefNo

	;WITH CTE_3 AS
	(
		SELECT RefNo, custid, COUNT(1) AS betcount
		FROM #Transfer
		GROUP BY RefNo, custid
		HAVING COUNT(1) = 3
	)
	,CTE1 AS
	(
		SELECT t.RefNo, t.GainLoss,
			COUNT(1) OVER(PARTITION BY t.RefNo, ABS(t.GainLoss)) AS betcount,
			ROW_NUMBER() OVER(PARTITION BY t.RefNo, ABS(t.GainLoss) ORDER BY ABS(t.GainLoss)) AS RowNum
		FROM #Transfer t
		WHERE EXISTS (SELECT 1 FROM CTE_3 c WHERE c.RefNo = t.RefNo AND c.custid = t.custid)
	)
	,CTE2 AS
	(
		SELECT RefNo, GainLoss, betcount FROM CTE1
		WHERE RowNum = 1
	)
	INSERT INTO #InvalidTransfer (RefNo, GainLoss)
	SELECT c1.RefNo, SUM(CASE WHEN c1.GainLoss > 0 THEN c1.GainLoss - ABS(c2.GainLoss) ELSE c1.GainLoss + ABS(c2.GainLoss) END) AS GainLoss
	FROM CTE2 c1
		INNER JOIN CTE2 c2 ON c1.RefNo = c2.RefNo AND c1.betcount = 1 AND c2.betcount = 2
	GROUP BY c1.RefNo

	SELECT	a.transdate, 
			c.username AS creator, 
			f.username AS fromCust, 
			t.username AS tocust, 
			a.fromexchangeid,
			a.toexchangeid,
			a.minExRate,
			a.maxExRate, 
			a.exRate AS inputExRate,
			a.Amount,
			it.GainLoss
	FROM	Acc_ExchangeRate_InvalidTransfer a WITH (NOLOCK)
			INNER JOIN Custinfo c WITH (NOLOCK) ON a.userid = c.custid 
			INNER JOIN Custinfo f WITH (NOLOCK) ON a.fromcust = f.custid 
			INNER JOIN Custinfo t WITH (NOLOCK) ON a.tocust = t.custid
			LEFT JOIN #InvalidTransfer it ON a.RefNo = it.Refno
	WHERE	TransDate >= @FromDate and TransDate < @ToDate and isDeleted = 0
	ORDER BY a.transdate

	DROP TABLE #RefNo
	DROP TABLE #InvalidTransfer
END
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeRateSelInvalid] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeRateSelInvalid] TO [VNTeam]
GO