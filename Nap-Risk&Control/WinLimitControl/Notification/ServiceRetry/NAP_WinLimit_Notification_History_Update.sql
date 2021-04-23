/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_Notification_History_Update]
(
	@LogID BIGINT
)
AS
/*
	Created: 20210410@Helen
	Task : 153291 - Win Limit Control - Notification - RetryService
	DB: DBCUST/CustDB
	
	Revisions:
		- 20210423@Helen: CWL - Support to add 2 columns IsNotified and LogID into CWL History Monitoring Page - [Redmine:153291]
			
	Param's Explanation:
	
		
*/
BEGIN
	
	UPDATE w 
		SET IsNotified = 0
	FROM WinLimit_CustGameMonitoring_History w WITH (ROWLOCK)
	WHERE w.IsNotified = 1 AND w.LogID = @LogID
		
END	