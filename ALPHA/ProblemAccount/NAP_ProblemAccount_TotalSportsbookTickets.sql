/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_ProblemAccount_TotalSportsbookTickets]
	@CustId				INT
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@MoveBetsDay		SMALLDATETIME
	,@BalanceUpDay		SMALLDATETIME
	,@totalBetTickets	INT = 0 OUTPUT
AS

/*
	Created: 20200205@Percy
	DB: DBAGE.bodb02
	Task: Customer Management - Problem Account - Total Sportsbook tickets (CN88: CS_ProblemAccount_TotalSportsbookTickets)

	Revisions:
		- 20200205@Percy: Initialize SP [RedmineID: #127446]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @FromDate = CONVERT(VARCHAR(10), @FromDate, 120), @ToDate = CONVERT(VARCHAR(10), @ToDate, 120), @totalBetTickets = 0

	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME
	DECLARE @tblWinlostDate TABLE (WinlostDate SMALLDATETIME)

	IF @ToDate > @MoveBetsDay
	BEGIN
		SELECT	@FDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END
				,@TDate = @ToDate

		SELECT @totalBetTickets = @totalBetTickets + COUNT(1)
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.custid = @CustId
			AND b.winlostdate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM dbo.SportBettypeMatrix s WITH (NOLOCK) WHERE b.bettype = s.bettype AND s.ProductID = 1 AND s.RefTable = 0)

		SELECT @totalBetTickets = @totalBetTickets + COUNT(1)
		FROM dbo.translog t WITH (NOLOCK)
		WHERE t.custid = @CustId
			AND t.winlostdate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM dbo.SportBettypeMatrix s WITH (NOLOCK) WHERE t.gameid = s.bettype AND s.ProductID = 1 AND s.RefTable = 3)
	END

	IF @FromDate <= @MoveBetsDay
	BEGIN
		DECLARE @srecommend INT, @mrecommend INT, @recommend INT
		SELECT  @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend FROM dbo.Customer WITH (NOLOCK) WHERE custid = @CustId

		-- sum_winloss
		SELECT	@FDate = CASE WHEN @FromDate < @BalanceUpDay THEN @BalanceUpDay ELSE @FromDate END
				,@TDate = CASE WHEN @ToDate > @MoveBetsDay THEN @MoveBetsDay ELSE @ToDate END

		IF @FDate <= @TDate
		BEGIN
			;WITH CTE_WinlostDate AS
			(
				SELECT @FDate AS WinlostDate
				UNION ALL
				SELECT DATEADD(DAY, 1, WinlostDate)
				FROM CTE_WinlostDate
				WHERE WinlostDate < @TDate
			)
			SELECT @totalBetTickets = @totalBetTickets + ISNULL(SUM(BetCount), 0)
			FROM CTE_WinlostDate wld
				CROSS APPLY (
					SELECT ISNULL(BetCount, 0) AS BetCount
					FROM dbo.sum_winloss s WITH (NOLOCK)
					WHERE wld.WinlostDate = s.winlostdate
						AND s.srecommend = @srecommend
						AND s.mrecommend = @mrecommend
						AND s.recommend = @recommend
						AND s.roleid = 1
						AND s.sporttype = 0
						AND s.bettype = 0
						AND s.custid = @CustId
				) s
			OPTION (MAXRECURSION 0)
		END

		-- sum_winloss_old
		SELECT	@FDate = @FromDate
				,@TDate = CASE WHEN @ToDate >= @BalanceUpDay THEN DATEADD(DAY, -1, @BalanceUpDay) ELSE @ToDate END

		IF @FDate <= @TDate
		BEGIN
			;WITH CTE_WinlostDate AS
			(
				SELECT @FDate AS WinlostDate
				UNION ALL
				SELECT DATEADD(DAY, 1, WinlostDate)
				FROM CTE_WinlostDate
				WHERE WinlostDate < @TDate
			)
			SELECT @totalBetTickets = @totalBetTickets + ISNULL(SUM(BetCount), 0)
			FROM CTE_WinlostDate wld
				CROSS APPLY (
					SELECT ISNULL(BetCount, 0) AS BetCount
					FROM bodb_Summary.dbo.sum_winloss_old s WITH (NOLOCK)
					WHERE wld.WinlostDate = s.winlostdate
						AND s.srecommend = @srecommend
						AND s.mrecommend = @mrecommend
						AND s.recommend = @recommend
						AND s.roleid = 1
						AND s.sporttype = 0
						AND s.bettype = 0
						AND s.custid = @CustId
				) s
			OPTION (MAXRECURSION 0)
		END
	END
END
GO