ALTER PROCEDURE [dbo].[Acc_On_UserUpdLogout]
	@On_UserID int,
	@ServerID int = 0,
	@UserName varchar(30) = NULL,
	@RoleID tinyint = 0
AS
/*
Created: 
Task : Admin logout
DB: DB03.ON_USER
Original:

Revisions:
    - 20090402@Phuc: write log for logout.
	- 20101022@Johnson: record execution time
Param's Explanation:
*/

SET NOCOUNT ON
DECLARE @Begin		DATETIME
DECLARE @End		DATETIME
DECLARE @Duration	INT

SET @Begin = GETDATE()
--Write log to record user logout
Declare @CustID int, @LoginIP varchar(15),   
		@LogData nvarchar(200)
SELECT	@CustID = 0, @LoginIP = '127.0.0.0'  
Select @CustID = custid, @ServerID = isnull(@ServerID,ServerID), @LoginIP = IP 
From On_User (nolock) where on_userid = @On_UserID

SELECT @LogData =  'Admin:' + case when isnull(@UserName,'') = '' then cast(@custid as varchar(30)) else @Username end + ' Logout Success'

Delete from On_User where on_userid = @On_UserID

SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond,@Begin,@End)

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
	 @UserID = @CustID, 
	 @RoleID = @RoleID, 
	 @SubAccID = 0,
	 @ServerID = @ServerID,
	 @LoginIP = @LoginIP,
	 @ActionID = 1307,	 
	 @Doing = @LogData,
	 @Duration = @Duration
GO
GRANT EXECUTE ON [dbo].[Acc_On_UserUpdLogout] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_On_UserUpdLogout] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_On_UserUpdLogout] TO [vnteam]