/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Age]
GO

ALTER PROCEDURE  [dbo].[Acc_CustGroupAddByUsername]
	@Username	varchar(50),
	@GroupName	varchar(50),
	@ErrCode	int = 0 OUTPUT,
	@ErrMsg		nvarchar(1000) = '' OUTPUT,
	@UserID		int 
AS

/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Insert an existing customer to External AccSite Group
	DB: DBAGE/bodb_AGE 
	
	Revisions:
		- 20110429@Jamie: Remove prefix DBLOG when call write log
		- 20110913@Jamie: Put linked server DBLOG because switching to DB053
		- 20110927@Lukas: modify to be able to put 1 customer into 2 groups
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY, DB06 to DBARC
		- 20160729@Percy: insert into setting table if group is extra pt group [RedmineID: #60883]
		- 20170926@Percy: Move the table: Acc_GroupExtraPTSetting from DBACC.bodb_ACC to DBAGE.bodb02 [RedmineID: #83600]
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	
	SET @startRun = GETDATE()
	
	-- Check permission for account site
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission
		@custid = @UserID,
		@funcname ='[Admin_ManageExAcc]',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT,
		@System = 'ACCOUNTING'
	
	IF @ErrCode <> 0
		RETURN
	
	DECLARE @RoleID INT
	DECLARE @CustID INT, @SiteID INT
	DECLARE @Currency INT
	DECLARE @SiteName VARCHAR(50)
	
	SELECT @RoleID = RoleID, @CustID = CustID, @Currency = Currency, @SiteName = [Site]
	FROM bodb02.dbo.Customer WITH (NOLOCK)
	WHERE Username = @Username
	
	--Check custid
	IF ISNULL(@CustID, 0) = 0
	BEGIN
		SELECT @ErrMsg = 	N'This username is invalid!'	
			, @ErrCode = 101
		RETURN
	END
	
	--Check RoleID, should be super role
	IF ISNULL(@RoleID, 0) <> 4
	BEGIN
		SELECT @ErrMsg = 	N'The role of this username is not super, please check again !'	
			, @ErrCode = 102
		RETURN
	END
	
	--Check belonging group currency
	
	IF (@Currency NOT IN (SELECT exchangeID from bodb02.dbo.[f_CurrencyBySystem](@GroupName)))
	BEGIN
		SELECT @ErrMsg = 	N'The currency of this username does not belong to this group !'
			, @ErrCode = 103
		RETURN
	END
	
	--Check belonging site
	SELECT @SiteID = SiteId From bodb02.dbo.[Site] WITH (NOLOCK)
	WHERE [site] = @SiteName
	
	IF (@SiteID NOT IN (SELECT siteid FROM bodb02.dbo.[f_SiteBySystem] (@GroupName)))
	BEGIN
		SELECT @ErrMsg = 	N'The site of this username does not belong to this group !'
			, @ErrCode = 104
		RETURN
	END
	
	
	if exists (SELECT 1 FROM dbo.Acc_CustGroup WITH (NOLOCK) WHERE CustID = @CustID AND GroupName = @GroupName)
	BEGIN
		SELECT @ErrMsg = 	N'This username was added before, please check again!'
			, @ErrCode = 105
		RETURN
	END
	
	INSERT INTO dbo.Acc_CustGroup (CustID, RoleID, GroupName)
	VALUES (@CustID, @RoleID, @GroupName)

	-- Check Extra PT Group
	IF EXISTS (SELECT 1 FROM DBACC.bodb_Acc.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupName = @GroupName)
	BEGIN
		UPDATE dbo.Acc_CustGroup WITH(ROWLOCK, UPDLOCK)
		SET IsPayout = 1
		WHERE CustID = @CustID AND GroupName = @GroupName
		
		DECLARE @today DATETIME
		SELECT  @today = CONVERT(DATE, GETDATE())

		IF NOT EXISTS (SELECT 1 FROM bodb02.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate)
		BEGIN
		SELECT
			@ErrCode = 106,
			@ErrMsg = 'Please select the Extra PT effective date for the customer ' + @Username + '.'
		END
	END

	--Write log data
	DECLARE @LogData NVARCHAR(1000)
	
	SET @LogData = '<Acc_CustGroupAddByUsername UserID="' + CONVERT(VARCHAR(20), @UserID)
					+ '" CustID="' + CONVERT(VARCHAR(50), @CustID)
					+ '" Username="' + CONVERT(VARCHAR(50), @Username)
					+ '" Group="' + CONVERT(VARCHAR(50), @GroupName) + '" />'

	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 618,
		@TrackingValue = @LogData,
		@duration = @duration
END
GO