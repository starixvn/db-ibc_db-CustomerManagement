/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_WinLimit_AllSiteSel] @ProductId INT = NULL
AS
/*
	Created: Franklin	
	Date: 2016-06-22
	Task: #57722 - Implement Game Win Limit Control phase2

	DB: DBCUST/CustDB

	Revisions:
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
		- 20230213@Tacy: CWL - Split 789y site [RedmineID: #182387]

	Parameters Explanation:	

	Example: 
		EXEC [NAP_WinLimit_AllSiteSel]
*/
BEGIN
     SET NOCOUNT ON;

     SELECT siteid AS Id,
            CASE WHEN isLicensee=0 THEN site + ' (' + SiteLabel + ')' ELSE site END AS Name
     FROM dbo.Site WITH (NOLOCK)
     WHERE isActive = 1;
END
GO