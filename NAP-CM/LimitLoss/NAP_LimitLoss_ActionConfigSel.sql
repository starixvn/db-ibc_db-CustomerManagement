ALTER PROCEDURE [dbo].[NAP_LimitLoss_ActionConfigSel]
AS
/*
	Created: Elodie
	Date: 20140526
	Task : Get action config
	DB: DBAGE/bodb_Age

	Revisions:

	Parameter's explaination: 
	
	Example: EXEC NAP_LimitLoss_ActionConfigSel
	
*/
SET NOCOUNT ON

SELECT a.LevelID, a.ActionID, a.Value
FROM dbo.LimitLoss_ActionConfig a WITH (NOLOCK)

GO
GRANT EXECUTE ON [dbo].[NAP_LimitLoss_ActionConfigSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_LimitLoss_ActionConfigSel] TO [vnteam]

 