/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoSelByUserID]
	@UserID		INT
AS
	/*
		Created: Dan
		Date: 2012-11-19
		Task: Get user's info
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Parameter's Explanation:
	*/ 
SET NOCOUNT ON
	SELECT c.custid, c.username, c.firstname, c.lastname, g.groupID, g.groupname, ui.enabled
	FROM eaUserInfo ui WITH(NOLOCK)
		INNER JOIN CUSTDB.dbo.Customer c WITH(NOLOCK) ON ui.UserID = c.custid
		INNER JOIN eaGroup g WITH(NOLOCK) ON ui.groupID = g.groupID
	WHERE ui.UserID = @UserID

GO
