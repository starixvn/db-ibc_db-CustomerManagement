/*<info serverAlias="DBACC-bodb_ACC" executers="" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_ACC]
GO

ALTER PROCEDURE [dbo].[Task_BetMonitoring_CustTotalBetReachThreshold_Job]
	@MaxBatch INT = 500000 --Total CustID of a patch
AS 
/*  
	Creator: Elodie
	Date: 20160705
	Task: Detect customer who reach threshold - [Redmine:#58401]
	DB: DBACC/bodb_ACC
  
	History:  

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Threshold FLOAT, @MinimumTickets SMALLINT, @Threshold_TINYINT TINYINT, @ModifiedDate SMALLDATETIME, @MinDate SMALLDATETIME
	CREATE TABLE #tmpCustTotalBet (CustID INT PRIMARY KEY, TotalBet INT, TotalBetAfterThreshold FLOAT)	
	CREATE TABLE #tmpCust (CustID INT PRIMARY KEY)

	SELECT @MinDate = CAST(Value AS SMALLDATETIME)
	FROM dbo.BetMonitoring_Setting with (NOLOCK)
	WHERE SettingName = 'MinDate'

	SELECT @ModifiedDate = GETDATE()
	SELECT @Threshold = CONVERT(FLOAT,Value)/100 FROM dbo.BetMonitoring_Setting with (NOLOCK) WHERE SettingName = 'Threshold'
	SELECT @MinimumTickets = CONVERT(SMALLINT,Value) FROM dbo.BetMonitoring_Setting with (NOLOCK) WHERE SettingName = 'MinimumTickets'
	
	IF @MinDate = '1900-01-01 00:00:00' -- 1: recheck all data in BetMonitoring_CustTotalBet table
	BEGIN
		DECLARE @FromCustID INT, @ToCustID INT, @MinCustID INT, @MaxCustID INT, @CustNo_est INT, @Patch_start TINYINT = 1, @Patch_stop TINYINT = 1

		CREATE TABLE #PatchRunning_tmp (ID INT)
		CREATE TABLE #PatchRunning (ID INT IDENTITY, CustID_to INT)
		
		SELECT @MinCustID = MIN(CustID), @MaxCustID = MAX(CustID) FROM BetMonitoring_CustTotalBet WITH (NOLOCK)
		
		SET @CustNo_est =  (SELECT COUNT(DISTINCT CUSTID) FROM BetMonitoring_CustTotalBet WITH (NOLOCK))
		
		IF @CustNo_est < @MaxBatch 
			SET @MaxBatch = @CustNo_est
		
		SET @Patch_stop = @CustNo_est / @MaxBatch + CASE WHEN @CustNo_est % @MaxBatch = 0 THEN 0 ELSE 1 END
		
		WHILE @Patch_start <= @Patch_stop
		BEGIN
			INSERT INTO #PatchRunning_tmp (ID)
			VALUES (@Patch_start)
			
			SET @Patch_start = @Patch_start + 1
		END
		
		SET @Patch_start = 1
		
		INSERT INTO #PatchRunning (CustID_to)
		SELECT CustID
		FROM (
		SELECT CUSTID, ROW_NUMBER () OVER (ORDER BY CUSTID) AS Row_Index
		FROM BetMonitoring_CustTotalBet WITH (NOLOCK) 
		GROUP BY CustID
		) AS T
		WHERE T.Row_Index IN (SELECT ID * @MaxBatch 
							  FROM #PatchRunning_tmp
							  UNION 
							  SELECT @CustNo_est
							  ) 
		ORDER BY CustID
		
		WHILE @Patch_start <= @Patch_stop
		BEGIN
			
			SET @FromCustID  = @MinCustID
			
			SET @ToCustID = (SELECT CustID_to FROM #PatchRunning WHERE ID = @Patch_start)
			
			INSERT INTO #tmpCustTotalBet (CustID, TotalBet, TotalBetAfterThreshold)
			SELECT b.CustID, SUM(b.BetCount), @Threshold * SUM(b.BetCount)
			FROM BetMonitoring_CustTotalBet b WITH (NOLOCK)
			WHERE b.CustID >= @FromCustID AND b.CustID <= @ToCustID
			GROUP BY b.CustID
			HAVING SUM(b.BetCount)> @MinimumTickets
			
			SELECT @Threshold_TINYINT = CAST(@Threshold * 100 AS TINYINT)

			UPDATE bh
			SET bh.BetCount = b.BetCount,
				bh.TotalBet = tb.TotalBet,
				bh.Threshold = @Threshold_TINYINT,
				bh.NotifiedStatus = 1,
				bh.ModifiedDate = @ModifiedDate
			FROM BetMonitoring_CustTotalBet_History bh WITH (ROWLOCK, UPDLOCK)
				INNER JOIN BetMonitoring_CustTotalBet b WITH (NOLOCK) ON b.CustID = bh.CustID AND b.SportType = bh.SportType
				INNER JOIN #tmpCustTotalBet tb ON b.CustID = tb.CustID
			WHERE b.BetCount >= tb.TotalBetAfterThreshold
				AND bh.NotifiedStatus <> 2

			INSERT INTO dbo.BetMonitoring_CustTotalBet_History (CustID, SportType, BetCount, TotalBet, Threshold, NotifiedStatus, ModifiedDate)
			SELECT b.CustID, b.SportType, b.BetCount, tb.TotalBet, @Threshold_TINYINT, 1 AS NotifiedStatus, @ModifiedDate AS ModifiedDate
			FROM BetMonitoring_CustTotalBet b WITH (NOLOCK)
				INNER JOIN #tmpCustTotalBet tb ON b.CustID = tb.CustID
			WHERE NOT EXISTS (SELECT 1 FROM BetMonitoring_CustTotalBet_History ig WITH (NOLOCK) WHERE ig.CustID = b.CustID AND ig.SportType = b.SportType)
				AND b.BetCount >= tb.TotalBetAfterThreshold
				AND b.SportType <> 1
			
			SELECT @FromCustID, @ToCustID

			SELECT @MinCustID = @ToCustID + 1
			
			SET @Patch_start = @Patch_start + 1
			
			WAITFOR DELAY '00:00:00.28'
		END
	END
	ELSE
	BEGIN
		INSERT INTO #tmpCust (CustID)
		SELECT CustID
		FROM dbo.BetMonitoring_CustTotalBet WITH (NOLOCK)
		WHERE ModifiedDate > @MinDate
		GROUP BY CustID

		INSERT INTO #tmpCustTotalBet (CustID, TotalBet, TotalBetAfterThreshold)
		SELECT b.CustID, SUM(b.BetCount), @Threshold * SUM(b.BetCount)
		FROM BetMonitoring_CustTotalBet b WITH (NOLOCK)
			INNER JOIN #tmpCust tmp ON tmp.CustID = b.CustID
		GROUP BY b.CustID	
		HAVING SUM(b.BetCount) > @MinimumTickets
		
		SELECT @Threshold_TINYINT = CAST(@Threshold * 100 AS TINYINT)

		UPDATE bh
		SET bh.BetCount = b.BetCount,
			bh.TotalBet = tb.TotalBet,
			bh.Threshold = @Threshold_TINYINT,
			bh.NotifiedStatus = 1,
			bh.ModifiedDate = @ModifiedDate
		FROM BetMonitoring_CustTotalBet_History bh WITH (ROWLOCK, UPDLOCK)
			INNER JOIN BetMonitoring_CustTotalBet b WITH (NOLOCK) ON b.CustID = bh.CustID AND b.SportType = bh.SportType
			INNER JOIN #tmpCustTotalBet tb ON b.CustID = tb.CustID
		WHERE b.BetCount >= tb.TotalBetAfterThreshold
			AND bh.NotifiedStatus <> 2

		INSERT INTO dbo.BetMonitoring_CustTotalBet_History (CustID, SportType, BetCount, TotalBet, Threshold, NotifiedStatus, ModifiedDate)
		SELECT b.CustID, b.SportType, b.BetCount, tb.TotalBet, @Threshold_TINYINT, 1 AS NotifiedStatus, @ModifiedDate AS ModifiedDate
		FROM BetMonitoring_CustTotalBet b WITH (NOLOCK)
			INNER JOIN #tmpCustTotalBet tb ON b.CustID = tb.CustID
		WHERE NOT EXISTS (SELECT 1 FROM BetMonitoring_CustTotalBet_History ig WITH (NOLOCK) WHERE ig.CustID = b.CustID AND ig.SportType = b.SportType)
			AND b.BetCount >= tb.TotalBetAfterThreshold
			AND b.SportType <> 1
	END

	UPDATE s 
	SET Value = CONVERT(VARCHAR(200), GETDATE(), 120) 
	FROM BetMonitoring_Setting s WITH (ROWLOCK,UPDLOCK)
	WHERE SettingName = 'MinDate'
END
GO