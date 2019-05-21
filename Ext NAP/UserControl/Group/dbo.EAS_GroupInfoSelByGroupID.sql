/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSelByGroupID]
	@GroupID	INT
AS
	/*
		Created: Dan
		Date: 2012-11-16
		Task: get group info by id
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON

SELECT groupID, GroupName, Description
FROM eaGroup WITH(NOLOCK)
WHERE groupID = @GroupID

GO
