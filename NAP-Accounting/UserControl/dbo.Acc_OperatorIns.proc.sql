/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_OperatorIns]
	@custid INT OUTPUT, 
	@firstname NVARCHAR (50), 
	@lastname NVARCHAR (50), 
	@address NVARCHAR (80), 
	@postal NVARCHAR (50), 
	@city NVARCHAR (50), 
	@state NVARCHAR (50), 
	@country NVARCHAR (50), 
	@phone NVARCHAR (50), 
	@mobilephone NVARCHAR (50), 
	@fax NVARCHAR (50), 
	@email NVARCHAR (50), 
	@creator INT, 
	@username NVARCHAR (50), 
	@userpwd NVARCHAR (50), 
	@roleid INT, 
	@ReturnErrCode BIT=0, 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@Language VARCHAR (2)='E'
AS
DECLARE @pwdexpiry AS DATETIME;
/*
Created: 
Task : Add account in User control 
DB: DBCUST/CUSTDB
Original:saveoperator.asp

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20101112@Henry: add Maxperball161
	- 20110526@Tom: Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
	- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
	- 20120605@Sophia: Modify @Logdata and change the range of ActionID
	- 20130118@Elodie: Change link server DB03 to DBPOLICY	
					   Write more log on DBTXN server in case of DBLOG server failure
	- 20130710@Kathy: Synchronize user data between Accounting and AdminSite: Insert data to AdminSiteUser table
	- 20180808@Helen: DB05.DBPOLICY migration - [Redmine:99462]
	- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
	- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
	- 20190905@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
	- 20221013@Eden: Remove unused columns from Custinfo table [RedmineID: #179014]
	- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]

Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON;
DECLARE @LogData AS NVARCHAR (200), 
@Begin AS DATETIME, 
@End AS DATETIME, 
@Duration AS INT;
SET @Begin = GETDATE();
--Check permission for account site: @phuc20080213
EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid = @creator, @funcname = '[UserControl]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
    BEGIN
        IF @ReturnErrCode = 0
            RAISERROR (@ErrMsg, 16, 1);
        RETURN;
    END
--end

DECLARE @IsExists BIT 
EXEC Age_CustomerCheckExists @username = @username, @IsExists = @IsExists OUTPUT

IF @IsExists = 1
BEGIN
    SELECT @ErrMsg = 'This username is not available. ',
            @ErrCode = 101;
    IF @ReturnErrCode = 0
        RAISERROR (@ErrMsg, 16, 1);
    RETURN;
END

SELECT @pwdexpiry = dateadd(dd, 30, getdate());
BEGIN TRANSACTION;
INSERT  INTO customer (username, firstname, lastname, phone, mobilephone, fax, email, address, city, state, country, postal, userpwd, roleid, pwdexpiry, Creatdate, creator)
VALUES               (@username, @firstname, @lastname, @phone, @mobilephone, @fax, @email, @address, @city, @state, @country, @postal, @userpwd, @roleid, @pwdexpiry, getdate(), @creator);
SELECT @CustID = @@Identity;
INSERT  INTO [dbo].[custinfo] (username, [custid], [currency], [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [closed], [MatchLimit], [VirtualMultiplier], [DisableOutright], [danger], [danger2], [danger3], [Enabled])
VALUES                       (@username, @custid, NULL, @roleid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);
IF @@ERROR <> 0
    BEGIN
        ROLLBACK;
        SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Add customer failed.' WHEN 'CS' THEN N'Add customer failed.' WHEN 'J' THEN N'Add customer failed.' ELSE N'Add customer failed.' END;
        IF @ReturnErrCode = 0
            RAISERROR (@ErrMsg, 16, 1);
        RETURN;
    END
COMMIT TRANSACTION;

BEGIN TRY
		IF(@roleid >4)
			EXEC DBPRO.bodb02.dbo.Dot_Admin_Add_AdminSiteUser @custid, @username, @userpwd, @creator
END TRY
BEGIN CATCH
	DELETE FROM Customer WHERE custid = @custid
	DELETE FROM custInfo WHERE custid = @custid
	SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Add customer failed.' WHEN 'CS' THEN N'Add customer failed.' WHEN 'J' THEN N'Add customer failed.' ELSE N'Add customer failed.' END;
		IF @ReturnErrCode = 0
			RAISERROR (@ErrMsg, 16, 1);
		RETURN;
END catch
	
/**** Write to log table ***/
SELECT @LogData =	'<Acc_OperatorIns>'+
							'<FirstName>'+ ISNULL([dbo].[f_EncodeXMLValue](@firstname),'') +'</FirstName>'+
							'<LastName>'+ ISNULL([dbo].[f_EncodeXMLValue](@lastname),'') + '</LastName>'+
							'<Address>'+ ISNULL([dbo].[f_EncodeXMLValue](@address),'') + '</Address>'+
							'<State>'+ ISNULL([dbo].[f_EncodeXMLValue](@state),'') + '</State>'+
							'<Country>'+ ISNULL([dbo].[f_EncodeXMLValue](@country),'') + '</Country>'+
							'<Phone>'+ ISNULL([dbo].[f_EncodeXMLValue](@phone),'') + '</Phone>'+
							'<MobilePhone>'+ ISNULL([dbo].[f_EncodeXMLValue](@mobilephone),'') + '</MobilePhone>'+
							'<Fax>'+ ISNULL([dbo].[f_EncodeXMLValue](@fax),'') + '</Fax>'+
							'<Email>'+ ISNULL([dbo].[f_EncodeXMLValue](@email),'') + '</Email>'+
							'<Roleid>'+ ISNULL(CONVERT(VARCHAR(10),@roleid),'') + '</Roleid>'+
							'<Postal>'+ ISNULL([dbo].[f_EncodeXMLValue](@postal),'') + '</Postal>'+
							'<City>'+ ISNULL([dbo].[f_EncodeXMLValue](@city),'') + '</City>'+
							'<UserName>'+ISNULL([dbo].[f_EncodeXMLValue](@username),'')+'</UserName>'+
					'</Acc_OperatorIns>'					

