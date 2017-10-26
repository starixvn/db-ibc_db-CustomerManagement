/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingSelect]
	@UserName NVARCHAR(30) = ''
	, @SportType SMALLINT = 1
	
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of global settings
	DB: DBCUST.CustDB

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		
	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT ci.UserName
		, CASE 
				WHEN t.IsGroupHeadLine = 1 THEN 'Headline'
				ELSE CASE ci.RoleID WHEN  4 THEN 'Super' WHEN 3 THEN 'Master' WHEN 2 THEN 'Agent' END 
		   END AS [Level]
		, CASE WHEN T.IsGroupHeadLine = 1 THEN 'RM' ELSE ex.Currency END AS Currency
		, t.MaxTurnover
		, t.CustID
	FROM dbo.TOControl_GlobalSetting t WITH(NOLOCK) 
		INNER JOIN dbo.CustInfo ci WITH(NOLOCK) ON ci.CustID = t.CustID
		INNER JOIN dbo.Exchange ex WITH(NOLOCK) ON ex.exchangeid = ci.currency
	WHERE T.Sporttype = @SportType
		AND (ISNULL(@UserName, '') = '' OR ci.Username LIKE '%' + @UserName + '%') 

END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_GlobalSettingSelect] TO [bodbAdminNet]
GO