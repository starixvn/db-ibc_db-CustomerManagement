/*	
	Created: 20170407@Elodie
	Task: Initialize data for TO Control setting
	DB: DBCUST/CustDB
*/

USE CustDB
GO
--DELETE FROM TOControl_GlobalSetting

CREATE TABLE #CustList (CustID INT PRIMARY KEY, MaxTurnOver MONEY)

DECLARE @MaxTurnover MONEY = 200000
----Get the affected customer list
--SELECT c.custid, c.username, c.site, e.currency, e.code, c.roleid, gs.MaxTurnOver
--FROM dbo.TOControl_GlobalSetting gs WITH (NOLOCK)
--	INNER JOIN dbo.Customer c WITH (NOLOCK) ON gs.custid = c.custid
--	INNER JOIN Exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
--WHERE site = '789y' AND roleid <> 1 AND gs.MaxTurnOver < @MaxTurnover 
--ORDER BY c.username

--3164 affected rows
INSERT INTO #CustList (custid, MaxTurnOver)
SELECT c.custid, @MaxTurnover
FROM dbo.TOControl_GlobalSetting gs WITH (NOLOCK)
	INNER JOIN dbo.Customer c WITH (NOLOCK) ON gs.custid = c.custid
WHERE site = '789y' AND roleid <> 1 AND gs.MaxTurnOver < @MaxTurnover

DECLARE @MatchList TABLE(matchid INT, homeid INT, awayid INT, eventdate DATETIME, sporttype INT, leagueid INT) 
DECLARE @PercentageUsed MONEY

INSERT INTO @MatchList(matchid, homeid, awayid, eventdate, sporttype, leagueid)
SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.sporttype, m.leagueid
FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
WHERE m.eventstatus <> 'completed'

--3164 affected rows
UPDATE gs
SET gs.MaxTurnOver = c.MaxTurnover
FROM dbo.TOControl_GlobalSetting gs WITH(ROWLOCK, UPDLOCK) 
	INNER JOIN #CustList c ON c.CustID = gs.CustID

--5979 affected rows
UPDATE t
SET 
	@PercentageUsed = CASE WHEN c.MaxTurnover = 0 THEN 100 ELSE (t.HouseTurnOver*100/c.MaxTurnover) END,
	t.MaxTurnover = c.MaxTurnover,
	t.IsNotified = 
		CASE 
			WHEN c.MaxTurnover > t.MaxTurnover THEN   --- reset isNotified only in case of increasing maxturnover
				CASE	
					WHEN @PercentageUsed >= 100 THEN 100
					WHEN @PercentageUsed >= 80 THEN 80
					WHEN @PercentageUsed >= 60 THEN 60
					WHEN @PercentageUsed >= 40 THEN 40
					ELSE 0
				END 
			ELSE IsNotified 
		END
FROM dbo.TOControl_Setting t WITH(ROWLOCK, UPDLOCK)
	INNER JOIN #CustList c ON c.CustID = t.CustID
	INNER JOIN @MatchList m ON m.matchid = t.matchid
