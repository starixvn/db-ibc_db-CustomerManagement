/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_MenuSel]
AS
	/*
		Created: Johnson
		Date: 2012-05-15
		Task: Manage menu
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
	*/	
SET NOCOUNT ON

	SELECT m.MenuID, m.MenuName, m.MenuDesc, 
		m.ParentID, m.ParentName, m.URL, 
		ISNULL(f.FuncID,0) as funcid , ISNULL(f.FuncName,'') as funcname,
		m.DisplayOrder, m.ModifiedDate, m.active
	FROM eaMenu m WITH(NOLOCK)
		LEFT JOIN eaFunction f WITH(NOLOCK) ON m.funcid = f.funcid
	ORDER BY m.parentID, m.DisplayOrder ASC
GO
