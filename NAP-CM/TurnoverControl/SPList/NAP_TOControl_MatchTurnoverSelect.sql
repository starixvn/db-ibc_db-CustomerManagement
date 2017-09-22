/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE CustDB
GO
    
ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverSelect]
(
	@SportType				INT = 1, 
	@LeagueID				INT = 0,
	@MatchID				INT = 0,
	@UserName				NVARCHAR(50),
	@IsExcludeCompletedEvent BIT = 0,
	@UsedPercent			INT = 40,
	@FromDate				DATETIME, 
	@ToDate					DATETIME,
	@MoveBetsDay			DATETIME
)	
AS
/*
	Created: Don
	Date: 2017-03-23
	Task: Retrieve Super/Master/Agent Turnover List
	DB: DBCUST.CustDB

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
	
	Parameter's explaination: 
	HARDCODE for @PercentLevel
	CASE
			WHEN @UsedPercent >= 100 THEN 10
			WHEN @UsedPercent >= 80 THEN 8
			WHEN @UsedPercent >= 60 THEN 6
			WHEN @UsedPercent >= 40 THEN 4
			ELSE 0
	END
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #MatchList(matchid INT, homeid INT, awayid INT, eventdate DATETIME, eventstatus NVARCHAR(50), leagueid INT)

	DECLARE @PercentLevel TINYINT = 0
	SELECT @PercentLevel = ISNULL((SELECT MAX(PercentLevel) FROM dbo.TOControl_LevelSetting WITH (NOLOCK) WHERE PercentValue <= @UsedPercent),0)
		

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
				AND m.matchid = CASE WHEN @MatchID = 0 THEN m.matchid ELSE @MatchID END
				AND (@IsExcludeCompletedEvent = 0 OR (@IsExcludeCompletedEvent = 1 AND m.eventstatus <> 'completed'))
				
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
				AND m.matchid = CASE WHEN @MatchID = 0 THEN m.matchid ELSE @MatchID END
				AND (@IsExcludeCompletedEvent = 0 OR (@IsExcludeCompletedEvent = 1 AND m.eventstatus <> 'completed'))
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
				AND m.matchid = CASE WHEN @MatchID = 0 THEN m.matchid ELSE @MatchID END
				AND (@IsExcludeCompletedEvent = 0 OR (@IsExcludeCompletedEvent = 1 AND m.eventstatus <> 'completed'))

			UNION ALL

			SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.eventstatus, m.leagueid
			FROM DBAGE.bodb02.dbo.match14 m WITH(NOLOCK)
			WHERE 
				m.eventdate BETWEEN @FromDate AND @MoveBetsDay
				AND m.sporttype = @SportType
				AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
				AND m.matchid = CASE WHEN @MatchID = 0 THEN m.matchid ELSE @MatchID END
				AND (@IsExcludeCompletedEvent = 0 OR (@IsExcludeCompletedEvent = 1 AND m.eventstatus <> 'completed'))
	END	

	/* Get list of Super/Master/Agent turnover */
	;WITH CTE_SettingList AS (
		SELECT 
			t.CustID, t.matchid, t.MaxTurnover, t.TotalTurnover, t.HouseTurnover
			, CASE WHEN t.MaxTurnover = 0 THEN 100 ELSE t.HouseTurnover*100/t.MaxTurnover END AS PercentageUsed
			, t.IsGroupHeadLine
		FROM dbo.TOControl_Setting t WITH(NOLOCK) 
			INNER JOIN dbo.custInfo c WITH (NOLOCK) ON t.custID = c.custid
		WHERE t.PercentLevel >= @PercentLevel
			AND (ISNULL(@UserName,'')='' OR c.username LIKE '%' + @UserName + '%')
			
	)
	SELECT 
			t.CustID, c.username, e.currency, 
			m.leagueid, m.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, 
			t.MaxTurnover, t.TotalTurnover, t.HouseTurnover
			, CASE WHEN t.IsGroupHeadLine = 1 THEN 'Headline'
				   ELSE	CASE c.RoleID WHEN 4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END 
			  END AS Level,
			t.PercentageUsed
	FROM CTE_SettingList t
		INNER JOIN #MatchList m WITH (NOLOCK) ON t.matchID = m.matchid
		INNER JOIN dbo.custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN dbo.exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE @UsedPercent <= t.PercentageUsed
	ORDER BY 
		m.leagueid DESC,
		m.matchid ASC, 
		t.PercentageUsed DESC, 
		c.username ASC

END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_MatchTurnoverSelect] TO [bodbAdminNet]
GO