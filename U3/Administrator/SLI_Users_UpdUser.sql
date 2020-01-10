/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE NAP_UserControl
GO

ALTER PROCEDURE [dbo].[SLI_Users_UpdUser]
	@CustId		INT
	,@GroupId	TINYINT
AS

/*
	Created: 20190106@Percy
	DB: DBPOL.NAP_UserControl
	Task: NAP U3 - Administrator - Update user

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]
*/

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.SLI_Users WITH (ROWLOCK)
	SET GroupId = @GroupId
	WHERE CustId = @CustId
END
GO