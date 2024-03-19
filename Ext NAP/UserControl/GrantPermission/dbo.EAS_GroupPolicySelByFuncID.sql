/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupPolicySelByFuncID]
	@FuncID	INT
AS
	/*
		Created: Kan
		Date: 2019-01-21
		Task: Get EAS's groups and policies by FuncID
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190121@Kan: Get EAS's groups and policies by FuncID [Redmine Id: 106667]
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanations:
	*/
BEGIN
	SET NOCOUNT ON

	SELECT g.groupid, g.groupname, ISNULL(gp.FuncID, @FuncID) AS FuncID, ISNULL(gp.Policy, 0) AS Policy
	FROM dbo.eaGroup g WITH(NOLOCK)
		LEFT JOIN dbo.eaGroupPolicy gp WITH(NOLOCK) ON gp.FuncID = @FuncID AND g.GroupID = gp.GroupID
	ORDER BY g.groupName
END
GO
