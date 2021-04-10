/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_WinLimit_Notification_ServiceRetry_Update]
(
	@logIDs VARCHAR(MAX)
)
AS
/*
	Created: 20210410@Helen
	Task : 153241 - Win Limit Control - Notification - RetryService
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210410@Helen: Support retry notification server - [Redmine:153241]
			
	Param's Explanation:
	• @logIDs: '63252,63254' (from table WinLimit_CustGameMonitoring_History)
		
*/
BEGIN

	CREATE TABLE #logIDs (LogID BIGINT, Isfinished BIT)
	CREATE TABLE #logIDs_batch (LogID BIGINT)
	
	INSERT INTO #logIDs (LogID)
	SELECT val
	FROM dbo.f_SplitString (@logIDs,',')
	OPTION (MAXRECURSION 0)
	
	DECLARE @debug_message VARCHAR(500)
	SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121)
	
	WHILE (1=1)
	BEGIN
		UPDATE TOP (1000) lg
			SET Isfinished = 1	
		OUTPUT DELETED.LogID
		INTO #logIDs_batch (LogID)		
		FROM #logIDs lg
		WHERE Isfinished IS NULL
		
		IF @@ROWCOUNT = 0
			BREAK
			
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT
		
		UPDATE w 
			SET IsNotified = 0
		FROM WinLimit_CustGameMonitoring_History w WITH (ROWLOCK)
			INNER JOIN #logIDs_batch lg ON w.LogID = lg.LogID
		WHERE w.IsNotified = 1 
		
		TRUNCATE TABLE #logIDs_batch
		
		WAITFOR DELAY '00:00:00.100'
		
	END
	DROP TABLE #logIDs
END	