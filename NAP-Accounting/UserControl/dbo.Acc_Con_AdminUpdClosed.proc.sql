ALTER PROCEDURE [dbo].[Acc_Con_AdminUpdClosed]
	@CustID INT, 
	@Closed BIT, 
	@UserID INT, 
	@isABS	BIT = 0,
	@Language VARCHAR (2)='E', 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
Created: 
Task : Update status close for account in User Control
DB: DBTXN/BODB02
Original:

Revisions:
	- 20100108@Daniel: Add reset logincount when open account
	- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
	- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
	- 20120220@Johnson: Check ABS system
	- 20120604@Elodie: Modify the content of a log in User Control
					   Only update admin's status if any changes
	- 20130118@Elodie: Change link server DB03 to DBPOLICY			  
					   Write more log on DBTXN server in case of DBLOG server failure					
Param's Explanation:

*/
SET NOCOUNT ON;
DECLARE @LogData AS NVARCHAR (500), 
@Begin AS DATETIME, 
@End AS DATETIME, 
@Duration AS INT;
SET @Begin = GETDATE();

DECLARE @funcname VARCHAR(50)
IF @isABS = 1 
	SELECT @funcname = '[ABSAdminUserControl]'
ELSE 
	SELECT @funcname = '[UserControl]'
	
--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @UserID, @funcname = @funcname, @System = @System, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
    RETURN;
--end

DECLARE @Old_Closed AS BIT, @LoginCount AS INT;

SELECT @Old_Closed = closed
FROM   custinfo WITH (NOLOCK)
WHERE  custid = @custid;

SELECT @LoginCount = logincount
FROM   customer WITH (NOLOCK)
WHERE  custid = @custid;

IF(@Old_Closed <> @Closed)
Begin
	UPDATE  custinfo WITH (ROWLOCK, UPDLOCK)
		SET Closed = @Closed
	WHERE   custid = @CustID;

	IF (@Old_Closed = 1
		AND @Closed = 0
		AND @LoginCount > 5)
		UPDATE  customer WITH (ROWLOCK, UPDLOCK)
			SET logincount = 0
		WHERE   custid = @custid;
	    
	/**** Write to log table ***/
	SELECT @LogData = '<Acc_Con_AdminUpdClosed><Status>' + CASE @closed WHEN 0 THEN 'Active' ELSE 'Closed' END + '</Status></Acc_Con_AdminUpdClosed>'

	SET @End = GETDATE();
	SET @Duration = DATEDIFF(millisecond, @Begin, @End);
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
				@custID = @custid, 
				@Doing = @LogData, 
				@userid = @UserID, 
				@TypeID = 1, 
				@actionid = 1705, 
				@duration = @Duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_Con_AdminUpdClosed> ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'<Status>' + CASE @closed WHEN 0 THEN 'Active' ELSE 'Closed' END + '</Status></Acc_Con_AdminUpdClosed>'
							
		EXEC bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
				@custID = @custid, 
				@Doing = @LogData, 
				@userid = @UserID, 
				@TypeID = 1, 
				@actionid = 1705, 
				@duration = @Duration
	END CATCH
End

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminUpdClosed] TO [vnteam];
GO
GRANT EXECUTE ON [dbo].[Acc_Con_AdminUpdClosed] TO [bodbAdminNet];

