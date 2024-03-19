/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSelByGroupName]
	@GroupName	VARCHAR(50)
AS
	/*
		Created: 20201210@Johnson	
		Task: get group info by name
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20200804@Jonnson: initial sp [redmine:#146884]
		Parameter's Explanation:
			
	*/ 
BEGIN
	SET NOCOUNT ON
	
	SELECT e.groupID, e.GroupName, e.Description, e.ParentID, ISNULL(p.GroupName,'None') as ParentGroup
	FROM eaGroup e WITH(NOLOCK)
		LEFT JOIN eaGroup p WITH(NOLOCK) ON e.ParentID = p.GroupID
	WHERE e.GroupName = @GroupName 
END	
	