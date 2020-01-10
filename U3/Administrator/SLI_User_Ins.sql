/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[SLI_User_Ins]
	@UserId		INT
	,@IsAddNew	BIT = 1
	,@UserName	VARCHAR(50)
	,@UserPwd	VARCHAR(50) = NULL
	,@FirstName	VARCHAR(50) = NULL
	,@LastName	VARCHAR(50) = NULL
	,@GroupId	TINYINT
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20190106@Percy
	DB: DBCUST.CustDB
	Task: NAP U3 - Administrator - Add new user

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]

	Param's Explanation:
		@IsAddNew
			= 0: Add Existing User
			= 1: Add New User
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @currentTime DATETIME = GETDATE()

	DECLARE @CustId INT

	IF @IsAddNew = 1
	BEGIN
		DECLARE @IsExists BIT 
		EXEC Age_CustomerCheckExists @username = @username, @IsExists = @IsExists OUTPUT

		IF @IsExists = 1
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'This username is not available.'
			RETURN
		END

		BEGIN TRANSACTION
			
		INSERT INTO dbo.Customer (username, userpwd, roleid, firstname, lastname, creator, pwdexpiry)
		SELECT @UserName, @UserPwd, 6, @FirstName, @LastName, @UserId, DATEADD(MONTH, 1, @currentTime)

		SELECT @CustId = @@IDENTITY

		INSERT INTO dbo.custInfo (
			username, custid, currency, roleid, mrecommend, recommend, dangercust, autosuspend, reject, credit
			,danger,danger2, danger3, Enabled, closed
			,MaxPerMatch, MaxPerMatch2, MaxPerMatch3, MaxPerMatch5, MaxPerMatch8, MaxPerMatch10
			,MaxPerMatch11, MaxPerMatch12, MaxPerMatch99, MaxPerMatch161, MaxPerMatch99MP, MaxPerBall161
			,MatchLimit, VirtualMultiplier, DisableCasino, DisableOutright, DisableNumber, SyncCasino
		)
		SELECT
			@UserName, @CustId, NULL, 6, 0, 0, 0, 0, 0, 0
			,0, 0, 0, 1, 0
			,0, 0, 0, 0, 0, 0
			,0, 0, 0, 0, 0, 0
			,0, 0, 0, 0, 0, 0
	
		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			
			SELECT @ErrCode = 102, @ErrMsg = 'Add customer failed.'
			RETURN
		END
		
		COMMIT TRANSACTION

		-- Insert data to AdminSiteUser
		BEGIN TRY
			EXEC DBPRO.bodb02.dbo.Dot_Admin_Add_AdminSiteUser @CustId, @UserName, @UserPwd, @UserId
		END TRY
		BEGIN CATCH
			DELETE dbo.Customer WHERE custid = @CustId
			DELETE dbo.custInfo WHERE custid = @CustId

			SELECT @ErrCode = 103, @ErrMsg = 'Add customer failed.'
			RETURN
		END CATCH
	END
	ELSE IF @IsAddNew = 0
	BEGIN
		SELECT @CustId = custid FROM dbo.Customer WITH (NOLOCK) WHERE username = @UserName AND roleid BETWEEN 5 AND 10
		
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @ErrCode = 201, @ErrMsg = 'This username is not exists.'
			RETURN
		END

		IF EXISTS (SELECT 1 FROM NAP_UserControl.dbo.SLI_Users WITH (NOLOCK) WHERE CustId = @CustId)
		BEGIN
			SELECT @ErrCode = 202, @ErrMsg = 'This username is already exists.'
			RETURN
		END
	END

	-- Insert SLI Customer
	BEGIN TRY
		EXEC NAP_UserControl.dbo.SLI_Users_AddUser @UserId = @UserId, @CustId = @CustId, @GroupId = @GroupId
	END TRY
	BEGIN CATCH
		IF @IsAddNew = 1
		BEGIN
			DELETE dbo.Customer WHERE custid = @CustId
			DELETE dbo.custInfo WHERE custid = @CustId
		END

		SELECT @ErrCode = 301, @ErrMsg = 'Add customer failed.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @ActionId INT, @LogData NVARCHAR(1000), @Duration INT, @GroupName VARCHAR(20)
	
	SELECT  @ActionId	= CASE @IsAddNew WHEN 1 THEN 1712 ELSE 1713 END
			,@Duration	= DATEDIFF(MILLISECOND, @currentTime, GETDATE())
			,@GroupName = CASE @GroupId WHEN 0 THEN 'User' WHEN 1 THEN 'Administrator' ELSE 'N/A' END

	SELECT  @LogData = '<SLI_User_Ins>'
						+ '<UserName>'	+ ISNULL(dbo.f_EncodeXMLValue (@UserName), '')	+ '</UserName>'
						+ '<FirstName>' + ISNULL(dbo.f_EncodeXMLValue (@FirstName), '')	+ '</FirstName>'
						+ '<LastName>'  + ISNULL(dbo.f_EncodeXMLValue (@LastName), '')	+ '</LastName>'
						+ '<ToGroup>'	+ ISNULL(dbo.f_EncodeXMLValue (@GroupName), '')	+ '</ToGroup>'
					+ '</SLI_User_Ins>'

	EXEC dbo.WriteLog_UserLog_UserControl_Wrapper
		@UserId		= @UserId
		,@CustId	= @CustId
		,@Doing		= @LogData
		,@TypeId	= 1
		,@ActionId	= @ActionId
		,@Duration	= @Duration
END
GO