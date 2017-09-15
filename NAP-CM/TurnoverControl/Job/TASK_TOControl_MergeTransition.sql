/*<info serverAlias="DBCUST-CustDB" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [CustDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[TASK_TOControl_MergeTransition]
AS 
/*
Created: 20170324@Francis
Task : Merge changed data for TOControl_Setting
DB: DBCUST.CustDB

Original:

Revisions:

Param explanation:
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @PercentageUsed MONEY

	CREATE TABLE #TmpTableRaw(CustID INT, matchid INT, adjusted_TurnOver MONEY, adjusted_HouseTurnOver MONEY)
	CREATE TABLE #TmpTable(CustID INT, matchid INT, adjusted_TurnOver MONEY, adjusted_HouseTurnOver MONEY, MaxTurnOver MONEY NULL)
	CREATE CLUSTERED INDEX CIX_CustID_MatchID ON #TmpTableRaw (CustID, matchid)
	CREATE UNIQUE CLUSTERED INDEX CIX_CustID_MatchID ON #TmpTable (CustID, matchid)

	INSERT INTO #TmpTableRaw(CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver)
		EXEC DBAGE.bodb02.dbo.TASK_TOControl_GetTransition

	INSERT INTO #TmpTable(CustID, matchid, adjusted_TurnOver, adjusted_HouseTurnOver)
		SELECT CustID, matchid, SUM (adjusted_TurnOver), SUM(adjusted_HouseTurnOver)
		FROM #TmpTableRaw
		GROUP BY CustID, matchid

	DROP TABLE #TmpTableRaw

	UPDATE t 
	SET MaxTurnOver = gl.MaxTurnOver
	FROM #TmpTable t
		INNER JOIN dbo.TOControl_GlobalSetting gl WITH (NOLOCK) ON t.CustID = gl.CustID

	MERGE dbo.TOControl_Setting AS TARGET
			USING (SELECT CustID, matchid, MaxTurnOver, adjusted_TurnOver, adjusted_HouseTurnOver FROM #TmpTable)
			   AS SOURCE (CustID, matchid, MaxTurnOver, adjusted_TurnOver, adjusted_HouseTurnOver)
				ON (TARGET.CustID = SOURCE.CustID AND TARGET.matchid = SOURCE.matchid)
			WHEN MATCHED THEN 
				 UPDATE SET @PercentageUsed = CASE WHEN TARGET.MaxTurnOver = 0 THEN	100 ELSE (TARGET.HouseTurnover + SOURCE.adjusted_HouseTurnOver) * 100 / TARGET.MaxTurnOver END,
							TARGET.TotalTurnOver = TARGET.TotalTurnOver + SOURCE.adjusted_TurnOver,
							TARGET.HouseTurnover = TARGET.HouseTurnover + SOURCE.adjusted_HouseTurnOver,
							--TARGET.IsNotified = 
							--	CASE	
							--		WHEN @PercentageUsed >= 100 THEN 100
							--		WHEN @PercentageUsed >= 80 THEN 80
							--		WHEN @PercentageUsed >= 60 THEN 60
							--		WHEN @PercentageUsed >= 40 THEN 40
							--	ELSE 0
							--	END,
							TARGET.PercentLevel = 
								CASE	
									WHEN @PercentageUsed < 10 THEN 0
									WHEN @PercentageUsed < 20 THEN 1
									WHEN @PercentageUsed < 30 THEN 2
									WHEN @PercentageUsed < 40 THEN 3
									WHEN @PercentageUsed < 50 THEN 4
									WHEN @PercentageUsed < 60 THEN 5
									WHEN @PercentageUsed < 70 THEN 6
									WHEN @PercentageUsed < 80 THEN 7
									WHEN @PercentageUsed < 90 THEN 8
									WHEN @PercentageUsed < 100 THEN 9
								ELSE 10
							END 
			WHEN NOT MATCHED THEN	
				INSERT (CustID, matchid, MaxTurnOver, TotalTurnOver, HouseTurnover, IsNotified, PercentLevel)
				VALUES (SOURCE.CustID, SOURCE.matchid, SOURCE.MaxTurnOver, SOURCE.adjusted_TurnOver, SOURCE.adjusted_HouseTurnOver, 0, 
						CASE WHEN SOURCE.MaxTurnOver = 0 THEN 100 ELSE CASE	WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 10 THEN 0
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 20 THEN 1
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 30 THEN 2
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 40 THEN 3
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 50 THEN 4
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 60 THEN 5
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 70 THEN 6
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 80 THEN 7
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 90 THEN 8
																			WHEN (SOURCE.adjusted_HouseTurnOver) * 100 / SOURCE.MaxTurnOver < 100 THEN 9 ELSE 10 END
											  END);

	DROP TABLE #TmpTable
END