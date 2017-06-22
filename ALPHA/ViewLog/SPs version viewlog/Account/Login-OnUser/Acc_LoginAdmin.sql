ALTER PROCEDURE [dbo].[Acc_LoginAdmin]
	@UserName varchar(50) OUTPUT,
	@UserPwd varchar(50),
	@LoginIP varchar(20),	
	@CustID int OUTPUT,
	@PageAccess nvarchar(500)='' OUTPUT,
	@RoleID tinyint OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@From nvarchar(200) = ''
AS
/*
Created: 
Task : 
DB: DB02.BODB02
Original:

Revisions:
	- 20081217@Phuong.Nguyen: Log data to UserLog_runSP
    - 20090402@Phuc: write log for logout.
    - 20100101@Kiwi: Modify Log.
	- 20100109@Daniel: 
		+ When user does not exist in system => Result:Failed(User_Not_Found) instead of Result:Failed(Not_Admin)
		+ After typing wrong password > 5 times, show err msg "A/C closed...", not wait to 7th
		+ Discard check A/C exists in DB03.Acc_Customer when checking existing of user
Param's Explanation:
*/

declare @LogData nvarchar(200),
	@db_userpwd nvarchar(50),
	@failedcount tinyint, @closed bit

SELECT @LogData = '', @ErrMsg = '', @ErrCode = 0 -- initial value

SELECT @CustID = c.custid, @db_userpwd = c.userpwd, @RoleID = roleid, @failedcount = IsNull(logincount, 0),
		@UserName = username
FROM dbo.customer c with (nolock)
WHERE username = @UserName

IF @@ROWCOUNT = 0 -- user not found
BEGIN
	SELECT  @ErrMsg = case @Language 
							when 'E' then 'Wrong username or password.'
							when 'CS' then N'Wrong username or password.'
							when 'J' then N'IDまたはパスワードが正しくありません。'
							else N'Wrong username or password.'
						end,
		@ErrCode = 101,
		@CustID = 0,
		@LogData = 'Admin:' + @UserName + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(User_Not_Found) From:' + @From
END
ELSE IF @RoleID NOT IN (5,6,7,8,9,10)
BEGIN
	SELECT  @ErrMsg = N'Wrong username or password.',
		@ErrCode = 102, 
		@LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(Not_Admin) From:' + @From
END
ELSE IF @UserPWD <> @db_userpwd
BEGIN
	SELECT @ErrMsg = N'Wrong username or password.',
		@ErrCode = 103,
		@LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(Password) From:' + @From,
		@failedcount = @failedcount + 1

	IF @failedcount > 5  -- already failed for 5 times, this is 6th time , LOCK THE A/C
	BEGIN
	
		UPDATE custinfo with (rowlock, updlock) SET closed = 1 WHERE custid = @custid
		--Phuong.Nguyen, log data
		DECLARE @LogSPData varchar(1000)
		SELECT @LogSPData = '<Acc_LoginAdmin IP="'+ @LoginIP + '" ' + 'From="' + @From + '" />'
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
			@UserID = @CustID,
			@CustID = @CustID,
			@ActionID = 905,
			@TrackingValue = @LogSPData
		--END

		SELECT  @ErrMsg = 'Your A/C was Closed, Please contact your supervisor.',
			@ErrCode = 104
	END
	IF @failedcount <= 6
		UPDATE customer with (rowlock, updlock) SET logincount = @failedcount WHERE custid = @custid
END

IF (@ErrMsg = '') AND (@LogData = '')
BEGIN
	SELECT @closed = closed FROM dbo.custinfo with (nolock) WHERE custid = @CustID

	IF @closed = 1
		SELECT  @ErrMsg = 'Your A/C was Closed, Please contact your supervisor.',
			@ErrCode = 104,
			@LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Failed(A/C_Closed) From:' + @From	
	ELSE
	BEGIN
		UPDATE customer with (rowlock, updlock)
		SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP, on_sessionid = 0
		WHERE custid = @custid

		SET @LogData = 'Admin:' + @username + ' Logged in to ACCOUNT SITE' + ' - ' + 'Result:Success From:' + @From
	END
END

	IF @LogData <> ''
	BEGIN
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
			 @UserID = @CustID, 
			 @RoleID = @RoleID, 
			 @SubAccID = 0,
			 @ServerID = 0,
			 @LoginIP = @LoginIP,
			 @ActionID = 1306,
			 @Doing = @LogData
	END

GO
GRANT  EXECUTE  ON [dbo].[Acc_LoginAdmin]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_LoginAdmin] TO [vnteam]