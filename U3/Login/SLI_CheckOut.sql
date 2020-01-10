/*<info serverAlias="DBONUSER-On_User" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE On_User
GO

ALTER PROCEDURE [dbo].[SLI_CheckOut]
	@On_UserId	INT
AS

/*
	Created: 20190106@Percy
	DB: DBONUSER.On_User
	Task: NAP U3 - User Logout

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentTime DATETIME
	SELECT  @currentTime = GETDATE()

	DECLARE @UserId INT, @RoleId TINYINT, @LoginIP NVARCHAR(20), @ServerID INT, @LogData NVARCHAR(1000), @Duration INT
	SELECT  @UserId = 0, @LoginIP = '127.0.0.0'
	
	SELECT  @UserId = custid, @ServerID = ServerID, @LoginIP = IP
	FROM dbo.On_User_Admin WITH (NOLOCK)
	WHERE on_userid = @On_UserID

	SELECT  @RoleId = roleid
	FROM bodb02.dbo.Customer WITH (NOLOCK)
	WHERE custid = @UserId

	DELETE dbo.On_User_Admin WITH (ROWLOCK)
	WHERE on_userid = @On_UserID

	SELECT @LogData =  'SLI Admin: ' + CONVERT(VARCHAR(30), @UserId) + ' Logout Success'
	SELECT @Duration = DATEDIFF(MILLISECOND, @currentTime, GETDATE())
  
	EXEC DBLOG.bodb_Customerlog.dbo.WriteLog_UserLog_Login   
		@UserId		= @UserId
		,@RoleId	= @RoleId
		,@SubAccId	= 0
		,@ServerId	= @ServerId
		,@LoginIP	= @LoginIP
		,@ActionId	= 1334
		,@Doing		= @LogData
		,@Duration	= @Duration
END
GO