/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_OnUser_ForceKickout]
	@custid INT
AS
	/*
		Created: 20201124@Johnson		
		Task: Force kick out admin subgroup when changed pwd
		DB: DBPOL/NAP_UserControl
		Revisions:
			- 20201124@Johnson: iinitial sp [Redmine: #145199]
		
		Paramter's Explanation:
	*/
BEGIN	
	SET NOCOUNT ON
	
	UPDATE eaOn_User WITH(UPDLOCK,ROWLOCK)
	SET isKickedout = 1
	WHERE custid = @custid
		AND isKickedout = 0
END	