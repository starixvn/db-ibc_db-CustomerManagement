/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,wsv_nap" isFunction="0" isNested="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[CS_ProblemAccount_TotalSportsbookTickets]
	@CustId				INT
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@MoveBetsDay		SMALLDATETIME
	,@totalBetTickets	INT = 0 OUTPUT
AS

/*
	Created: 20190822@Percy
	DB: DBAGE.bodb02
	Task: Customer Management - CN88 - Problem Account - Total Sportsbook tickets

	Revisions:
		- 20190822@Percy: Initialize SP [RedmineID: #116814]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @FromDate = CONVERT(VARCHAR(10), @FromDate, 120), @ToDate = CONVERT(VARCHAR(10), @ToDate, 120), @totalBetTickets = 0

	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME

	IF @ToDate > @MoveBetsDay
	BEGIN
		SELECT	@FDate = CASE WHEN @FromDate <= @MoveBetsDay THEN DATEADD(DAY, 1, @MoveBetsDay) ELSE @FromDate END
				,@TDate = @ToDate

		SELECT @totalBetTickets = @totalBetTickets + COUNT(1)
		FROM dbo.bettrans b WITH (NOLOCK)
		WHERE b.custid = @CustId
			AND b.winlostdate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM dbo.CS_SportBettypeMatrix s WITH (NOLOCK) WHERE b.bettype = s.bettype AND s.ProductID = 1 AND s.RefTable = 0)

		SELECT @totalBetTickets = @totalBetTickets + COUNT(1)
		FROM dbo.translog t WITH (NOLOCK)
		WHERE t.custid = @CustId
			AND t.winlostdate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM dbo.CS_SportBettypeMatrix s WITH (NOLOCK) WHERE t.gameid = s.bettype AND s.ProductID = 1 AND s.RefTable = 3)
	END

	IF @FromDate <= @MoveBetsDay
	BEGIN
		SELECT	@FDate = @FromDate
				,@TDate = CASE WHEN @ToDate > @MoveBetsDay THEN @MoveBetsDay ELSE @ToDate END

		SELECT @totalBetTickets = @totalBetTickets + ISNULL(SUM(Wagers), 0)
		FROM bodb_Summary.dbo.CS_SumWinloss s WITH (NOLOCK)
		WHERE s.custid = @CustId
			AND s.winlostdate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM dbo.CS_SportBettypeMatrix s WITH (NOLOCK) WHERE s.bettype = s.bettype AND s.ProductID = 1)

		SELECT @totalBetTickets = @totalBetTickets + ISNULL(SUM(Wagers), 0)
		FROM bodb_Summary.dbo.CS_SumCancelled s WITH (NOLOCK)
		WHERE s.custid = @CustId
			AND s.winlostdate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM dbo.CS_SportBettypeMatrix s WITH (NOLOCK) WHERE s.bettype = s.bettype AND s.ProductID = 1)
	END
END
GO