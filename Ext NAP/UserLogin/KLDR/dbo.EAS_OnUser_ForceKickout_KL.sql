/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_OnUser_ForceKickout_KL]
	@custid INT
AS
	/*
		Created: 20201124@Johnson		
		Task: Force kick out admin subgroup when changed pwd
		DB: DBPOL/NAP_UserControl
		Revisions:
			- 20201124@Johnson: iinitial sp [Redmine: #145199]
			- 20231219@Johnson: setup KL DR [redmine: #195700]
		Paramter's Explanation:
	*/
BEGIN	
	SET NOCOUNT ON
	
	RETURN
	/*
	UPDATE eaOn_User WITH(UPDLOCK,ROWLOCK)
	SET isKickedout = 1
	WHERE custid = @custid
		AND isKickedout = 0*/
		
END	