SET @End = GETDATE();
SET @Duration = DATEDIFF(millisecond, @Begin, @End)
BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.[WriteLog_UserLog_UserControl] 
		@custID = @custid, 
		@Doing = @LogData, 
		@userid = @creator, 
		@TypeID = 1, 
		@actionid = 1851, 
		@duration = @Duration
END TRY
BEGIN CATCH
	SELECT @LogData =	'<Acc_OperatorIns> ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'<FirstName>'+ ISNULL([dbo].[f_EncodeXMLValue](@firstname),'') +'</FirstName>'+
							'<LastName>'+ ISNULL([dbo].[f_EncodeXMLValue](@lastname),'') + '</LastName>'+
							'<Address>'+ ISNULL([dbo].[f_EncodeXMLValue](@address),'') + '</Address>'+
							'<State>'+ ISNULL([dbo].[f_EncodeXMLValue](@state),'') + '</State>'+
							'<Country>'+ ISNULL([dbo].[f_EncodeXMLValue](@country),'') + '</Country>'+
							'<Phone>'+ ISNULL([dbo].[f_EncodeXMLValue](@phone),'') + '</Phone>'+
							'<MobilePhone>'+ ISNULL([dbo].[f_EncodeXMLValue](@mobilephone),'') + '</MobilePhone>'+
							'<Fax>'+ ISNULL([dbo].[f_EncodeXMLValue](@fax),'') + '</Fax>'+
							'<Email>'+ ISNULL([dbo].[f_EncodeXMLValue](@email),'') + '</Email>'+
							'<Roleid>'+ ISNULL(CONVERT(VARCHAR(10),@roleid),'') + '</Roleid>'+
							'<Postal>'+ ISNULL([dbo].[f_EncodeXMLValue](@postal),'') + '</Postal>'+
							'<City>'+ ISNULL([dbo].[f_EncodeXMLValue](@city),'') + '</City>'+
							'<UserName>'+ISNULL([dbo].[f_EncodeXMLValue](@username),'')+'</UserName>'+
					'</Acc_OperatorIns>'
	EXEC bodb_CustomerLog.dbo.[WriteLog_UserLog_UserControl] 
		@custID = @custid, 
		@Doing = @LogData, 
		@userid = @creator, 
		@TypeID = 1, 
		@actionid = 1851, 
		@duration = @Duration
END CATCH
GO