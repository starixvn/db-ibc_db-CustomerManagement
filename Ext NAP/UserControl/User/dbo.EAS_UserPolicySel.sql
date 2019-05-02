/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserPolicySel]
	@UserID		INT
AS
	/*
		Created: Dan
		Date: 2012-11-20
		Task: Get policy of user
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20130520@Lukas: get funcKey field
			- 20140122@Elodie: Get column FuncDesc
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]

		Parameter's Explanation:
	*/ 
SET NOCOUNT ON

	SELECT f.funcid, f.funcname, f.DisplayOrder, f.ParentID, f.ParentName, ISNULL(u.policy,0) UserPolicy, ISNULL(g.policy,0) GroupPolicy, f.funcKey, f.FuncDesc
	FROM eaFunction f WITH(NOLOCK)
	LEFT JOIN 	
		(
			SELECT FuncID, Policy
			FROM eaUserPolicy WITH(NOLOCK) 
			WHERE UserID = @UserID
		) u ON f.funcid  = u.funcid
	LEFT JOIN
		(
			SELECT FuncID, Policy
			FROM eaGroupPolicy gp WITH(NOLOCK)
				INNER JOIN eaUserInfo ui WITH(NOLOCK) ON ui.userid = @userid AND ui.groupid = gp.groupid		
		) g ON f.funcid = g.funcid
	ORDER BY f.ParentID ,f.DisplayOrder ASC

GO
