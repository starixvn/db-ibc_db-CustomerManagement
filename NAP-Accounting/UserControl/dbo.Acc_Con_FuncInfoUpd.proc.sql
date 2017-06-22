
ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoUpd]
	@FuncId int,
	@FuncName nvarchar(50),
	@FuncNote nvarchar(2000) = null,
	@FuncDesc nvarchar(50) = '',
	@FileNames varchar(MAX),
	@System nvarchar(50) = 'ACCOUNTING',	
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserId int,
	@ParentId int
AS
/*
Task: Update function info 
DB: DBPOLICY/BODB02 

Revision
	- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20110526@Tom: Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
	- 20110810@Jamie: Expand size of param @FileNames to MAX 
	- 20120604@Elodie: Modify the content of a log in User Control
					   Only update function's infomation if any changes
	- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
	- 20140721@Lukas: change function name from [UserControl] to [ManageFunction]	for creating new menu/function
*/
	SET NOCOUNT ON 
	DECLARE @LogData nvarchar(max),@Begin	DATETIME,@End	DATETIME,@Duration	INT;
	SET @Begin = GETDATE();
	--Check permission
	EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ManageFunction]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'ACCOUNTING'
	If @ErrCode <> 0
		RETURN
	IF exists (select 1 from acc_functioninfo with (NOLOCK) where system = @System and FuncName = @FuncName and FuncId <> @FuncId)
	BEGIN
		Select @ErrMsg = 	case @Language 
							when 'E' then N'This function name is already used.'
							when 'CS' then N'This function name is already used.'
							else N'This function name is already used.'
					end, @ErrCode = 101	
		return
	END 
	
	DECLARE @FuncName_old nvarchar(200), 
			@FuncNote_old nvarchar(2000),
			@FuncDesc_old nvarchar(200), 
			@FileNames_old VARCHAR(MAX), 
			@ParentId_old	int;

	--Get old values
	select  @FuncName_old = FuncName, @FuncNote_old = FuncNote, @FuncDesc_old = FuncDesc, @FileNames_old = FileNames, @ParentId_old = ParentId
	from acc_functioninfo with (nolock)
	where FuncID = @FuncId

	IF(@FuncName_Old <> @FuncName
	or @FuncNote_old <> @FuncNote
	or @FuncDesc_old <> @FuncDesc
	or @FileNames_old <> @FileNames
	or @ParentId_old <> @ParentId)
	Begin 
		update acc_functioninfo with (rowlock)
		set FuncName = @FuncName, FuncNote = @FuncNote, FuncDesc = @FuncDesc, ModifyDate = getdate(), FileNames = @FileNames, ParentId = @ParentId
		where FuncID = @FuncId

		/**************Write to Log table********************/
		Declare @ParentName_Old nvarchar(50), @ParentName nvarchar(50)
		select @ParentName_Old = FuncName from Acc_FunctionInfo with (NOLOCK) where FuncID = @ParentId_old
		select @ParentName = FuncName from Acc_FunctionInfo with (NOLOCK) where FuncID = @ParentId

		SELECT @LogData = '<Acc_Con_FuncInfoUpd><FunctionName><Old>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncName_Old),'')															+ '</Old>' +
															 '<New>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncName),'')																+ '</New></FunctionName>' +
											   '<FunctionNote><Old>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncNote_old),'')															+ '</Old>' +
															 '<New>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncNote),'')																+ '</New></FunctionNote>' +
											   '<FunctionDesc><Old>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncDesc_old),'')															+ '</Old>' +
															 '<New>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncDesc),'')																+ '</New></FunctionDesc>' +
											   '<FileNames><Old>'    + ISNULL([dbo].[f_EncodeXMLValue](@FileNames_old),'')															+ '</Old>' +
														  '<New>'    + ISNULL([dbo].[f_EncodeXMLValue](@FileNames),'')																+ '</New></FileNames>' +
											   '<ParentName><Old>'   + CASE WHEN @ParentId_old=0 Then 'NONE' Else IsNull(@ParentName_Old,convert(varchar(10),@ParentId_old)) End	+ '</Old>' +
														   '<New>'   + CASE WHEN @ParentId=0 Then 'NONE' Else IsNull(@ParentName,convert(varchar(10),@ParentId)) End				+ '</New></ParentName>' +
						  '</Acc_Con_FuncInfoUpd>'

		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		BEGIN TRY			  
			EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]
				@custID = @FuncId,
				@Doing = @LogData,
				@userid = @UserID,
				@TypeID =2,
				@actionid =1802,
				@duration = @Duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = '<Acc_Con_FuncInfoUpd> ' +								
								'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							   '</Acc_Con_FuncInfoUpd>'
							   
			EXEC WriteLog_UserLog @UserID = @UserID, 
						      @Doing = @LogData
		END CATCH
	End

GO
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoUpd] TO [vnteam]