/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_LeagueSelect]
	@SportType INT,   
	@FromDate DATETIME,   
	@ToDate DATETIME,  
	@MoveBetsDay DATETIME
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of leagues
	DB: DBAGE.bodb02

	Revisions:

	Parameter's explaination:
		@MoveBetDate	= NULL		: used for Add SMA Turnover
						<> NULL		: Used for list SMA Turnover
*/
BEGIN
	SET NOCOUNT ON  
  
	DECLARE @League AS TABLE (LeagueID INT, LeagueName NVARCHAR(200))  

	IF @MoveBetsDay IS NULL --only get data from match, but match14
	BEGIN
		INSERT INTO @League (LeagueID, LeagueName)  
			SELECT DISTINCT l.leagueid, l.leaguename  
			FROM dbo.League l WITH(NOLOCK)   
				INNER JOIN dbo.match m WITH (NOLOCK) ON l.leagueid = m.leagueid 
			WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate and eventstatus <> 'completed' and matchcode not like '%hedge%'
	END
	ELSE
	BEGIN
		IF @Todate <= @MoveBetsDay
		BEGIN  
			INSERT INTO @League (LeagueID, LeagueName)  
				SELECT DISTINCT l.leagueid, l.leaguename  
				FROM dbo.League l WITH(NOLOCK)   
					INNER JOIN dbo.match14 m WITH (NOLOCK) ON l.leagueid = m.leagueid  
				WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate  
		END  
		ELSE IF @FromDate > @MoveBetsDay  
		BEGIN  
			INSERT INTO @League (LeagueID, LeagueName)  
				SELECT DISTINCT l.leagueid, l.leaguename  
				FROM dbo.League l WITH(NOLOCK)   
					INNER JOIN dbo.match m WITH (NOLOCK) ON l.leagueid = m.leagueid  
				WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate  
		END  
		ELSE  
		BEGIN  
			INSERT INTO @League (LeagueID, LeagueName)  
				SELECT DISTINCT l.leagueid, l.leaguename  
				FROM dbo.League l WITH(NOLOCK)   
					INNER JOIN dbo.match14 m WITH (NOLOCK) ON l.leagueid = m.leagueid  
				WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @MoveBetsDay  
	   
			INSERT INTO @League (LeagueID, LeagueName)  
				SELECT DISTINCT l.leagueid, l.leaguename  
				FROM dbo.League l WITH(NOLOCK)   
					INNER JOIN dbo.match m WITH (NOLOCK) ON l.leagueid = m.leagueid  
				WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @MoveBetsDay AND @ToDate  
		END  
	END
  
	SELECT DISTINCT leagueid
	FROM @League

END
GO