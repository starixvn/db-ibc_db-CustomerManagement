ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoDel]
	@GroupID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int,
	@System nvarchar(50) = 'ACCOUNTING'
AS
/*
	Created by: []
	Task: Update department of account in User Control 
	DB: DBPOLICY/BODB02
 
	Revisions:
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

IF exists (select 1 from AccCustomer_1 with (NOLOCK) where GroupID = @GroupID) 
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N' This group has customer belong to, so you cannot delete!'
					when 'CS' then N' This group has customer belong to, so you cannot delete!'
					else N' This group has customer belong to, so you can not delete!'
			end, @ErrCode = 102
	return
END

SELECT @LogData = '<Acc_Con_GroupInfoDel><GroupName>' + [dbo].[f_Get_GroupNameByGroupID](@groupid) + '</GroupName></Acc_Con_GroupInfoDel>'

DELETE FROM Acc_GroupPolicy_1 where GroupID=@GroupID
DELETE FROM Acc_GroupInfo_1 where GroupID=@GroupID

/**** Write to log table ***/
	SET @End = GETDATE()
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	BEGIN TRY		  
		EXEC DBLOG.bodb_CustomerLog.[dbo].[WriteLog_UserLog_UserControl]
			@custID = @groupid,
			@Doing = @LogData,
			@userid = @UserID,
			@TypeID =0,
			@actionid =1706,
			@duration = @Duration  
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_Con_GroupInfoDel> ' +							
							'ErrMsg="' + COALESCE(ERROR_MESSAGE(),SPACE(1)) + '" ' + 
							'</Acc_Con_GroupInfoDel>'
							
		EXEC WriteLog_UserLog @UserID = @UserID, 
						      @Doing = @LogData
	END CATCH
GO 
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_GroupInfoDel] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Acc_Con_GroupInfoDel] TO [bodbAdminNet]