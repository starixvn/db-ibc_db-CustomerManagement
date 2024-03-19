/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_Con_AdminIns]
	@FirstName NVARCHAR (50), 
	@LastName NVARCHAR (50), 
	@UserName NVARCHAR (50), 
	@UserPwd NVARCHAR (50)='', 
	@CustID INT OUTPUT, 
	@UserID INT, 
	@GroupID INT, 
	@isABS	BIT = 0,	
	@System VARCHAR (50)='ACCOUNTING', 
	@Language VARCHAR (2)='E', 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT
AS
/*
Created: 
Task : Add account in User control
DB: DBCUST/CUSTDB
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20101112@Henry: add Maxperball161
	- 20110526@Tom: Remove condition @System and Write log into table DBlog.bodb_CustomerLog.dbo.UserLog_UserControl"
	- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
	- 20120220@Johnson: Check ABS system
	- 20120601@Sophia: Modify @LogData
	- 20130118@Elodie: Change link server DB03 to DBPOLICY
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20141126@Dom: Synchronize user data between Accounting and AdminSite: Insert data to AdminSiteUser table
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
	- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
	- 20190828@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
	- 20220517@Winfred: Insert new OTP Login requried for VPN's users [redmine:170994]
	- 20221013@Eden: Remove unused columns from Custinfo table [RedmineID: #179014]
	- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
BEGIN

	SET NOCOUNT ON;

	DECLARE @Begin AS DATETIME;
	SET @Begin = GETDATE();
	--Check permission for account site: @phuc20080213
	DECLARE @funcname VARCHAR(50)

	IF @isABS = 1 
		SELECT @funcname = '[ABSAdminUserControl]'
	ELSE 
		SELECT @funcname = '[UserControl]'

		
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @userid, @funcname = @funcname, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
	IF @ErrCode <> 0
		RETURN;
	DECLARE @pwdexpiry AS DATETIME, @roleid AS INT, @closed AS BIT
	SELECT @RoleID = 6,
		   @pwdexpiry = DATEADD(month, 1, CURRENT_TIMESTAMP),
		   @closed = 0

	--check duplicate username
	DECLARE @IsExists BIT 
	EXEC Age_CustomerCheckExists @username = @username, @IsExists = @IsExists OUTPUT

	IF @IsExists = 1
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This username is not available. ' WHEN 'CS' THEN N'This username is not available. ' WHEN 'J' THEN N'This username is not available. ' ELSE N'This username is not available. ' END,
				@ErrCode = 102;
		RETURN;
	END

	BEGIN TRANSACTION;
	INSERT  INTO customer (username, userpwd, roleid, firstname, lastname, creator, pwdexpiry)
	VALUES               (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry);
	SELECT @CustID = @@IDENTITY;
	INSERT  INTO dbo.custinfo (username, [custid], [currency], [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [MatchLimit], [VirtualMultiplier], [DisableOutright], [danger], [danger2], [danger3], [Enabled], [closed])
	VALUES                   (@username, @custid, NULL, @roleid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, @closed);
	IF @@ERROR <> 0
		BEGIN
			ROLLBACK;
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Add customer failed.' WHEN 'CS' THEN N'Add customer failed.' WHEN 'J' THEN N'Add customer failed.' ELSE N'Add customer failed.' END,
				   @ErrCode = 103;
			RETURN;
		END
	COMMIT TRANSACTION;

	/* Insert data to AdminSiteUser */ 	
	BEGIN TRY
		IF(@roleid >4)
			EXEC DBPRO.bodb02.dbo.Dot_Admin_Add_AdminSiteUser @custid, @username, @userpwd, @UserID
	END TRY
	BEGIN CATCH
		DELETE FROM Customer WHERE custid = @custid
		DELETE FROM custInfo WHERE custid = @custid
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Add customer failed.' WHEN 'CS' THEN N'Add customer failed.' WHEN 'J' THEN N'Add customer failed.' ELSE N'Add customer failed.' END;
			RETURN;
	END CATCH

	EXEC NAP_UserControl.dbo.Acc_Con_AdminPolicyIns @CustID = @Custid, @Userid = @UserID, @GroupID = @GroupID, @System = @System;

	EXEC NAP_UserControl.dbo.NAP_Admin_OTPIns 
		@CustId			= @CustId,
		@System			= 'NAP',
		@UserId			= @UserID,
		@ErrCode		= @ErrCode OUTPUT,
		@ErrMsg			= @ErrMsg OUTPUT

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = @ErrCode, @ErrMsg = @ErrMsg
		RETURN
	END
	/**************Write to Log table ********************/
	DECLARE @LogData AS NVARCHAR (500), 
	@End AS DATETIME, 
	@Duration AS INT;
	--Get Group Name from DB03.BODB02
	DECLARE @GroupName NVARCHAR(50)
	EXEC @GroupName = NAP_UserControl.dbo.f_Get_GroupNameByGroupID @GroupID
	SELECT @LogData = '<Acc_Con_AdminIns>'+
							'<FirstName>' + ISNULL([dbo].[f_EncodeXMLValue](@firstname),'') + '</FirstName>'+
							'<LastName>' + ISNULL([dbo].[f_EncodeXMLValue](@lastname),'') + '</LastName>'+
							'<ToGroup>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</ToGroup>'+
					  '</Acc_Con_AdminIns>'

	SET @End = GETDATE()
	SET @Duration = DATEDIFF(millisecond, @Begin, @End)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] @custID = @CustID, @Doing = @LogData, @userid = @UserID, @TypeID = 1, @actionid = 1701, @duration = @Duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_Con_AdminIns> ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'<FirstName>' + ISNULL([dbo].[f_EncodeXMLValue](@firstname),'') + '</FirstName>'+
							'<LastName>' + ISNULL([dbo].[f_EncodeXMLValue](@lastname),'') + '</LastName>'+
							'<ToGroup>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</ToGroup>'+	
					  '</Acc_Con_AdminIns>'
		EXEC bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] @custID = @CustID, @Doing = @LogData, @userid = @UserID, @TypeID = 1, @actionid = 1701, @duration = @Duration			  
	END CATCH
END
GO
