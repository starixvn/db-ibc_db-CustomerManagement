/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoSel]	
AS
	/*
		Created: Dan
		Date: 2012-11-15
		Task: Get groups 
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
			
	*/	
SET NOCOUNT ON

	SELECT g.GroupID, 
		g.GroupName, 
		ISNULL(p.Users,0) as NoUsers, 
		ISNULL(g.Description,'') as Description, 
		ISNULL(c.username,'') as Creator, 
		g.createdDate
	FROM eaGroup g WITH(NOLOCK) 
		LEFT JOIN dbcust.dbo.Customer c WITH(NOLOCK) ON g.creator = c.custid
		LEFT JOIN 
		(
			SELECT GroupID, count(1) users
			FROM eaUserInfo WITH(NOLOCK)
			GROUP BY GroupID
		) p ON g.groupID = p.groupID
	ORDER BY groupName
GO
