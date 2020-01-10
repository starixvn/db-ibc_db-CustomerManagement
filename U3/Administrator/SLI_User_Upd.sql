/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[SLI_User_Upd]
	@UserId			INT
	,@CustId		INT
	,@OldUserPwd	VARCHAR(50) = NULL
	,@UserPwd		VARCHAR(50) = NULL
	,@Closed		BIT = NULL
	,@FirstName		VARCHAR(50) = NULL
	,@LastName		VARCHAR(50) = NULL
	,@GroupId		TINYINT = NULL
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20190106@Percy
	DB: DBCUST.CustDB
	Task: NAP U3 - Administrator - Update user information, change password, reset user password

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]

	Param's Explanation:
		@UserId = @CustId: change password (owner @UserId)
		@UserId = @CustId: reset user password, Update user information (@CustId)
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentTime	DATETIME = GETDATE()
			,@ActionId		INT

	IF NOT EXISTS (
		SELECT 1
		FROM dbo.Customer c WITH (NOLOCK)
			INNER JOIN NAP_UserControl.dbo.SLI_Users sc WITH (NOLOCK) ON c.custid = sc.CustId
		WHERE c.custid = @CustId AND c.roleid BETWEEN 5 AND 10
	)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'User does not exists.'
		RETURN
	END

	IF @UserId = @CustId -- change password
	BEGIN
		SELECT @ActionId = 1716

		DECLARE @DB_UserPwd VARCHAR(50)
		SELECT  @DB_UserPwd = UserPwd
		FROM dbo.Customer c WITH (NOLOCK)
			INNER JOIN NAP_UserControl.dbo.SLI_Users sc WITH (NOLOCK) ON c.custid = sc.CustId
		WHERE c.custid = @CustId AND c.roleid BETWEEN 5 AND 10

		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 201, @ErrMsg = 'User does not exists.'
			RETURN
		END

		IF ISNULL(@DB_UserPwd, '') <> ISNULL(@OldUserPwd, '')
		BEGIN
			SELECT @ErrCode = 202, @ErrMsg = 'Wrong password.'
			RETURN
		END

		BEGIN TRY
			UPDATE dbo.Customer WITH (ROWLOCK)
			SET UserPwd = @UserPwd
			WHERE custid = @CustId
		END TRY
		BEGIN CATCH
			SELECT @ErrCode = 203, @ErrMsg = 'Change password failed.'
			RETURN 
		END CATCH
	END
	ELSE IF @UserId <> @CustId
	BEGIN
		IF @UserPwd IS NOT NULL -- reset user password
		BEGIN
			SELECT @ActionId = 1715

			BEGIN TRY
				UPDATE dbo.Customer WITH (ROWLOCK)
				SET UserPwd = @UserPwd
				WHERE custid = @CustId
			END TRY
			BEGIN CATCH
				SELECT @ErrCode = 301, @ErrMsg = 'Reset password failed.'
				RETURN 
			END CATCH
		END
		ELSE IF @Closed IS NOT NULL -- Active/Disactive user
		BEGIN
			SELECT @ActionId = 1714

			BEGIN TRY
				UPDATE dbo.custinfo WITH (ROWLOCK)
				SET closed = @Closed
				WHERE custid = @CustId
			END TRY
			BEGIN CATCH
				SELECT @ErrCode = 302, @ErrMsg = 'Reset password failed.'
				RETURN 
			END CATCH
		END
		ELSE IF @FirstName IS NOT NULL OR @LastName IS NOT NULL OR @GroupId IS NOT NULL -- update user information
		BEGIN
			SELECT @ActionId = 1717

			IF @FirstName IS NOT NULL OR @LastName IS NOT NULL
			BEGIN
				BEGIN TRY
					UPDATE dbo.Customer WITH (ROWLOCK)
					SET FirstName = ISNULL(@FirstName, FirstName)
						,LastName = ISNULL(@LastName, LastName)
					WHERE custid = @CustId
				END TRY
				BEGIN CATCH
					SELECT @ErrCode = 303, @ErrMsg = 'Update user information failed.'
					RETURN 
				END CATCH
			END

			IF @GroupId IS NOT NULL
			BEGIN
				BEGIN TRY
					EXEC NAP_UserControl.dbo.SLI_Users_UpdUser @CustId = @CustId, @GroupId = @GroupId
				END TRY
				BEGIN CATCH
					SELECT @ErrCode = 304, @ErrMsg = 'Update user information failed.'
					RETURN 
				END CATCH
			END
		END
	END

	-- Write log
	DECLARE @LogData NVARCHAR(1000), @Duration INT, @GroupName VARCHAR(20)
	
	SELECT	@Duration	= DATEDIFF(MILLISECOND, @currentTime, GETDATE())
			,@GroupName = CASE @GroupId WHEN 0 THEN 'User' WHEN 1 THEN 'Administrator' ELSE 'N/A' END

	SELECT  @LogData = '<SLI_User_Upd>'
						+ CASE @ActionId	 -- change password
											WHEN 1716 THEN ''
											 -- reset password
											WHEN 1715 THEN ''
											-- Active/Disactive user
											WHEN 1714 THEN '<Status>' + CASE @closed WHEN 0 THEN 'Active' ELSE 'Closed' END + '</Status>'
											-- update user information
											WHEN 1717 THEN ''
													+ CASE WHEN @FirstName	IS NOT NULL THEN '<FirstName>'	+ ISNULL(dbo.f_EncodeXMLValue (@FirstName), '') + '</FirstName>'	ELSE '' END
													+ CASE WHEN @LastName	IS NOT NULL THEN '<LastName>'	+ ISNULL(dbo.f_EncodeXMLValue (@LastName), '')  + '</LastName>'		ELSE '' END
													+ CASE WHEN @GroupId	IS NOT NULL THEN '<ToGroup>'	+ ISNULL(dbo.f_EncodeXMLValue (@GroupName), '')	+ '</ToGroup>'		ELSE '' END
											END
					+ '</SLI_User_Upd>'

	EXEC dbo.WriteLog_UserLog_UserControl_Wrapper
		@UserId		= @UserId
		,@CustId	= @CustId
		,@Doing		= @LogData
		,@TypeId	= 1
		,@ActionId	= @ActionId
		,@Duration	= @Duration
END
GO