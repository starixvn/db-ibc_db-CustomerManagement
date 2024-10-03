/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_GroupInfoDel]
	@GroupID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int
AS
/*
	Created by: []
	Task: Update department of account in User Control 
	DB: DBCUST/NAP_UserControl
 
	Revisions:
		- 20110526@Tom: Remove condition @System and Write log into table DBLog.bodb_CustomerLog.dbo.UserLog_UserControl
		- 20120604@Elodie: Modify the content of a log in User Control
		- 20130125@Elodie: Write more log on UserLog table in case of DBLOG server failure
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20240816@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LogData nvarchar(200),@Begin	DATETIME,@End	DATETIME,@Duration	INT;
	
	SET @Begin = GETDATE();

	IF exists (select 1 from AccCustomer with (NOLOCK) where GroupID = @GroupID) 
	BEGIN
		Select @ErrMsg = 	case @Language 
						when 'E' then N' This group has customer belong to, so you cannot delete!'
						when 'CS' then N' This group has customer belong to, so you cannot delete!'
						else N' This group has customer belong to, so you can not delete!'
				end, @ErrCode = 102
		return
	END

	SELECT @LogData = '<Acc_Con_GroupInfoDel><GroupName>' + [dbo].[f_Get_GroupNameByGroupID](@groupid) + '</GroupName></Acc_Con_GroupInfoDel>'

	DELETE FROM Acc_GroupPolicy where GroupID=@GroupID
	DELETE FROM Acc_GroupInfo where GroupID=@GroupID

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
			
		END CATCH
END		
GO 