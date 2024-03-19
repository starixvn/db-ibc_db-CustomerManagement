/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_FunctionSelEdit]
	@funcId	INT
AS
	/*
		Created: Dan
		Date: 2012-12-03
		Task: Get functions info to edit group
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190426@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON
	
	SELECT g.GroupID, g.GroupName, CASE WHEN ISNULL(Policy,0)>1 THEN 1 ELSE 0 END hasPermission
	FROM dbo.eaGroup g WITH(NOLOCK) LEFT JOIN dbo.eaGroupPolicy gp WITH(NOLOCK) ON g.GroupID=gp.GroupID	and gp.FuncID = @funcId	
	ORDER BY g.GroupName ASC
	
GO
