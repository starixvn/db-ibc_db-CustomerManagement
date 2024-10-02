/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
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
			- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]

		Parameter's Explanations:
			- @GroupName: main group of admin belong
			- @userid: admin login
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	SET @IsBelonging = 0
	
	DECLARE @GroupID INT 
	
	SELECT @GroupID = GroupID 
	FROM dbo.eaUserInfo WITH(NOLOCK)
	WHERE userid = @userid	
	
	IF EXISTS (SELECT 1 FROM dbo.eaGroup WITH(NOLOCK)
			   WHERE GroupName = @GroupName 
				AND (GroupID = @GroupID OR ParentID = @GroupID)
			)
		SELECT @IsBelonging = 1	
END	
GO