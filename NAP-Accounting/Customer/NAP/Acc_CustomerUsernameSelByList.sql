USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUsernameSelByList]
	@Username VARCHAR(MAX) = '',
	@RoleId TINYINT = 1
AS

/*
	Creator: Percy
	Date: 2017-02-23
	DB: DBACC.bodb02
	Task: Get username list by suggest username [RedmineID: #71342]

	Revisions:

	Param's Explanation:
		- @Username: input list of suggest username
		- @RoleId: search by roleId, if @RoleId = 0: associated account, return @Username
*/

BEGIN
	SET NOCOUNT ON

	SELECT Username = @Username
END
GO

GRANT EXECUTE ON [dbo].[Acc_CustomerUsernameSelByList] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUsernameSelByList] TO [vnteam] AS [dbo]
GO