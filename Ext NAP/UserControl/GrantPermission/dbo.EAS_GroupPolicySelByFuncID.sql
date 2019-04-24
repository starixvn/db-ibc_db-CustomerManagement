/*<info serverAlias="DBEAS-bodb_EAS" executers="bodbExtAccNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupPolicySelByFuncID]
	@FuncID	INT
AS
	/*
		Created: Kan
		Date: 2019-01-21
		Task: Get EAS's groups and policies by FuncID
		DB: DBEAS/bodb_EAS
		
		Revisions:
			- 20190121@Kan: Get EAS's groups and policies by FuncID [Redmine Id: 106667]
		
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
