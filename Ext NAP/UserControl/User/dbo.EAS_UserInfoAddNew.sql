/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoAddNew]
(	@userID	INT = 0,	
	@Username	VARCHAR(50),
	@custid		INT = 0,
	@userpwd	VARCHAR(50),
	@firstname	NVARCHAR(50) = '',
	@lastname	NVARCHAR(50) = '',
	@groupid	INT,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT,
	@LogData NVARCHAR(MAX)	= '' OUTPUT
)
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
			- 20240704@Louisa: Scaleout DBCUST [Redmine:#199915]
			- 20241119@Eden: set srecommend = 0 [Redmine:#206823]

		Parameter's Explanation:
	*/
SET NOCOUNT ON

	--DECLARE @startRun datetime  
	--	,@endRun datetime  
	--	,@duration int		
	
	--SET @startRun=GETDATE()
	
	DECLARE @roleid		INT,
			@pwdexpiry	DATETIME,
			@closed		BIT
	
	SELECT @pwdexpiry = DATEADD (month,1,CURRENT_TIMESTAMP),
			@roleid   = 6,
			@closed	  = 0

	BEGIN TRY
		EXEC Acc_CustomerIns
			@FirstName	= @firstname
			,@LastName	= @lastname
			,@UserName	= @username
			,@UserPwd	= @userpwd
			,@pwdexpiry = @pwdexpiry
			,@roleid	= @roleid
			,@closed	= @closed	
			,@CustID	= @custid
			,@creator	= @userID
			,@ErrCode	= @ErrCode OUTPUT
			,@ErrMsg	= @ErrMsg OUTPUT
			,@srecommend = 0 
	
			IF ISNULL(@ErrCode,0) > 0
			BEGIN
				EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
				RETURN;
			END

		INSERT  INTO dbo.custinfo (username, [custid], [currency], [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [MatchLimit], [VirtualMultiplier], [DisableOutright], [danger], [danger2], [danger3], [Enabled], [closed],srecommend)
		VALUES                   (@username, @custid, NULL, @roleid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, @closed,0);
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg ='Add user failed.',
				   @ErrCode = 101;

			EXEC Acc_CustomerInsUserInfo_Rollback @CustID = @CustID
			RETURN;
	END CATCH
	
	/**************Write to Log table********************/
	--DECLARE @LogData NVARCHAR(MAX)	
	SELECT @LogData = '<EAS_UserInfoAddNew>'+
						'<UserName>' + @Username + '</UserName>' +
						'<FirstName>' + COALESCE(@firstname,'') + '</FirstName>' +
						'<LastName>' + COALESCE(@lastname,'') + '<LastName>' +
						'<GroupID>' + COALESCE(CONVERT(VARCHAR(10),@groupID),'') + '</GroupID>' +
						'<IP>' + COALESCE(@IP,'') + '</IP>' +
					'</EAS_UserInfoAddNew>'

GO
