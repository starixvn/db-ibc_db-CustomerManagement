/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSelAllGroup]
AS
	/*
		Created: Dan
		Date: 2012-11-19
		Task: Select all group available
		DB: DBPOL/NAP_UserControl
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON

	SELECT GroupID,GroupName
	FROM eaGroup WITH(NOLOCK)
	ORDER BY groupName

GO
