/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_NAP_CWL_SuspendedSite]()
RETURNS TABLE
AS
/*
	Created: 20231011@Tacy
	Task: List sites apply suspend member account
	DB: DBCUST-CUSTDB
	
	Revisions:
		- 20231011@Tacy: Create SP [RedmineID: #184911]
*/
RETURN
	SELECT siteid, site
	FROM Site WITH (NOLOCK)
	WHERE SiteLabel='MBC' AND isActive=1
	AND siteid<=188 --7aa666: max siteid - MBC
GO