ALTER PROCEDURE [dbo].[Acc_OperatorDel]
	@CustID INT, 
	@Language VARCHAR (2)='E', 
	@UserID INT=0, 
	@ReturnErrCode BIT=0, 
	@ErrCode INT=0 OUTPUT, 
	@ErrMsg NVARCHAR (200)='' OUTPUT
AS
/*
	Created by: []
	Task: Delete Customer
	DB: DBTXN/BODB02
	Original: DelOperator.asp

	Revisions:
		- 20080213@phuc:	Check permission for account site
		- 20080223@Thien: Not allow to delete operator since it's related to User Control in Admin.NET
		- 20110526@Tom: Remove condition @System and Write log into table DB03.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20110624@Tom: Change DB02 to DBTRANS (Splitting DB02 to DBPros and DBTRANS)
		- 20120605@Sophia: Modify @Logdata and change the range of ActionID
		- 20130118@Elodie: Change link server DB03 to DBPOLICY	
						   Write more log on DBTXN server in case of DBLOG server failure
*/
SET NOCOUNT ON;
DECLARE @LogData AS NVARCHAR (200), 
@Begin AS DATETIME, 
@End AS DATETIME, 
@Duration AS INT;
SET @Begin = GETDATE();
--Check permission for account site: @phuc20080213
EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid = @userid, @funcname = '[UserControl]', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
IF @ErrCode <> 0
    BEGIN
        IF @ReturnErrCode = 0
            RAISERROR (@ErrMsg, 16, 1);
        RETURN;
    END
--end
-------------------
--Thien@20080223: Not allow to delete operator since it's related to User Control in Admin.NET
SELECT @ErrMsg = 'Not allow to delete operator here! Please contact Thien''s team for information!',
       @ErrCode = 100;
RETURN;
-------------------
SELECT @LogData = '<Acc_OperatorDel>'+
						'<UserName>'+ISNULL([dbo].[f_EncodeXMLValue]([dbo].[f_CustNameByCustID](@custID)),'')+'</UserName>'+
					'</Acc_OperatorDel>'	

DELETE Customer WITH (ROWLOCK)
WHERE  CustID = @CustID;
DELETE CustInfo WITH (ROWLOCK)
WHERE  CustID = @CustID;
/**** Write to log table ***/
SET @End = GETDATE();
SET @Duration = DATEDIFF(millisecond, @Begin, @End);
BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
		@custID = @custID, 
		@Doing = @LogData, 
		@userid = @UserID, 
		@TypeID = 1, 
		@actionid = 1850, 
		@duration = @Duration
END TRY
BEGIN CATCH
	SELECT @LogData = '<Acc_OperatorDel> ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
						'<UserName>'+ISNULL([dbo].[f_EncodeXMLValue]([dbo].[f_CustNameByCustID](@custID)),'')+'</UserName>'+
					'</Acc_OperatorDel>'	
	
	EXEC bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl] 
		@custID = @custID, 
		@Doing = @LogData, 
		@userid = @UserID, 
		@TypeID = 1, 
		@actionid = 1850, 
		@duration = @Duration
END CATCH

GO
SET QUOTED_IDENTIFIER OFF;


GO
SET ANSI_NULLS ON;


GO
GRANT EXECUTE ON [dbo].[Acc_OperatorDel] TO [bodbAdminNet]

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_OperatorDel] TO [vnteam]

