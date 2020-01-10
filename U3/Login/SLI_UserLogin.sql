/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[SLI_UserLogin]
	@UserName		VARCHAR(50)
	,@UserPwd		VARCHAR(50)
	,@LoginIP		VARCHAR(20)
	,@LoginDomain	NVARCHAR(253) = NULL
	,@BrowserName	NVARCHAR(255) = NULL
	,@Platform		NVARCHAR(255) = NULL
	,@CountryCode	VARCHAR(64) = NULL
	,@From			NVARCHAR(200) = ''
	,@UserId		INT = 0 OUTPUT
	,@GroupId		TINYINT = 0 OUTPUT
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20190106@Percy
	DB: DBCUST.CustDB
	Task: NAP U3 - User login

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @UserId = NULL, @ErrCode = 0, @ErrMsg = ''

	DECLARE @StartTime DATETIME, @EndTime DATETIME, @Duration INT
	SELECT  @StartTime = GETDATE()

	DECLARE @LogData NVARCHAR(2000) = '', @DB_UserPwd NVARCHAR(50), @FailedCount TINYINT, @Closed BIT, @RoleId TINYINT

	SELECT	@UserId			= c.custid
			,@RoleId		= c.roleid
			,@DB_UserPwd	= c.userpwd
			,@FailedCount	= ISNULL(c.logincount, 0)
			,@GroupId		= sc.GroupId
	FROM dbo.Customer c WITH (NOLOCK)
		INNER JOIN NAP_UserControl.dbo.SLI_Users sc WITH (NOLOCK) ON c.custid = sc.custid
	WHERE c.username = @UserName

	IF @@ROWCOUNT = 0
	BEGIN
		SELECT
			@ErrCode = 101
			,@ErrMsg = 'Wrong username or password.'
			,@UserId = 0
			,@LogData = @Username + ' logged in to NAP U3 site - Result:Failed(User_Not_Found) From:' + @From
	END
	ELSE IF @RoleId NOT BETWEEN 5 AND 10
	BEGIN
		SELECT
			@ErrCode = 102
			,@ErrMsg = 'Wrong username or password.'
			,@UserId = 0
			,@LogData = @Username + ' logged in to NAP U3 site - Result:Failed(Not_Admin) From:' + @From
	END
	ELSE IF @UserPwd <> @DB_UserPwd
	BEGIN
		SELECT
			@ErrCode = 103
			,@ErrMsg = 'Wrong username or password.'
			,@UserId = 0
			,@LogData = @Username + ' logged in to NAP U3 site - Result:Failed(Password) From:' + @From
			,@FailedCount = @FailedCount + 1

		IF (@FailedCount <= 255) -- max of tinyint
		BEGIN
			UPDATE dbo.Customer WITH (ROWLOCK)
			SET logincount = @FailedCount
			WHERE custid = @UserId
		END
	END
	ELSE
	BEGIN
		SELECT @Closed = closed FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @UserId

		IF @Closed = 1
		BEGIN
			SELECT
				@ErrCode = 104
				,@ErrMsg = 'Your A/C was Closed, Please contact your supervisor.'
				,@LogData = @Username + ' logged in to NAP U3 site - Result:Failed(A/C_Closed) From:' + @From
				,@FailedCount = @FailedCount + 1
		END
		ELSE
		BEGIN
			UPDATE dbo.Customer WITH (ROWLOCK)
			SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP, on_sessionid = 0
			WHERE custid = @UserId

			SET @LogData =  @Username + ' logged in to NAP U3 site - Result:Success From:' + @From
		END
	END

	IF @LogData <> ''
	BEGIN		
		SET @EndTime	= GETDATE()
		SET @Duration	= DATEDIFF(MILLISECOND, @StartTime, @EndTime)
		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Login
				@UserID			= @UserId
				,@RoleID		= @RoleID
				,@SubAccID		= 0
				,@ServerID		= 0
				,@LoginIP		= @LoginIP
				,@ActionID		= 1333
				,@Doing			= @LogData
				,@DomainName	= @LoginDomain
				,@BrowserName	= @BrowserName
				,@Platform		= @Platform
				,@CountryCode	= @CountryCode
				,@Duration		= @Duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = @LogData + ' ErrMsg=' + ERROR_MESSAGE()
			
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Login
				@UserID			= @UserId
				,@RoleID		= @RoleID
				,@SubAccID		= 0
				,@ServerID		= 0
				,@LoginIP		= @LoginIP
				,@ActionID		= 1333
				,@Doing			= @LogData
				,@DomainName	= @LoginDomain
				,@BrowserName	= @BrowserName
				,@Platform		= @Platform
				,@CountryCode	= @CountryCode
				,@Duration		= @Duration
		END CATCH				 
	END
END
GO