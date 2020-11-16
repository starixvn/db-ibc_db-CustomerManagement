/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserCheckBelonging]
	@GroupName		VARCHAR(100) = '',
	@UserID			INT = 0,
	@IsBelonging	BIT = 0 OUTPUT
AS
	/*
		Created: 20201116@Johnson		
		Task: check belonging of user on external group
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20201116@Johnson: initial sp [Redmine: #126459]
		
		Parameter's Explanations:
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	SET @IsBelonging = 0
	
	IF EXISTS (SELECT 1
			FROM eaUserInfo u WITH(NOLOCK)
				INNER JOIN eaGroup g WITH(NOLOCK) ON u.groupid = g.groupid
			WHERE userid = @userid	
				AND g.GroupName = @GroupName
			)
	SELECT @IsBelonging = 1		
END	
GO

