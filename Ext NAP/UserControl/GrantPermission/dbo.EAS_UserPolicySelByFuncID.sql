/*<info serverAlias="DBEAS-bodb_EAS" executers="bodbExtAccNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserPolicySelByFuncID]
	@FuncID	INT
AS
	/*
		Created: Kan
		Date: 2019-01-21
		Task: Get EAS's users and policies by FuncID
		DB: DBEAS/bodb_EAS
		
		Revisions:
			- 20190121@Kan: Get EAS's users and policies by FuncID [Redmine Id: 106667]
		
		Parameter's Explanations:
	*/
BEGIN
	SET NOCOUNT ON

	SELECT c.custid, c.username, g.groupid, g.groupname, ui.enabled, ISNULL(up.FuncID, @FuncID) AS FuncID, ISNULL(up.Policy, 0) AS Policy
	FROM dbo.eaUserInfo ui WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON ui.userid = c.custid
		INNER JOIN dbo.eaGroup g WITH(NOLOCK) ON ui.groupID = g.groupID
		LEFT JOIN dbo.eaUserPolicy up WITH(NOLOCK) ON up.FuncID = @FuncID AND ui.UserID = up.UserID
	ORDER BY ui.enabled DESC, g.groupName ASC, c.username ASC
END
GO
