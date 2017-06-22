ALTER PROCEDURE [dbo].[Acc_Con_AdminIns]
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
SET NOCOUNT ON;
/*
Created: 
Task : Add account in User control
DB: DBTXN/bodb02
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
	
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
DECLARE @Begin AS DATETIME;
SET @Begin = GETDATE();
--Check permission for account site: @phuc20080213
DECLARE @funcname VARCHAR(50)

IF @isABS = 1 
	SELECT @funcname = '[ABSAdminUserControl]'
ELSE 
	SELECT @funcname = '[UserControl]'

	
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @userid, @funcname = @funcname, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
    RETURN;
DECLARE @pwdexpiry AS DATETIME, 
@roleid AS INT, 
@closed AS BIT;
SELECT @RoleID = 6,
       @pwdexpiry = DATEADD(month, 1, CURRENT_TIMESTAMP),
       @closed = 0;
IF EXISTS (SELECT 1
           FROM   customer WITH (NOLOCK)
           WHERE  username = @username)
    BEGIN
        SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This username is not available. ' WHEN 'CS' THEN N'This username is not available. ' WHEN 'J' THEN N'This username is not available. ' ELSE N'This username is not available. ' END,
               @ErrCode = 102;
        RETURN;
    END
BEGIN TRANSACTION;
INSERT  INTO customer (username, userpwd, roleid, firstname, lastname, creator, pwdexpiry)
VALUES               (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry);
SELECT @CustID = @@IDENTITY;
INSERT  INTO dbo.custinfo (username, [custid], [currency], [MaxPerMatch], [MaxPerMatch2], [MaxPerMatch3], [MaxPerMatch5], [MaxPerMatch8], [MaxPerMatch10], [MaxPerMatch11], [MaxPerMatch12], [MaxPerMatch99], [Maxpermatch151], [maxpermatch201], [MaxPerMatch161], [MaxPerMatch99MP], [MaxPerBall161], [MaxPerMatch151_OT], [roleid], [mrecommend], [recommend], [dangercust], [autosuspend], [reject], [credit], [MatchLimit], [VirtualMultiplier], [DisableHorseRacing], [DisableFinancial], [DisableCasino], [DisableOutright], [DisableOpenTote], [DisableBingo], [DisableNumber], [SyncCasino], [danger], [danger2], [danger3], [Enabled], [closed])
VALUES                   (@username, @custid, NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @roleid, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, @closed);
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

EXEC DBPOLICY.bodb02.dbo.Acc_Con_AdminPolicyIns @CustID = @Custid, @Userid = @UserID, @GroupID = @GroupID, @System = @System;
/**************Write to Log table ********************/
DECLARE @LogData AS NVARCHAR (500), 
@End AS DATETIME, 
@Duration AS INT;
--Get Group Name from DB03.BODB02
DECLARE @GroupName NVARCHAR(50)
EXEC @GroupName = DBPOLICY.bodb02.[dbo].[f_Get_GroupNameByGroupID] @GroupID
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

GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminIns] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminIns] TO [vnteam];

