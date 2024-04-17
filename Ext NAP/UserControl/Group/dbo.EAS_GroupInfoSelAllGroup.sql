/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSelAllGroup]
	@Mode INT = 0
AS
	/*
		Created: Dan
		Date: 2012-11-19
		Task: Select all group available
		DB: DBPOL/NAP_UserControl
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20200814@Johnson: add @mode to get main group only [redmine:#136501]
		Parameter's Explanation:
			@Mode = 0: get all groups
					1: get main groups
	*/ 
SET NOCOUNT ON
	
	IF @Mode = 0
	BEGIN
		SELECT GroupID,GroupName
		FROM eaGroup WITH(NOLOCK)
		ORDER BY groupName
	END
	ELSE 
	BEGIN
		SELECT GroupID,GroupName
		FROM eaGroup WITH(NOLOCK)
		WHERE ParentID = 0
			AND GroupID > 3
		ORDER BY groupName
	END
GO
