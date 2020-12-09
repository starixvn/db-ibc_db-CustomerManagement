/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoSelBySubGroup] 	
    @SubGroup	VARCHAR(50)	= ''
AS
/*	Created 20201112@Johnson  
	Task : Get list users assign to sub-group
	DB: DBCUST/CustDB
	
	Revisions:  
		- 20201112@Johnson: initial sp [redmine:#145199]
	
	Parameter's explanation:				
*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT c.custid, c.username 
	FROM eaUserInfo u WITH(NOLOCK)
		INNER JOIN eaGroup g WITH(NOLOCK) ON u.GroupID = g.GroupID
		INNER JOIN CustDB.dbo.customer c WITH(NOLOCK) ON u.UserID = c.custid
	WHERE GroupName = @SubGroup	
	ORDER BY c.username ASC

END