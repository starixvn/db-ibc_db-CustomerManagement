/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
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
	DB: DBCUST-CUSTDB 
	
	Revisions:
		- 20110429@Jamie: Remove prefix DBLOG when call write log
		- 20110913@Jamie: Put linked server DBLOG because switching to DB053
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY
		- 20160727@Percy: Add parameter @GroupName to remove only @CustID from @GroupName [RemdineID: #60883]
		- 20170926@Percy: Move the nested SP: Acc_GroupExtraPTSetting_Upd from DBACC.bodb_ACC to DBCUST.CustDB [RedmineID: #83600]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20240816@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241231@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	
	SET @startRun = GETDATE()
	
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
	IF EXISTS (SELECT 1 FROM dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupName = @GroupName)
	BEGIN
		-- delete setting
		EXEC dbo.Acc_GroupExtraPTSetting_Upd
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
	OUTPUT DELETED.custid, DELETED.GroupName, dbo.f_GetDateTime2()
	INTO Acc_CustGroup_Del_Inhouse(custid,GroupName,RepUpdateTime)
	WHERE CustID = @CustID AND GroupName = @GroupName
	
	-- Write log data
	DECLARE @LogData NVARCHAR(1000)
	SET @LogData = '<Acc_CustGroupDel UserID="' + CONVERT(VARCHAR(20), @UserID)
					+ '" CustID="' + CONVERT(VARCHAR(50), @CustID)
					+ '" Group="' + CONVERT(VARCHAR(50), @GroupName) + '" />'

	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper	@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 619,
		@TrackingValue = @LogData,
		@duration = @duration
		
END
GO