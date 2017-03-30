/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[NAP_TOControl_TurnoverNotificationSelect]
AS
/*
	Created: Don
	Date: 2017-03-23
	Task: Get Super/Master/Agent that reached notification thresholds
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination: 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MatchList TABLE (matchid INT, homeid INT, awayid INT, eventdate DATETIME, sporttype INT, leagueid INT)

	DECLARE @temp_ TABLE (custid INT, matchid INT, totalturnover MONEY, MaxTurnover MONEY, houseturnover MONEY, nlevel TINYINT)

	;WITH cte_ AS (
		SELECT t.custid, t.matchid, t.totalturnover, t.MaxTurnover, t.houseturnover, t.IsNotified, CASE WHEN t.MaxTurnover = 0 THEN 100 ELSE t.houseturnover*100/t.MaxTurnover END AS PercentageUsed
		FROM dbo.TOControl_Setting t WITH(NOLOCK)
		WHERE t.PercentLevel >= 4
	)
	INSERT INTO @temp_(custid, matchid, totalturnover, MaxTurnover, houseturnover, nlevel)
		SELECT cte_.custid, cte_.matchid, cte_.totalturnover, cte_.MaxTurnover, cte_.houseturnover, nlevel
		FROM cte_
			CROSS APPLY (SELECT CASE 
									WHEN PercentageUsed >= 100 THEN 100
									WHEN PercentageUsed >= 80 THEN 80
									WHEN PercentageUsed >= 60 THEN 60
									WHEN PercentageUsed >= 40 THEN 40
									ELSE 0
								END) _(nlevel)
		WHERE nlevel > cte_.IsNotified

	-- get match info
	INSERT INTO @MatchList(matchid, homeid, awayid, eventdate, sporttype, leagueid)
		SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.sporttype, m.leagueid
		FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
		WHERE EXISTS(SELECT tmp.matchid FROM @temp_ tmp WHERE m.matchid = tmp.matchid)

	-- return result
	SELECT 
		m.sporttype, m.leagueid, m.matchid, m.homeid, m.awayid, m.eventdate,
		c.custid, c.username, e.currency,c.roleid,
		t.totalturnover, t.maxturnover, t.houseturnover, t.nlevel
	FROM @temp_ t
		INNER JOIN @MatchList m ON t.matchid = m.matchid
		INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.custID = c.custid
		INNER JOIN dbo.exchange e WITH(NOLOCK) ON c.currency = e.exchangeid

END
GO