/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_SMATurnoverListSel]
	@SportType INT = 1, -- Soccer 
	@LeagueID INT = 0, -- All leagues
	@UsedPercent INT = 40,
	@FromDate DATETIME, 
	@ToDate DATETIME,
	@MoveBetsDay  DATETIME	
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve SMA Turnover list
	DB: DBAGE/bodb02

	Revisions:

	Parameter's explaination: 
	
	Example: EXEC Acc_SMATurnoverListSel @SportType = 1, @LeagueID = 0, @FromDate = '2014-05-10', @ToDate = '2013-05-15', @MoveBetsDay = '2014-12-05'
			 exec Acc_SMATurnoverListSel @FromDate='2014-09-13 00:00:00',
							@LeagueID=0,
							@MoveBetsDay='2014-09-22 00:00:00',
							@SportType=1,@UsedPercent=60,@ToDate='2014-10-07 00:00:00'
*/
SET NOCOUNT ON

IF @Todate <= @MoveBetsDay
BEGIN	
	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,t.HouseTurnover,
			CASE c.RoleID WHEN 4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
			CASE WHEN t.maxturnover = 0 THEN 100 ELSE t.HouseTurnover*100/t.maxturnover END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match14 m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END		
			AND @UsedPercent <= CASE WHEN @UsedPercent <> 0 THEN CASE WHEN t.maxturnover = 0 THEN 100 ELSE CAST((t.HouseTurnover/t.maxturnover*100) AS INT) END ELSE @UsedPercent END
	ORDER BY l.leaguename, t.matchid, PercentageUsed DESC, c.username
END
ELSE IF @FromDate > @MoveBetsDay
BEGIN
	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,t.HouseTurnover,
			CASE c.RoleID WHEN 4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
			CASE WHEN t.maxturnover = 0 THEN 100 ELSE t.HouseTurnover*100/t.maxturnover END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
			AND @UsedPercent <= CASE WHEN @UsedPercent <> 0 THEN CASE WHEN t.maxturnover = 0 THEN 100 ELSE CAST((t.HouseTurnover/t.maxturnover*100) AS INT) END ELSE @UsedPercent END
	ORDER BY l.leaguename, t.matchid, PercentageUsed DESC, c.username
END	
ELSE 
BEGIN
	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,t.HouseTurnover,
		CASE c.RoleID WHEN 4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
		CASE WHEN t.maxturnover = 0 THEN 100 ELSE t.HouseTurnover*100/t.maxturnover END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match14 m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @MoveBetsDay
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
			AND @UsedPercent <= CASE WHEN @UsedPercent <> 0 THEN CASE WHEN t.maxturnover = 0 THEN 100 ELSE CAST((t.HouseTurnover/t.maxturnover*100) AS INT) END ELSE @UsedPercent END
	UNION ALL
	SELECT c.custID, c.username, e.currency, l.leaguename, l.leagueid, t.matchID, m.homeid, m.awayid, m.eventdate, m.eventstatus, t.MaxTurnover, t.TotalTurnover,t.HouseTurnover,
		CASE c.RoleID WHEN 4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
		CASE WHEN t.maxturnover = 0 THEN 100 ELSE t.HouseTurnover*100/t.maxturnover END AS PercentageUsed
	FROM DownlineTurnover_Setting t WITH(NOLOCK) 
		INNER JOIN match m WITH (NOLOCK) ON t.matchid = m.matchid
		INNER JOIN custInfo c WITH (NOLOCK) ON t.custID = c.custid
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE m.sporttype = @SportType AND m.eventdate BETWEEN @MoveBetsDay AND @ToDate
			AND m.leagueid = CASE WHEN @LeagueID = 0 THEN m.leagueid ELSE @LeagueID END
			AND @UsedPercent <= CASE WHEN @UsedPercent <> 0 THEN CASE WHEN t.maxturnover = 0 THEN 100 ELSE CAST((t.HouseTurnover/t.maxturnover*100) AS INT) END ELSE @UsedPercent END
	ORDER BY l.leaguename, t.matchid, PercentageUsed DESC, c.username
END	

