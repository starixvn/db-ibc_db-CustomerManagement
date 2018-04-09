/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Age]
GO

ALTER PROCEDURE  [dbo].[Acc_CustGroupDel]
	@CustID int,
	@GroupName	VARCHAR(50),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int 
AS

/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Remove a customer out of Acc_CustGroup
	DB: DBAGE/bodb_AGE 
	
	Revisions:
		- 20110429@Jamie: Remove prefix DBLOG when call write log
		- 20110913@Jamie: Put linked server DBLOG because switching to DB053
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY
		- 20160727@Percy: Add parameter @GroupName to remove only @CustID from @GroupName [RemdineID: #60883]
		- 20170926@Percy: Move the nested SP: Acc_GroupExtraPTSetting_Upd from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	
	SET @startRun = GETDATE()
	
	-- Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
		@CustID = @UserID,
		@FuncName = '[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
		RETURN		
	
	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_CustGroup WITH (NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT
			@ErrMsg = 	N'This Customer does not exist',
			@ErrCode = 101
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM dbo.Acc_CustGroup WITH (NOLOCK) WHERE CustID = @CustID AND GroupName = @GroupName)
	BEGIN
		SELECT
			@ErrMsg = 	N'This Customer does not belong to this group!',
			@ErrCode = 102
		RETURN
	END

	-- Check Extra PT Group
	IF EXISTS (SELECT 1 FROM OPENQUERY(DBACC, 'SELECT GroupName FROM bodb_Acc.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)') WHERE GroupName = @GroupName)
	BEGIN
		-- delete setting
		EXEC DBCUST.CustDB.dbo.Acc_GroupExtraPTSetting_Upd
			@CustID = @CustID,
			@GroupName = @GroupName,
			@EffectiveDate = NULL, -- delete
			@UserID = @UserID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg	= @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN
	END

	DELETE dbo.Acc_CustGroup WITH (ROWLOCK,UPDLOCK)
	WHERE CustID = @CustID AND GroupName = @GroupName
	
	-- Write log data
	DECLARE @LogData NVARCHAR(1000)
	SET @LogData = '<Acc_CustGroupDel UserID="' + CONVERT(VARCHAR(20), @UserID)
					+ '" CustID="' + CONVERT(VARCHAR(50), @CustID)
					+ '" Group="' + CONVERT(VARCHAR(50), @GroupName) + '" />'

	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 619,
		@TrackingValue = @LogData,
		@duration = @duration
END
GO