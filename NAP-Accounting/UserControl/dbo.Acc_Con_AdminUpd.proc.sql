ALTER PROCEDURE [dbo].[Acc_Con_AdminUpd]
	@CustID INT, 
	@FirstName NVARCHAR (50), 
	@LastName NVARCHAR (50), 
	@isABS BIT = 0,
	@UserID INT, 
	@GroupID INT, 
	@Language VARCHAR (2)='E', 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Update info of account in User Control
	DB: DBTXN/BODB02
 
	Revisions:
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
		- 20120224@Johnson: check ABS system
		- 20120604@Elodie: Modify the content of a log in User Control
						   Only update admin's infomation if any changes
		- 20130118@Elodie: Change link server DB03 to DBPOLICY	
						   Write more log on DBTXN server in case of DBLOG server failure					
		
*/
SET NOCOUNT ON;
DECLARE @LogData AS NVARCHAR (500), 
@permission VARCHAR(50),
@Begin AS DATETIME, 
@End AS DATETIME, 
@Duration AS INT;
SET @Begin = GETDATE();

IF @isABS = 1
	SELECT @permission = '[ABSAdminUserControl]'
ELSE 
	SELECT @permission = '[UserControl]'
	
--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = @permission, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
    RETURN;
--end

Declare @db_FirstName NVARCHAR (50), @db_LastName NVARCHAR (50), @db_GroupID int
select @db_GroupID = groupid from DBPOLICY.bodb02.dbo.accCustomer_1 with (NOLOCK) where custid = @CustID
select @db_FirstName = firstname, @db_LastName = lastname from customer with (NOLOCK) where custid = @CustID

if(@db_GroupID <> @GroupID)
Begin
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_AdminGroupUpd @CustID = @CustID, @UserID = @UserID, @GroupID = @GroupID, @Language = @Language, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
	IF @ErrCode <> 0
		RETURN;
End

IF(@db_FirstName <> @FirstName or @db_LastName <> @LastName)
Begin
	UPDATE  customer WITH (ROWLOCK, UPDLOCK)
		SET firstname = @FirstName,
			LastName  = @LastName
	WHERE   custid = @CustID;
	IF @@ERROR <> 0
		BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Error occurs.Update unsuccessfully.' WHEN 'CS' THEN N'Error occurs.Update unsuccessfully.' WHEN 'J' THEN N'Error occurs.Update unsuccessfully.' ELSE N'Error occurs.Update unsuccessfully.' END,
				   @ErrCode = 102;
			RETURN;
		END

	/**** Write to log table ***/
	SELECT @LogData =	'<Acc_Con_AdminUpd><FirstName><Old>' + ISNULL([dbo].[f_EncodeXMLValue](@db_FirstName),'')	+ '</Old>' +
													 '<New>' + ISNULL([dbo].[f_EncodeXMLValue](@FirstName),'')		+ '</New></FirstName>' +
										  '<LastName><Old>'  + ISNULL([dbo].[f_EncodeXMLValue](@db_LastName),'')	+ '</Old>' +
													'<New>'  + ISNULL([dbo].[f_EncodeXMLValue](@LastName),'')		+ '</New></LastName>' +
						'</Acc_Con_AdminUpd>'

	SET @End = GETDATE();
	SET @Duration = DATEDIFF(millisecond, @Begin, @End);
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
				@custID = @custid, 
				@Doing = @LogData, 
				@userid = @UserID, 
				@TypeID = 1, 
				@actionid = 1704, 
				@duration = @Duration
	END TRY
	BEGIN CATCH
		SELECT @LogData =	'<Acc_Con_AdminUpd> ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'<FirstName><Old>' + ISNULL([dbo].[f_EncodeXMLValue](@db_FirstName),'')	+ '</Old>' +
									   '<New>' + ISNULL([dbo].[f_EncodeXMLValue](@FirstName),'')    + '</New></FirstName>' +
							'<LastName><Old>'  + ISNULL([dbo].[f_EncodeXMLValue](@db_LastName),'')	+ '</Old>' +
									  '<New>'  + ISNULL([dbo].[f_EncodeXMLValue](@LastName),'')		+ '</New></LastName>' +
						'</Acc_Con_AdminUpd>'
		EXEC bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
				@custID = @custid, 
				@Doing = @LogData, 
				@userid = @UserID, 
				@TypeID = 1, 
				@actionid = 1704, 
				@duration = @Duration
	END CATCH				
End

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminUpd] TO [vnteam];
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminUpd] TO [bodbAdminNet];

