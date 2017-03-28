USE [msdb]
GO

/****** Object:  Job [bodb02 : Sync DownlineTurnOver_Setting]    Script Date: 01/25/2015 22:55:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/25/2015 22:55:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'bodb02 : Sync DownlineTurnOver_Setting', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Jamie', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get Change]    Script Date: 01/25/2015 22:55:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Change', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Get Change
EXEC DBAGE.bodb02.dbo.Task_GetDownlineTurnOver_Setting_Change @GetOption = ''C''

INSERT INTO dbo.DownlineTurnOver_Setting_tmp
(CustID, matchid, maxturnover, totalturnover,houseturnover)
SELECT CustID, matchid, maxturnover, totalturnover,houseturnover
FROM DBAGE.bodb02.dbo.DownlineTurnOver_Setting_tmp


-- Sync Change
Declare @temp TABLE (CustID int, matchid int)
Declare @ucnt int, @icnt int

UPDATE D
SET maxturnover = t.maxturnover,
	totalturnover = t.totalturnover,
	houseturnover = t.houseturnover
OUTPUT deleted.CustID, deleted.matchid INTO @temp (CustID, matchid)
FROM
	dbo.DownlineTurnOver_Setting D
	INNER JOIN dbo.DownlineTurnOver_Setting_tmp T ON D.CustID = T.CustID AND D.matchid = T.matchid

SET @ucnt = @@ROWCOUNT

INSERT INTO dbo.DownlineTurnOver_Setting
(CustID, matchid, maxturnover, totalturnover,houseturnover)
SELECT CustID, matchid, maxturnover, totalturnover,houseturnover
FROM dbo.DownlineTurnOver_Setting_tmp D
WHERE NOT EXISTS (SELECT * FROM @temp T WHERE D.CustID = T.CustID AND D.matchid = T.matchid)

SET @icnt = @@ROWCOUNT

DELETE FROM DownlineTurnOver_Setting_tmp

PRINT '' == Upd = '' + CAST(@ucnt as varchar(10)) + '' , Ins = '' + CAST(@icnt as varchar(10)) + '' ==''

', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Get Delete]    Script Date: 01/25/2015 22:55:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Get Delete', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'
-- Get Delete
EXEC DBAGE.bodb02.dbo.Task_GetDownlineTurnOver_Setting_Change @GetOption = ''D''

INSERT INTO dbo.DownlineTurnOver_Setting_tmp
(CustID, matchid, maxturnover, totalturnover,houseturnover)
SELECT CustID, matchid, maxturnover, totalturnover,houseturnover
FROM DBAGE.bodb02.dbo.DownlineTurnOver_Setting_tmp


-- Sync Delete
Declare @dcnt int

DELETE D
FROM dbo.DownlineTurnOver_Setting D
	INNER JOIN dbo.DownlineTurnOver_Setting_tmp T ON D.CustID = T.CustID AND D.matchid = T.matchid

SET @dcnt = @@ROWCOUNT

DELETE FROM DownlineTurnOver_Setting_tmp

PRINT '' == Del = '' + CAST(@dcnt as varchar(10)) + '' == ''
', 
		@database_name=N'bodb02', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'(Re)start every 10 second', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=2, 
		@freq_subday_interval=10, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130529, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'22e284db-8058-4995-a2c6-b6309c3e181d'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


