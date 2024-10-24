/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.EAS_GroupAdmin_Sel
	@GroupAdmin VARCHAR(100) = ''
AS
/*
	Created: 20240704@Louisa
	Task: Scaleout DBCUST Redmine:#199915
	DB: DBCUST/NAP_UserControl
		
	Revisions:
		- 20240704@Louisa: initial Redmine:#199915

	Parameter's Explanation:
*/
BEGIN
	SET NOCOUNT ON

		DECLARE @isSubGroupAdmin BIT

		SELECT @isSubGroupAdmin = CASE WHEN ParentID > 0 THEN 1 ELSE 0 END
		FROM dbo.eaGroup WITH(NOLOCK)
		WHERE GroupName = @GroupAdmin

		SELECT GroupName 
		FROM dbo.eaGroup WITH(NOLOCK)
		WHERE ParentID = 0
			OR 1 = CASE WHEN @isSubGroupAdmin = 1 AND GroupName = @GroupAdmin THEN 1 ELSE 0 END

END
GO