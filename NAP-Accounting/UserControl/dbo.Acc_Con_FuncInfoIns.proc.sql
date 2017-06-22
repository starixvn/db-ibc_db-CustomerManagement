
ALTER PROCEDURE  [dbo].[Acc_Con_FuncInfoIns]
	@FuncId int output,
	@FuncName nvarchar(50),
	@FuncNote nvarchar(2000) = null,
	@FuncDesc nvarchar(50) = '',
	@DisplayOrder int = 1,
	@ParentId int = null,
	@FileNames varchar(MAX),
	@System nvarchar(50) = 'ACCOUNTING',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int 
AS
/*
	Created by: []
	Task: Insert a new function or sub one into User Control 
	DB: DBPOLICY/BODB02 
	
	Revisions:
		- 20100703@Jamie: Modify to insert policy default = 0 
		- 20101101@Steven: Insert ParentId = 0 for root level
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20110810@Jamie: Expand size of param @FileNames to MAX 
		- 20120604@Elodie: Modify the content of a log in User Control
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
		- 20140721@Lukas: change function name from [UserControl] to [ManageFunction]	for creating new menu/function
*/
	SET NOCOUNT ON 
	DECLARE @LogData nvarchar(max),@Begin	DATETIME,@End	DATETIME,@Duration	INT;
	SET @Begin = GETDATE();

	--Check permission for account site
	EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[ManageFunction]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'ACCOUNTING'
	If @ErrCode <> 0
		RETURN
	--end
	--Check funcname
	if exists (select 1 from acc_functioninfo with (nolock) where System = @System and FuncName = @FuncName)
		begin
			Select @ErrMsg = 	case @Language 
					when 'E' then N'This function name is already used.'
					when 'CS' then N'This function name is already used.'
					else N'This function name is already used.'
			end, @ErrCode = 102
			return
		end
	if @ParentId is not null
		begin
			if not exists (select 1 from acc_functioninfo with (nolock) where FuncId = @ParentId)
			begin
				Select @ErrMsg = 	case @Language 
					when 'E' then N'Parent function does not exist or is invalid.'
					when 'CS' then N'Parent function does not exist or is invalid.'
					else N'Parent function does not exist or is invalid.'
				end, @ErrCode = 102
				return
			end
		end
		
	BEGIN TRANSACTION
		if @ParentId is not null
			select @DisplayOrder = max(DisplayOrder)+1 from acc_functioninfo with (nolock) where FuncId = @ParentId
		else
			select @DisplayOrder = 1

		insert into acc_functioninfo(FuncName, FuncNote, FuncDesc, FuncRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentId, FileNames, System)
		values (@FuncName, @FuncNote, @FuncDesc, 3, getdate(), getdate(), @DisplayOrder, @UserId, isnull(@ParentId, 0), @FileNames, @System)	

		select @FuncId = @@IDENTITY
		--Insert data to acc_grouppolicy table
		if @ParentId is not null
			begin		
				-- policy = 0 when inserting 
				--Insert into Acc_GroupPolicy and AccCustomer
				insert into Acc_GroupPolicy_1(FuncId, GroupId, Policy, CreateDate, ModifyDate, Creator)
				select	@FuncId, GroupId, 0 , getdate(), getdate(), @UserId/*0:Policy*/
					from acc_GroupPolicy_1 with (nolock)	where FuncId = @ParentId
				--add list custid is used on parentid
				insert into Acc_MemberPolicy_1(CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
				select	custid, @FuncId, 0 , getdate(), getdate(), @UserID /*0:Policy*/
					from acc_MemberPolicy_1 with (nolock)		where funcId = @ParentId

			end
		else
			begin
				insert into Acc_GroupPolicy_1(FuncId, GroupId, Policy, CreateDate, ModifyDate, Creator)
				Select @FuncId, GroupId, 0, getdate(), getdate(), @UserId
				from Acc_GroupInfo_1 grp with (nolock)	where System = @System				
				
				--Add user from accounting system
				insert into Acc_MemberPolicy_1(CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
					select custid, @FuncId, 0, getdate(), getdate(), @UserID
					from accCustomer_1 with (nolock)
			end
		
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add function failed.'
							when 'CS' then N'Add function failed.'
							when 'J' then N'Add function failed.'
							else N'Add function failed.'
						end, @ErrCode = 103
		return
	END
	COMMIT TRANSACTION
	/**** Write to log table ***/
	Declare @ParentName nvarchar(50)
	select @ParentName = FuncName from Acc_FunctionInfo with (NOLOCK) where FuncID = @ParentId

	SELECT @LogData = '<Acc_Con_FuncInfoIns><FunctionName>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncName),'')														+ '</FunctionName>' +
										   '<FunctionNote>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncNote),'')														+ '</FunctionNote>' +
										   '<FunctionDesc>' + ISNULL([dbo].[f_EncodeXMLValue](@FuncDesc),'')														+ '</FunctionDesc>' +
										   '<DisplayOrder>' + ISNULL(CONVERT(VARCHAR(10),@DisplayOrder),'')															+ '</DisplayOrder>' +
										   '<FileNames>'    + ISNULL([dbo].[f_EncodeXMLValue](@FileNames),'')														+ '</FileNames>'	+
										   '<ParentName>'   + CASE WHEN @ParentId IS NULL Then 'NONE' Else IsNull(@ParentName,convert(varchar(10),@ParentId)) End	+ '</ParentName>'	+
					  '</Acc_Con_FuncInfoIns>'

	SET @End = GETDATE()
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	BEGIN TRY		  
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]
			@custID = @FuncId,
			@Doing = @LogData,
			@userid = @UserID,
			@TypeID =2,
			@actionid =1801,
			@duration = @Duration  
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_Con_FuncInfoIns> ' +							
							'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'</Acc_Con_FuncInfoIns>'
							
		EXEC WriteLog_UserLog @UserID = @UserID, 
						      @Doing = @LogData
	END CATCH

GO
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoIns] TO [vnteam]