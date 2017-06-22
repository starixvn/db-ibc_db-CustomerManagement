
ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoDel]
	@FuncID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
AS

/*
	Created by: []
	Task: Delete function
	DB: DBPOLICY/BODB02 
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20120604@Elodie: Modify the content of a log in User Control
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
		- 20140721@Lukas: change function name from [UserControl] to [ManageFunction]	for creating new menu/function
*/ 
SET NOCOUNT ON 
DECLARE @LogData nvarchar(200),@Begin	DATETIME,@End	DATETIME,@Duration	INT
SET @Begin = GETDATE();

--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ManageFunction]',@System='ACCOUNTING',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

if exists (select 1 from acc_functioninfo with (nolock) where ParentId = @FuncId and ParentId <> FuncId)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'Error occurs. This function has sub function belong to, so you can not delete!'
					when 'CS' then N'Error occurs. This function has sub function belong to, so you can not delete!'
					else N'Error occurs. This function has sub function belong to, so you can not delete!'
			end, @ErrCode = 102
	return
END

Declare @FuncName nvarchar(50)
select @FuncName = FuncName from Acc_FunctionInfo with (NOLOCK) where FuncID = @FuncID

SELECT @LogData = '<Acc_Con_FuncInfoDel><FunctionName>' + IsNull(@FuncName,'FuncID:'+convert(varchar(10),@FuncID)) + '</FunctionName></Acc_Con_FuncInfoDel>'
			
BEGIN TRANSACTION
	DELETE FROM Acc_GroupPolicy_1 where FuncId=@FuncId
	DELETE FROM Acc_MemberPolicy_1 where FuncId=@FuncId
	DELETE FROM acc_functioninfo where FuncId=@FuncId
	IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			select @ErrMsg = case @Language 
						when 'E' then 'Delete function failed.'
						when 'CS' then N'Delete function failed.'
						when 'J' then N'Delete function failed.'
						else N'Delete function failed.'
					end, @ErrCode = 103
			return
		END
COMMIT TRANSACTION

/**** Write to log table ***/

SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
BEGIN TRY		  
	EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]
		@custID = @FuncId,
		@Doing = @LogData,
		@userid = @UserID,
		@TypeID =2,
		@actionid =1800,
		@duration = @Duration  
END TRY
BEGIN CATCH
	SELECT @LogData = '<Acc_Con_FuncInfoDel> ' +						
						'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
						'</Acc_Con_FuncInfoDel>'
						
	EXEC WriteLog_UserLog @UserID = @UserID, 
						  @Doing = @LogData
END CATCH


GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoDel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoDel] TO [bodbAdminNet]