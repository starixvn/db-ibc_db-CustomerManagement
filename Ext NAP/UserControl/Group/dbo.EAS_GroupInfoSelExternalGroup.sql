/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSelExternalGroup]	
AS
	/*
		Created: Dan
		Date: 2012-11-19
		Task: Get currency groups for external admin
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20200806@Johnson: add sub group [redmine:#136501]
		Parameter's Explanation:
			
	*/	
SET NOCOUNT ON
	SELECT g.GroupID, 
		g.GroupName,
		g.ParentID
	FROM eaGroup g WITH(NOLOCK) 
		LEFT JOIN dbo.eaGroupPolicy gp(NOLOCK) ON gp.GroupID=g.GroupID and FuncID=11 -- ExternalGroup function
	WHERE ISNULL(Policy,0)<2
	--groupName LIKE 'ACC%'	
	ORDER BY groupName
GO
