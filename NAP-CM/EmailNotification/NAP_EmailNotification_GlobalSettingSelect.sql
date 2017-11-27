/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_EmailNotification_GlobalSettingSelect]
(	
	@NotifiedByFunction_Flag TINYINT = 1
)	
AS
/*
	Created: Helen
	Date: 2017-09-20
	Task: Retrieve list of global settings - [Redmine: 75557]
	DB: DBCUST.CustDB

	Revisions:
		- 20171012@Elodie: Get email notifications for Loss Limit monitoring function [Redmine:#82892]

	Parameter's explaination:
	- @NotifiedByFunction_Flag
			1: TO Control
			2: Loss monitoring
			+ 1: for the next one
			
*/
BEGIN
	SET NOCOUNT ON

	-- FOR TO Control
	IF @NotifiedByFunction_Flag = 1
	BEGIN
		SELECT DISTINCT GS.CustID, GH.GroupID
		FROM dbo.TOControl_GlobalSetting GS WITH(NOLOCK) 
			INNER JOIN dbo.CustGroupHeadline GH WITH (NOLOCK) ON GH.Custid = GS.custid
		WHERE GS.IsGroupHeadLine = 1
	END
	-- FOR TO Control
	ELSE IF @NotifiedByFunction_Flag = 2
	BEGIN
		SELECT ca.CustID, ls.GroupHeadlineID AS GroupID
		FROM DBAGE.bodb_Age.dbo.LimitLoss_HeadlineSetting ls WITH(NOLOCK) 
			INNER JOIN dbo.custAccount ca WITH (NOLOCK) ON ls.GroupHeadlineID = ca.groupID
		WHERE ca.IsGroupHeadLine = 1
	END
END
GO

GRANT EXECUTE ON [dbo].[NAP_EmailNotification_GlobalSettingSelect] TO [bodbAdminNet]
GO