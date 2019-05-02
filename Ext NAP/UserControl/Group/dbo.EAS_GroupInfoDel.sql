/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoDel]
	@GroupID int,	
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
/*
	Created by: Dan
	Date: 2012-11-16
	Task: Delete a group 
	DB: DBPOL/NAP_UserControl
 
	Revisions:
		- 20190426@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
*/
SET NOCOUNT ON

DECLARE @LogData nvarchar(200),@Begin	DATETIME,@End	DATETIME,@Duration	INT;

SET @Begin = GETDATE();

--Check permission 
EXEC dbo.EAS_UserCheckPermission @UserID=@UserID,@FuncKey='ManageGroup',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

IF EXISTS (SELECT 1 FROM dbo.eaUserInfo WITH (NOLOCK) WHERE GroupID = @GroupID) 
BEGIN
	SELECT @ErrMsg = 'This group has user belong to, so you cannot delete!'									
			,@ErrCode = 101
	RETURN
END

DELETE FROM dbo.eaGroupPolicy WITH (ROWLOCK)
WHERE GroupID=@GroupID

DELETE FROM dbo.eaGroup WITH (ROWLOCK)
WHERE GroupID=@GroupID

/**** Write to log table ***/
SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	
SELECT @LogData = '<EAS_GroupInfoDel>'+
					'<GroupID>' +  CAST(@GroupID as varchar(20)) + '</GroupID>'+ 					
				'</EAS_GroupInfoDel>'
		  
EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
		@custID = @groupid,
		@TrackingValue = @LogData,
		@userid = @UserID,
		@TypeID =0,
		@actionid =20002,
		@duration = @Duration  

GO 
