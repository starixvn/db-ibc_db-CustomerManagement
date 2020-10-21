/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_MenuSelByUserID]
	@userid		INT
AS 
	/*
		Created: Dan
		Date: 2012-11-21
		Task: Get menu by userid
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]
			
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @tmpFunction TABLE (funcid int, policy int)
	
	INSERT INTO @tmpFunction (funcid, policy)
	SELECT CASE WHEN ISNULL(u.funcid ,0) = 0 THEN g.funcid ELSE u.funcid END as FuncID,
			CASE WHEN ISNULL(u.policy,0) < ISNULL(g.policy,0) THEN ISNULL(g.policy,0) ELSE ISNULL(u.policy,0) END as Policy
	FROM
	(
		SELECT FuncID,Policy 
		FROM eaUserPolicy WITH(NOLOCK) 
		WHERE userid = @userid
	) u
	FULL OUTER JOIN
	(
		SELECT FuncID,Policy 
		FROM eaUserInfo ui WITH(NOLOCK)
		INNER JOIN eaGroupPolicy gp WITH(NOLOCK) ON ui.groupid = gp.groupid
		WHERE ui.userid = @userid
	) g ON u.funcid = g.funcid
	
	SELECT
		m.ParentID,
		m.ParentName,
		m.MenuID,
		m.MenuName,
		m.URL,
		m.DisplayOrder,
		m.FuncID,
		m.active,
		f.FuncKey
	FROM eaMenu m WITH(NOLOCK) 	
		INNER JOIN @tmpFunction p ON p.funcid = m.funcid
		LEFT JOIN eaFunction f ON p.funcid = f.funcid
	WHERE m.active = 1 AND p.policy > 0
	ORDER BY m.parentID, m.displayOrder
	
	SELECT f.funcid, f.funcName, f.funckey, t.policy, f.ParentID,  isTest
	FROM @tmpFunction t
		INNER JOIN eaFunction f WITH(NOLOCK) ON t.funcid = f.funcid
	WHERE t.policy > 0

GO
