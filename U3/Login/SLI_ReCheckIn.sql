/*<info serverAlias="DBONUSER-On_User" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE On_User
GO

ALTER PROCEDURE [dbo].[SLI_ReCheckIn]
	@On_UserId		INT
	,@IsKickedOut	BIT = 0 OUTPUT
AS

/*
	Created: 20190106@Percy
	DB: DBONUSER.On_User
	Task: NAP U3 - User Re-check in

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]
*/

BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM dbo.On_User_Admin WITH (NOLOCK) WHERE On_UserID = @On_UserID AND isKickedOut = 1)
	BEGIN
		SET @IsKickedOut = 1
	END
	ELSE
	BEGIN
		SET @IsKickedOut = 0

		UPDATE dbo.On_User_Admin WITH (ROWLOCK)
		SET reload_time = GETDATE()
		WHERE On_UserID = @On_UserID

		IF @@ROWCOUNT = 0
			SET @IsKickedOut = 1
	END
END
GO