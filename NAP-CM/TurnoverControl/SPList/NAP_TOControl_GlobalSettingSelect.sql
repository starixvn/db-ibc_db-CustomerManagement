/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingSelect]
	@UserName NVARCHAR(30) = ''
	, @SportType SMALLINT = 1
	, @ExchangeID INT = 0
	
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of global settings
	DB: DBCUST.CustDB

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171212@Helen: Implement some change request from OPS Team - [Redmine: 85638]
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
		AND 1 = CASE 
					WHEN @ExchangeID = 0 THEN 1
					WHEN @ExchangeID = 2 AND (t.IsGroupHeadLine = 1 OR ex.exchangeid = 2) THEN 1
					WHEN @ExchangeID NOT IN (0,2) AND ex.exchangeid = @ExchangeID AND t.IsGroupHeadLine = 0 THEN 1 
					ELSE 0 
				END  
		
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_GlobalSettingSelect] TO [bodbAdminNet]
GO