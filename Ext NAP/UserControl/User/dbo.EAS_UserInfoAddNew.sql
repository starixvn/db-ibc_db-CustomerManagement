/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoAddNew]
	@userID	INT = 0,	
	@Username	VARCHAR(50),
	@custid		INT = 0 OUTPUT,
	@userpwd	VARCHAR(50),
	@firstname	NVARCHAR(50) = '',
	@lastname	NVARCHAR(50) = '',
	@groupid	INT,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-19
		Task: Insert user's info 
		DB: DBCUST/CUSTDB
		
		Revisions:
			- 20130121@Dan: change linked server DB052 to DBEAS, Write log on DBTXN server in case of DBLOG server failure
			- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
			- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
			- 20221013@Eden: Remove unused columns from Custinfo table [RedmineID: #179014]
			- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]

		Parameter's Explanation:
	*/
SET NOCOUNT ON

	DECLARE @startRun datetime  
		,@endRun datetime  
		,@duration int		
	
	SET @startRun=GETDATE()
	
	EXEC NAP_UserControl.dbo.EAS_UserCheckPermission @UserID = @userID ,@FuncKey = 'ManageUser', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
	
	IF EXISTS (SELECT 1 FROM Customer WITH(NOLOCK) WHERE username = @username)
		OR EXISTS(SELECT 1 FROM Dep_Customer_Archived WITH (NOLOCK) WHERE username= @username)
	BEGIN
		SELECT @ErrMsg = 'This username is not available',
			@ErrCode = 100
		RETURN
	END
	
	DECLARE @roleid		INT,
			@pwdexpiry	DATETIME,
			@closed		BIT
	
	SELECT @pwdexpiry = DATEADD (month,1,CURRENT_TIMESTAMP),
			@roleid   = 6,
			@closed	  = 0
	
	
	INSERT  INTO customer (username, userpwd, roleid, firstname, lastname, creator, pwdexpiry, creatdate)
	VALUES               (@username, @userpwd, @roleid, @firstname, @lastname, @userID, @pwdexpiry, current_timestamp);
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg ='Add user failed.',
			   @ErrCode = 101;
		RETURN;
	END
	
	SELECT @CustID = SCOPE_IDENTITY();
	
	INSERT  INTO dbo.custinfo (username, [custid], [currency], [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [MatchLimit], [VirtualMultiplier], [DisableOutright], [danger], [danger2], [danger3], [Enabled], [closed])
	VALUES                   (@username, @custid, NULL, @roleid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, @closed);
	
	IF @@ERROR <> 0
	BEGIN
		--roll back transaction
		DELETE FROM customer WITH(ROWLOCK) WHERE custid = @custid
		
		SELECT @ErrMsg = 'Add user failed.',
			   @ErrCode = 102;
		RETURN;
	END

	
	INSERT INTO NAP_UserControl.dbo.eaUserInfo (UserID, GroupID, enabled, creator, CreatedDate)
	VALUES (@CustID, @GroupID, 1, @userID, current_timestamp)
	
	IF @@ERROR <> 0
	BEGIN
		--roll back transaction
		DELETE FROM customer WITH(ROWLOCK) WHERE custid = @custid
		DELETE FROM custinfo WITH(ROWLOCK) WHERE custid = @custid
		
		SELECT @ErrMsg = 'Add user failed.',
			   @ErrCode = 103;
		RETURN;
	END
	
	/**************Write to Log table********************/
	DECLARE @LogData NVARCHAR(MAX)	
	SELECT @LogData = '<EAS_UserInfoAddNew>'+
						'<UserName>' + @Username + '</UserName>' +
						'<FirstName>' + COALESCE(@firstname,'') + '</FirstName>' +
						'<LastName>' + COALESCE(@lastname,'') + '<LastName>' +
						'<GroupID>' + COALESCE(CONVERT(VARCHAR(10),@groupID),'') + '</GroupID>' +
						'<IP>' + COALESCE(@IP,'') + '</IP>' +
					'</EAS_UserInfoAddNew>'

	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)   

	EXEC NAP_UserControl.[dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
		@custID = @custid, 
		@TrackingValue = @LogData, 
		@userid = @userID, 
		@TypeID = 1, 
		@actionid = 20004, 
		@duration = @duration
GO
