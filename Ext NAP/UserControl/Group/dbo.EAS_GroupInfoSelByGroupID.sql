/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSelByGroupID]
	@GroupID	INT,
	@Mode 		TINYINT =0
AS
	/*
		Created: Dan
		Date: 2012-11-16
		Task: get group info by id
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20200804@Jonnson: add sub group [redmine:#136501]
			- 20201223@Johnson: sort by maingroup first for @mode = 2 [redmine:#147642]
		Parameter's Explanation:
			- @Mode = 1: only 1 group incase edit group
					2: all group & sub group to show dropdown on left pannel
	*/ 
BEGIN
	SET NOCOUNT ON
	
	IF @Mode = 1
	BEGIN
		SELECT e.groupID, e.GroupName, e.Description, e.ParentID, ISNULL(p.GroupName,'None') as ParentGroup
		FROM eaGroup e WITH(NOLOCK)
			LEFT JOIN eaGroup p WITH(NOLOCK) ON e.ParentID = p.GroupID
		WHERE e.groupID = @GroupID 
	END
	ELSE IF @mode = 2
	BEGIN
		SELECT e.groupID, e.GroupName, e.Description, e.ParentID, ISNULL(p.GroupName,'None') as ParentGroup
		FROM eaGroup e WITH(NOLOCK)
			LEFT JOIN eaGroup p WITH(NOLOCK) ON e.ParentID = p.GroupID
		WHERE e.groupID = @GroupID OR e.ParentID = @GroupID
		ORDER BY CASE WHEN e.ParentID = 0 THEN 1 ELSE 0 END DESC,GroupName
	END	
	
END
GO
