ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoIns]
	@GroupID int output,
	@GroupName nvarchar(50)='',
	@GroupDesc nvarchar(50)='',
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
As

/*
Task: Insert group info 
DB: DBPOLICY/BODB02 

Revision
	- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
	- 20120604@Elodie: Modify the content of a log in User Control
	- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
*/

SET NOCOUNT ON 
DECLARE @LogData nvarchar(200),@Begin	DATETIME,@End	DATETIME,@Duration	INT;
SET @Begin = GETDATE();

--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = @System
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from Acc_GroupInfo_1 with (NOLOCK) where system = @System and GroupName = @GroupName)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'This group name is already used.'
					when 'CS' then N'This group name is already used.'
					else N'This group name is already used.'
			end, @ErrCode = 102
	return
END

BEGIN TRANSACTION
	INSERT INTO Acc_GroupInfo_1(Groupname, GroupDesc, System, CreateDate,ModifyDate,Creator)
		VALUES (@GroupName, @GroupDesc, @System, getdate(),getdate(),@UserID)
	
	SELECT @GroupID=@@IDENTITY
	Insert into Acc_GroupPolicy_1(GroupID,FuncID,Policy,Createdate,ModifyDate,Creator)
		Select @GroupID as GroupID,FuncID,0 as policy,getdate() as createdate,
			getdate() as modifydate, @UserID as creator
		from acc_functioninfo with (nolock) where system = @System
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add group failed.'
							when 'CS' then N'Add group failed.'
							when 'J' then N'Add group failed.'
							else N'Add group failed.'
						end, @ErrCode = 103
		return
	END
COMMIT TRANSACTION

/**** Write to log table ***/
SELECT @LogData = '<Acc_Con_GroupInfoIns><GroupName>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</GroupName>' +
										'<GroupDesc>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupDesc),'') + '</GroupDesc></Acc_Con_GroupInfoIns>'

SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
BEGIN TRY	  
	EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]
		@custID = @GroupID,
		@Doing = @LogData,
		@userid = @UserID,
		@TypeID =0,
		@actionid =1707,
		@duration = @Duration  
END TRY
BEGIN CATCH
	SELECT @LogData = '<Acc_Con_GroupInfoIns> ' +							
							'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
						'</Acc_Con_GroupInfoIns>'
						
	EXEC WriteLog_UserLog @UserID = @UserID, 
						  @Doing = @LogData
END CATCH
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoIns] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].Acc_Con_GroupInfoIns TO [bodbAdminNet]