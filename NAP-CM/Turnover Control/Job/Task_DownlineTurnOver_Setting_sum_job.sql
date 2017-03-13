USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_DownlineTurnOver_Setting_sum_job]    Script Date: 01/20/2015 04:04:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
	Created: Dom
	Date: 2014-10-06
	Task: Rebuild the function Turnover Control [Feature #21804]
	SERVER: DBAGE
	DB: BODB02
*/

CREATE PROCEDURE [dbo].[Task_DownlineTurnOver_Setting_sum_job]
AS
	TRUNCATE TABLE dbo.DownlineTurnOver_Trigger_tmp
	
	Declare @rc1 int, @rc2 int
	
	DELETE D
	OUTPUT deleted.srecommend,deleted.mrecommend,deleted.recommend, deleted.matchid,deleted.bettype, deleted.sumstake,deleted.HouseTurnover
	INTO DownlineTurnOver_Trigger_tmp (srecommend,mrecommend,recommend, matchid,bettype, sumstake,HouseTurnover)
	FROM dbo.DownlineTurnOver_Trigger D
	
	SET @rc1 = @@ROWCOUNT
	
	;WITH src AS (
		SELECT srecommend CustID, matchid, SUM(sumstake) sumstake,SUM(HouseTurnover) HouseTurnover 
		FROM dbo.DownlineTurnOver_Trigger_tmp 
		WHERE   ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY srecommend, matchid
		UNION ALL
		SELECT mrecommend CustID, matchid, SUM(sumstake) sumstake,SUM(HouseTurnover) HouseTurnover 
		FROM dbo.DownlineTurnOver_Trigger_tmp 
		WHERE   ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY mrecommend, matchid
		UNION ALL
		SELECT recommend CustID, matchid, SUM(sumstake) sumstake,SUM(HouseTurnover) HouseTurnover 
		FROM dbo.DownlineTurnOver_Trigger_tmp 
		WHERE   ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY recommend, matchid

	)
	UPDATE T
	SET IsNotified = CASE WHEN T.MaxTurnover <> 0 AND T.HouseTurnover + src.HouseTurnover <> T.HouseTurnover THEN   --- Update Notification Flag
								CASE	WHEN ((T.HouseTurnover + src.HouseTurnover)/T.MaxTurnover)*100 < 80 THEN 0
										WHEN ((T.HouseTurnover + src.HouseTurnover)/T.MaxTurnover)*100 < 95  AND IsNotified = 0 THEN 0
										ELSE IsNotified
								END 
							ELSE IsNotified 
					END,
		totalturnOver = totalturnover + src.sumstake,
		T.HouseTurnover = T.HouseTurnover + src.HouseTurnover
	FROM dbo.DownlineTurnOver_Setting T
		INNER JOIN src ON T.custid = src.CustID AND T.matchid = src.matchid
		
	------Insert for new match and custid ---------------
	;WITH src AS (
		SELECT srecommend CustID, MatchID, maxturnover, SUM(sumstake) sumstake,SUM(HouseTurnover) HouseTurnover 
		FROM dbo.DownlineTurnOver_Trigger_tmp tr
		INNER JOIN DownlineTurnOver_GlobalSetting gs WITH(NOLOCK) ON gs.CustID = tr.srecommend
		WHERE   ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY srecommend, matchid, maxturnover
		UNION ALL
		SELECT mrecommend CustID, MatchID, maxturnover, SUM(sumstake) sumstake,SUM(HouseTurnover) HouseTurnover 
		FROM dbo.DownlineTurnOver_Trigger_tmp tr
		INNER JOIN DownlineTurnOver_GlobalSetting gs WITH(NOLOCK) ON gs.CustID = tr.mrecommend
		WHERE   ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY mrecommend, matchid, maxturnover
		UNION ALL
		SELECT recommend CustID, MatchID, maxturnover, SUM(sumstake) sumstake,SUM(HouseTurnover) HouseTurnover 
		FROM dbo.DownlineTurnOver_Trigger_tmp tr
		INNER JOIN DownlineTurnOver_GlobalSetting gs WITH(NOLOCK) ON gs.CustID = tr.recommend
		WHERE   ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		GROUP BY recommend, matchid, maxturnover
	)
	INSERT INTO DownlineTurnOver_Setting(custid, matchid, maxturnover, totalturnover, HouseTurnover, IsNotified)
	SELECT s.custid, s.matchid, s.maxturnover, sumstake, s.HouseTurnover, 0 
	FROM DownlineTurnOver_GlobalSetting gs WITH(NOLOCK)
	LEFT JOIN src s ON s.custid=gs.custid
	LEFT JOIN DownlineTurnOver_Setting st WITH(NOLOCK) ON st.CustID = s.CustID AND st.MatchID = s.MatchID
	WHERE s.CustID IS NOT NULL 
		AND s.MatchID IS NOT NULL
		AND st.CustID IS NULL 
		AND st.MatchID IS NULL 
	
	SET @rc2 = @@ROWCOUNT
	
	PRINT '=== Delete ' + CAST(@rc1 as varchar(20)) + ' row(s), Update ' + CAST(@rc2 as varchar(20)) + ' row(s) ==='
	
	

GO


