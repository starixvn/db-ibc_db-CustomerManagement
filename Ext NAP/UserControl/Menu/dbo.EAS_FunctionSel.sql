/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_FunctionSel]
AS
	/*
		Created: Dan
		Date: 2012-11-20
		Task: Get functions info
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190426@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON
	
	SELECT FuncID, FuncName, FuncKey, FuncDesc, ParentID, ParentName, DisplayOrder, ModifiedDate, isTest
	FROM eaFunction WITH(NOLOCK)
	ORDER BY parentID, DisplayOrder ASC
	
GO
