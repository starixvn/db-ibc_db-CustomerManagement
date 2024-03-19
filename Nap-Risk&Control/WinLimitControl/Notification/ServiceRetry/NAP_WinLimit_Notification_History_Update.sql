/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_History_Update]
(
	@LogID BIGINT,
	@UserID INT,
	@CustID INT
)
AS
/*
	Created: 20210410@Helen
	Task : 153291 - Win Limit Control - Notification - RetryService
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210423@Helen: CWL - Support to add 2 columns IsNotified and LogID into CWL History Monitoring Page - [Redmine:153291]
		- 20230829@Luke: Apply Company Max Payout rules per ticket [Redmine: #193014]
		
	Param's Explanation:
	
		
*/
BEGIN
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
    SELECT @StartRun = GETDATE();
     
	UPDATE w 
		SET IsNotified = 0
	FROM WinLimit_CustGameMonitoring_History w WITH (ROWLOCK)
	WHERE w.IsNotified = 1 AND w.LogID = @LogID AND w.ActionID < 200 
	
	IF @@ROWCOUNT = 0
		RETURN
		
	 SELECT @EndRun = GETDATE(),
            @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
     DECLARE @TrackingValue VARCHAR(300)='', @TrackingValue2 VARCHAR(300)='';
     
     -- NEW VALUE
     SET @TrackingValue = '<NAP_WinLimit_Notification_History_Update ';
     SET @TrackingValue = @TrackingValue+'" LogID ="'+CONVERT(VARCHAR(20), @LogID);
     SET @TrackingValue = @TrackingValue+'" CustID ="'+CONVERT(VARCHAR(20), @CustID);
     SET @TrackingValue = @TrackingValue+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
     SET @TrackingValue = @TrackingValue+'" IsNotified="0"'+'/>';
     
     -- OLD VALUE
     SET @TrackingValue2 = '<NAP_WinLimit_Notification_History_Update ';
     SET @TrackingValue2 = @TrackingValue2+'" LogID ="'+CONVERT(VARCHAR(20), @LogID);
     SET @TrackingValue2 = @TrackingValue2+'" CustID ="'+CONVERT(VARCHAR(20), @CustID);
     SET @TrackingValue2 = @TrackingValue2+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
     SET @TrackingValue2 = @TrackingValue2+'" IsNotified="1"'+'/>';
     
     SELECT @EndRun = GETDATE(),
            @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);
     BEGIN TRY
         EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
              @UserID = @UserID,
              @CustID = @CustID,
              @ActionID = 31208,
              @TrackingValue = @TrackingValue,
              @TrackingValue2 = @TrackingValue2,
              @Duration = @Duration;
     END TRY
     BEGIN CATCH
     END CATCH;
END	