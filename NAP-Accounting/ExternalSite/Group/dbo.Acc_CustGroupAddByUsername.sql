/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="1"></info>*/
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
	DB: DBCUST/CUSTDB 
	
	Revisions:
		- 20110429@Jamie: Remove prefix DBLOG when call write log
		- 20110913@Jamie: Put linked server DBLOG because switching to DB053
		- 20110927@Lukas: modify to be able to put 1 customer into 2 groups
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE, change linked server DB03 to DBPOLICY, DB06 to DBARC
		- 20160729@Percy: insert into setting table if group is extra pt group [RedmineID: #60883]
		- 20170926@Percy: Move the table: Acc_GroupExtraPTSetting from DBACC.bodb_ACC to DBAGE.bodb02 [RedmineID: #83600]
		- 20180409@Kan: Make this SP nested [RedmineID: 77733]
		- 20180509@Kan: Hard-code to update temporary global setting for World Cup event [Redmine: 92010]
		  + ACCUSD: 1,000,000 US$ (USD)
		  + ACCINDO: 5,000,000 IN (IDR)
		  + ACCTHAI: 20,000,000 TB (THB)
		- 20180706@Kan: Rollback new global setting to old value after World Cup event [Redmine: 97774]
		- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration - move to DBCUST [Redmine: 104770]
		- 20200512@Johnson: check super's prefix before adding into 789y's group [redmine:#133846]
		- 20210426@Sol: Alpha/NAP - Migrate from DBACC to DBCust - [Redmine: #154041]
		- 20250102@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
*/

BEGIN
	SET NOCOUNT ON 
	
	DECLARE @startRun	DATETIME
	DECLARE @endRun		DATETIME
	DECLARE @duration	INT
	
	SET @startRun = GETDATE()
	
	DECLARE @RoleID INT
	DECLARE @CustID INT, @SiteID INT
	DECLARE @Currency INT
	DECLARE @SiteName VARCHAR(50)
	
	SELECT @RoleID = RoleID, @CustID = CustID, @Currency = Currency, @SiteName = [Site]
	FROM dbo.Customer WITH (NOLOCK)
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
		SELECT @ErrMsg = 	N'The role of this username is not super, please check again!'	
			, @ErrCode = 102
		RETURN
	END
	
	--Check belonging group currency
	
	IF (@Currency NOT IN (SELECT exchangeID from dbo.[f_CurrencyBySystem](@GroupName)))
	BEGIN
		SELECT @ErrMsg = 	N'The currency of this username does not belong to this group!'
			, @ErrCode = 103
		RETURN
	END
	
	--Check belonging site
	SELECT @SiteID = SiteId From dbo.[Site] WITH (NOLOCK)
	WHERE [site] = @SiteName
	
	IF (@SiteID NOT IN (SELECT siteid FROM dbo.[f_SiteBySystem] (@GroupName)))
	BEGIN
		SELECT @ErrMsg = 	N'The site of this username does not belong to this group!'
			, @ErrCode = 104
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM dbo.Acc_CustGroup WITH (NOLOCK) WHERE CustID = @CustID AND GroupName = @GroupName)
	BEGIN
		SELECT @ErrMsg = 	N'This username was added before, please check again!'
			, @ErrCode = 105
		RETURN
	END
	
	--check super's prefix for789y's group
	IF @GroupName IN ('ACCUT','ACCYEN789','ACCYEN889','ACCTEST')	--789y
		AND EXISTS (SELECT 1 FROM Acc_SuperPrefix WITH(NOLOCK)
					WHERE GroupName = @GroupName)
		AND NOT EXISTS (SELECT 1 FROM Acc_SuperPrefix WITH(NOLOCK)
						WHERE GroupName = @GroupName
							AND Prefix = LEFT(@username,2)
							AND AllowNewSuper = 1
				)				
	BEGIN
		SELECT @ErrMsg = 	N'This group requires the supers to follow its prefixes. Please select another super or rename the current one.'
			, @ErrCode = 110
		RETURN 
	END		
	
	
	INSERT INTO dbo.Acc_CustGroup (CustID, RoleID, GroupName, RepUpdateTime)
	VALUES (@CustID, @RoleID, @GroupName, dbo.f_GetDateTime2())

	-- Check Extra PT Group
	IF EXISTS (SELECT 1 FROM dbo.Acc_DWLList_ExtraPT WITH(NOLOCK) WHERE GroupName = @GroupName)
	BEGIN
		UPDATE dbo.Acc_CustGroup WITH(ROWLOCK, UPDLOCK)
		SET IsPayout = 1
			,RepUpdateTime = dbo.f_GetDateTime2()
		WHERE CustID = @CustID AND GroupName = @GroupName
		
		DECLARE @today DATETIME
		SELECT  @today = CONVERT(DATE, GETDATE())

		IF NOT EXISTS (SELECT 1 FROM dbo.Acc_GroupExtraPTSetting WITH(NOLOCK) WHERE SuperId = @CustID AND @today BETWEEN FromDate AND ToDate)
		BEGIN
		SELECT
			@ErrCode = 106,
			@ErrMsg = 'Please select the Extra PT effective date for the customer ' + @Username + '.'
		END
	END

	/* ---------- Keep below code for future use. ----------
	-- Hard-code to update temporary global setting for World Cup event
	-- Format date is: yyyy-mm-dd
	DECLARE @BeginWC DATETIME = '2018-6-11',
		@EndWC DATETIME = '2018-7-16',
		@MaxTurnover MONEY,
		@Creator INT
	
	IF @GroupName IN ('ACCUSD', 'ACCINDO', 'ACCTHAI')
		AND CONVERT(DATE, GETDATE()) BETWEEN @BeginWC AND @EndWC
	BEGIN
		IF @GroupName = 'ACCUSD'
		BEGIN
			SET @MaxTurnover = 1000000
		END
		ELSE IF @GroupName = 'ACCINDO'
		BEGIN
			SET @MaxTurnover = 5000000
		END
		ELSE --IF @GroupName = 'ACCTHAI'
		BEGIN
			SET @MaxTurnover = 20000000
		END

		SELECT @Creator = CustId
		FROM bodb02.dbo.Customer WITH (NOLOCK)
		WHERE Username = 'starix2'

		EXEC DBCUST.CustDB.dbo.NAP_TOControl_GlobalSettingUpdate
			@CustID = @CustID,
			@MaxTurnover = @MaxTurnover,
			@SportType = 1,
			@IsGroupHeadLine = 0,
			@UserID = @Creator,
			@IP	= '::1',
			@ErrCode = 0,
			@ErrMsg = ''
	END
	-- End of Hard-code ...
	*/

	--Write log data
	DECLARE @LogData NVARCHAR(1000)
	
	SET @LogData = '<Acc_CustGroupAddByUsername UserID="' + CONVERT(VARCHAR(20), @UserID)
					+ '" CustID="' + CONVERT(VARCHAR(50), @CustID)
					+ '" Username="' + CONVERT(VARCHAR(50), @Username)
					+ '" Group="' + CONVERT(VARCHAR(50), @GroupName) + '" />'

	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)
	
	
	-- Write log
	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @UserID,
		@CustID = @CustID,
		@ActionID = 618,
		@TrackingValue = @LogData,
		@duration = @duration
		
END
GO