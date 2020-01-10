/*<info serverAlias="DBONUSER-On_User" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE On_User
GO

ALTER PROCEDURE [dbo].[SLI_CheckIn]
	@UserId			INT
	,@NetSessionId	VARCHAR(30)
	,@ServerId		INT
	,@IP			NVARCHAR(20) = ''
	,@On_UserId		INT = 0 OUTPUT
	,@IsKickedOut	BIT = 0 OUTPUT
AS

/*
	Created: 20190106@Percy
	DB: DBONUSER.On_User
	Task: NAP U3 - User Check in

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]
*/

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.On_User_Admin WITH (ROWLOCK)
	SET IsKickedout = 1, ServerId = 0
	WHERE CustId = @UserId AND ServerId = @ServerId

	INSERT INTO dbo.On_User_Admin (CustId, NetSessionID, On_SessionId, ServerId, IsKickedOut, IP, SubAccId)
	VALUES (@UserId, @NetSessionId, 0, @ServerId, 0, @IP, 0)
  
	SELECT @On_UserId = SCOPE_IDENTITY(), @IsKickedOut = 0
END
GO