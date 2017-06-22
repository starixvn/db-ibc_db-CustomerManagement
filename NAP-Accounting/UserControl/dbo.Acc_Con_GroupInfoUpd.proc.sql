Alter PROCEDURE [dbo].[Acc_Con_GroupInfoUpd]
	@GroupID int,
	@GroupName nvarchar(50)=null,
	@GroupDesc nvarchar(50)=null,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
AS
/*
	Created by: []
	Task: Update  group info
	DB: DBPOLICY/BODB02
 
	Revisions:
		- 20110526@Tom: Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20120601@Sophia:	.Add condition @GroupName_Old <> @GroupName OR @GroupDesc_Old <> @GroupDesc
							.Change @LogData
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure							
*/
DECLARE @LogData nvarchar(500),@Begin	DATETIME,@End	DATETIME,@Duration	INT,@GroupName_Old nvarchar(200),@GroupDesc_Old nvarchar(200);
	
SET @Begin = GETDATE();
--Check permission for account site: @phuc20080213
EXEC dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[UserControl]',@System=@System,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from Acc_GroupInfo_1 with (NOLOCK) where system = @System and Groupname = @GroupName and GroupID <> @GroupID)
BEGIN
	Select @ErrMsg = 	case @Language 
						when 'E' then N'This group name is already used.'
						when 'CS' then N'This group name is already used.'
						else N'This group name is already used.'
				end, @ErrCode = 101	
	return
END 
ELSE
BEGIN
	
	Select @GroupName_Old=isnull(GroupName,''),@GroupDesc_Old=isnull(GroupDesc,'')  from Acc_GroupInfo_1 with(Nolock) where GroupID=@GroupID	

	IF @GroupName_Old <> @GroupName OR @GroupDesc_Old <> @GroupDesc
	BEGIN 
		Update Acc_GroupInfo_1 with (ROWLOCK, UPDLOCK)set GroupName=isnull(@GroupName,GroupName),GroupDesc=isnull(@GroupDesc,GroupDesc),Modifydate=getdate(),Creator=@Userid where GroupID=@GroupID	

		/**** Write to log table ***/
			SELECT @LogData = 
					'<Acc_Con_GroupInfoUpd>'+
						'<Groupname>'+
							'<Old>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName_Old),'') + '</Old>' +
							'<New>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</New>' +
						'</Groupname>'+
						'<GroupDescription>'+
							'<Old>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupDesc_Old),'') + '</Old>' +
							'<New>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupDesc),'') + '</New>' +
						'</GroupDescription>'+
					'</Acc_Con_GroupInfoUpd>'				
					

			SET @End = GETDATE()
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
			BEGIN TRY					
				EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]
					@custID = @GroupID,
					@Doing = @LogData,
					@userid = @UserID,
					@TypeID =0,
					@actionid =1708,
					@duration = @Duration  
			END TRY
			BEGIN CATCH
				SELECT @LogData = 
					'<Acc_Con_GroupInfoUpd> ' +							
							'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' +						
					'</Acc_Con_GroupInfoUpd>'
					
				EXEC WriteLog_UserLog @UserID = @UserID, 
									  @Doing = @LogData
			END CATCH
	END 
END



GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoUpd] TO [vnteam]
go

GRANT EXECUTE ON [dbo].[Acc_Con_GroupInfoUpd] TO [bodbAdminNet]