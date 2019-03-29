/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet,bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

CREATE PROCEDURE [dbo].[Age_CheckOut]
	@On_UserID int,
	@UserName varchar(30) = NULL,
	@RoleID tinyint = NULL,
	@ServerID int = NULL,
	@Nickname varchar(50) = NULL,
	@reason NVARCHAR(100) = ' Logout Success'
AS
/*
Created: 20110912@Sophia
Task : Agent logout
DB: DB03.ON_USER
Original SP: Acc_CheckOut

Revisions:
	- 20190329@Johnson: add reason for log logout [redmine:#110409]
Param's Explanation:

*/
SET NOCOUNT ON

DECLARE @Begin		DATETIME
DECLARE @End		DATETIME
DECLARE @Duration	INT

SET @Begin = GETDATE()
--Write log to record user logout


Declare @CustID int, @LoginIP varchar(20), @SubAccID int,  
	@LogData nvarchar(200), @Role varchar(20)
SELECT	@CustID = 0 
Select @CustID = ISNULL(custid,0), @ServerID = isnull(@ServerID,ServerID), @LoginIP = IP, @SubAccID = ISNULL(SubAccID,0)
From On_User_Agent (nolock) where on_userid = @On_UserID

SELECT @SubAccID = ISNULL(@SubAccID, 0)
SELECT @LoginIP = ISNULL(@LoginIP, 0)

--Original:On_UserUpdLogout
update On_User_Agent with (ROWLOCK, UPDLOCK) set ServerID = 0
where on_userid = @On_UserID

--don't write log for AdminLogin
IF (@SubAccID <0)
BEGIN
	RETURN
END

SELECT @Role = CASE @RoleID WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  

SELECT @LogData =  @Role + case when isnull(@UserName,'') = '' then cast(@custid as varchar(30)) else @Username end + @reason

-- ***Check Sub-Account***  
IF @SubAccID > 0  
	SET @LogData = 'Sub-Account ' +  @LogData

SET @End = GETDATE()
SET @Duration = DATEDIFF(millisecond,@Begin,@End)

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
	 @UserID = @CustID, 
	 @RoleID = @RoleID, 
	 @SubAccID = @SubAccID,
	 @ServerID = @ServerID,
	 @LoginIP = @LoginIP,
	 @ActionID = 1305,
	 @Doing = @LogData,
	 @Duration = @Duration,
	 @Nickname = @Nickname
GO

