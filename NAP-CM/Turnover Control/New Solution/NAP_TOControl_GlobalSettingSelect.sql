/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingSelect]
	@UserName NVARCHAR(30) = ''
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of global settings
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT ci.UserName,
		CASE ci.RoleID WHEN  4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END [Level],
		ex.Currency,
		t.MaxTurnover,
		t.CustID
	FROM dbo.TOControl_GlobalSetting t WITH(NOLOCK) 
		INNER JOIN dbo.CustInfo ci WITH(NOLOCK) ON ci.CustID = t.CustID
		INNER JOIN dbo.Exchange ex WITH(NOLOCK) ON ex.exchangeid = ci.currency
	WHERE (ISNULL(@UserName, '') = '' OR ci.Username = @UserName)

END
GO