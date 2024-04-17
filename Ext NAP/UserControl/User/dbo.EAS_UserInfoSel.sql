/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[EAS_UserInfoSel]
	@GroupID	INT = NULL,
	@Username	VARCHAR(50) = ''
AS
	/*
		Created: Dan
		Date: 2012-11-19
		Task: Get EAS's users
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanations:
	*/ 
SET NOCOUNT ON

	SELECT c.custid, c.username, c.firstname, c.lastname, g.groupid, g.groupname, ISNULL(creator.username,'') as creator, ui.CreatedDate, ui.enabled
	FROM eaUserInfo ui WITH(NOLOCK)
		INNER JOIN CUSTDB.dbo.Customer c WITH(NOLOCK) ON ui.userid = c.custid
		INNER JOIN eaGroup g WITH(NOLOCK) ON ui.groupID = g.groupID
		LEFT JOIN CUSTDB.dbo.Customer creator WITH(NOLOCK) ON ui.creator = creator.custid
	WHERE ui.GroupID = ISNULL(@GroupID,ui.GroupID)
		AND c.username LIKE ISNULL(@Username,c.username) + '%'
	ORDER BY ui.enabled DESC, g.groupName ASC, c.username ASC
GO
