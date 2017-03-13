/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_SMATurnoverLeagueSel]  
 @SportType INT,   
 @FromDate DATETIME,   
 @ToDate DATETIME,  
 @MoveBetsDay  DATETIME
AS  
/*  
 Created: Elodie  
 Date: 20130515  
 Task : Retrieve league by sport and eventdate  
 DB: DBAGE/bodb02  
  
 Revisions:  
  
 Parameter's explaination:   
	@MoveBetDate = NULL: used for Add SMA Turnover
				 <> NULL: Used for list SMA Turnover
 Example: EXEC Acc_SMATurnoverLeagueSel @SportType = 1, @FromDate = '2013-05-10', @ToDate = '2013-05-15', @MoveBetsDay = '2013-05-05'  
   
*/  
SET NOCOUNT ON  
  
DECLARE @League AS TABLE (LeagueID INT, LeagueName NVARCHAR(200))  

IF @MoveBetsDay IS NULL --only get data from match, but match14
BEGIN
	INSERT INTO @League (LeagueID, LeagueName)  
	SELECT DISTINCT l.leagueid, l.leaguename  
	FROM League l WITH(NOLOCK)   
	INNER JOIN match m WITH (NOLOCK) ON l.leagueid = m.leagueid 
	WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate and eventstatus <> 'completed' and matchcode not like '%hedge%'
END
ELSE
BEGIN
	IF @Todate <= @MoveBetsDay
	BEGIN  
	 INSERT INTO @League (LeagueID, LeagueName)  
	 SELECT DISTINCT l.leagueid, l.leaguename  
	 FROM League l WITH(NOLOCK)   
	  INNER JOIN match14 m WITH (NOLOCK) ON l.leagueid = m.leagueid  
	 WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate  
	END  
	ELSE IF @FromDate > @MoveBetsDay  
	BEGIN  
	 INSERT INTO @League (LeagueID, LeagueName)  
	 SELECT DISTINCT l.leagueid, l.leaguename  
	 FROM League l WITH(NOLOCK)   
	  INNER JOIN match m WITH (NOLOCK) ON l.leagueid = m.leagueid  
	 WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @ToDate  
	END  
	ELSE  
	BEGIN  
	 INSERT INTO @League (LeagueID, LeagueName)  
	 SELECT DISTINCT l.leagueid, l.leaguename  
	 FROM League l WITH(NOLOCK)   
	  INNER JOIN match14 m WITH (NOLOCK) ON l.leagueid = m.leagueid  
	 WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @FromDate AND @MoveBetsDay  
	   
	 INSERT INTO @League (LeagueID, LeagueName)  
	 SELECT DISTINCT l.leagueid, l.leaguename  
	 FROM League l WITH(NOLOCK)   
	  INNER JOIN match m WITH (NOLOCK) ON l.leagueid = m.leagueid  
	 WHERE l.sporttype = @SportType AND m.eventdate BETWEEN @MoveBetsDay AND @ToDate  
	END  
END
  
SELECT DISTINCT leagueid, leaguename  
FROM @League  
ORDER BY leaguename ASC  

