/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserPolicySelByFuncID]
	@FuncID	INT
AS
	/*
		Created: Kan
		Date: 2019-01-21
		Task: Get EAS's users and policies by FuncID
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190121@Kan: Get EAS's users and policies by FuncID [Redmine Id: 106667]
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanations:
	*/
BEGIN
	SET NOCOUNT ON

	SELECT c.custid, c.username, g.groupid, g.groupname, ui.enabled, ISNULL(up.FuncID, @FuncID) AS FuncID, ISNULL(up.Policy, 0) AS Policy
	FROM dbo.eaUserInfo ui WITH(NOLOCK)
		INNER JOIN CUSTDB.dbo.Customer c WITH(NOLOCK) ON ui.userid = c.custid
		INNER JOIN dbo.eaGroup g WITH(NOLOCK) ON ui.groupID = g.groupID
		LEFT JOIN dbo.eaUserPolicy up WITH(NOLOCK) ON up.FuncID = @FuncID AND ui.UserID = up.UserID
	ORDER BY ui.enabled DESC, g.groupName ASC, c.username ASC
END
GO
