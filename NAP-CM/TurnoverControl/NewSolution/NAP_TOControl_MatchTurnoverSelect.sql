/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE CustDB
GO
    
ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverSelect]
	@SportType				INT = 1, 
	@LeagueID				INT = 0,
	@UsedPercent			INT = 40,
	@FromDate				DATETIME, 
	@ToDate					DATETIME,
	@MoveBetsDay			DATETIME
AS
/*
	Created: Don
	Date: 2017-03-23
	Task: Retrieve Super/Master/Agent Turnover List
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination: 
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #MatchList(matchid INT, homeid INT, awayid INT, eventdate DATETIME, eventstatus NVARCHAR(50), leagueid INT)

	DECLARE @PercentLevel TINYINT = 0
	SELECT @PercentLevel = 
		CASE
			WHEN @UsedPercent >= 100 THEN 10
			WHEN @UsedPercent >= 80 THEN 8
			WHEN @UsedPercent >= 60 THEN 6
			WHEN @UsedPercent >= 40 THEN 4
			ELSE 0
		END

	/* Get information about needed events */
	IF @Todate <= @MoveBetsDay
	BEGIN
		INSERT INTO #MatchList(matchid, homeid, awayid, eventdate, eventstatus, leagueid)
			SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.eventstatus, m.leagueid
			FROM DBAGE.bodb02.dbo.match14 m WITH(NOLOCK)
			WHERE 
				m.eventdate BETWEEN @FromDate AND @ToDate
				AND m.sporttype = @SportType
				AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END 
	END
	ELSE IF @FromDate > @MoveBetsDay
	BEGIN
		INSERT INTO #MatchList(matchid, homeid, awayid, eventdate, eventstatus, leagueid)
			SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.eventstatus, m.leagueid
			FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
			WHERE 
				m.eventdate BETWEEN @FromDate AND @ToDate
				AND m.sporttype = @SportType
				AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
	END
	ELSE
	BEGIN
		INSERT INTO #MatchList(matchid, homeid, awayid, eventdate, eventstatus, leagueid)
			SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.eventstatus, m.leagueid
			FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
			WHERE 
				m.eventdate BETWEEN @MoveBetsDay AND @ToDate
				AND m.sporttype = @SportType
				AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END

			UNION ALL

			SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.eventstatus, m.leagueid
			FROM DBAGE.bodb02.dbo.match14 m WITH(NOLOCK)
			WHERE 
				m.eventdate BETWEEN @FromDate AND @MoveBetsDay
				AND m.sporttype = @SportType
				AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
	END	

	/* Get list of Super/Master/Agent turnover */
	;WITH CTE_SettingList AS (
		SELECT 
			t.CustID, t.matchid, t.MaxTurnover, t.TotalTurnover, t.HouseTurnover,
			CASE WHEN t.MaxTurnover = 0 THEN 100 ELSE t.HouseTurnover*100/t.MaxTurnover END AS PercentageUsed
		FROM dbo.TOControl_Setting t WITH(NOLOCK) 
		WHERE t.PercentLevel >= @PercentLevel
	)
	SELECT 
			t.CustID, c.username, e.currency, 
			m.leagueid, m.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, 
			t.MaxTurnover, t.TotalTurnover, t.HouseTurnover,
			CASE c.RoleID WHEN 4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END AS Level,
			t.PercentageUsed
	FROM CTE_SettingList t
		INNER JOIN #MatchList m WITH (NOLOCK) ON t.matchID = m.matchid
		INNER JOIN dbo.custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN dbo.exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE 
		@UsedPercent <=	t.PercentageUsed
	ORDER BY 
		m.matchid ASC, 
		t.PercentageUsed DESC, 
		c.username ASC

END
GO