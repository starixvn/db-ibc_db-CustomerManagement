/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupPolicySel]
	@groupid	INT
AS
/*
	Created: Dan
	Date: 2012-11-16
	Task: Get group policy
	DB: DBPOL/NAP_UserControl
	
	Revisions:
		- 20130517@Lukas: get column funcKey
		- 20140122@Elodie: Get column FuncDesc
		- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]

	Parameter's Explanation:
*/ 
SET NOCOUNT ON

SELECT f.FuncID, f.FuncName, f.DisplayOrder, f.ParentID, f.ParentName, ISNULL(gp.Policy,0) as Policy, f.FuncDesc
	,f.funcKey
FROM eaFunction f WITH(NOLOCK)
	LEFT JOIN eaGroupPolicy gp WITH(NOLOCK) ON gp.GroupID = @groupid AND gp.funcid = f.funcid	
ORDER BY f.ParentID ,f.DisplayOrder ASC

GO
