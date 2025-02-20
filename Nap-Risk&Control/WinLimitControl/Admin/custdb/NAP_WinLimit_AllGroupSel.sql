/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [NAP_WinLimit_AllGroupSel]
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
	- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
	- 20250227@Johnson: move sp to GlobCustDB [redmine: #216870]
Parameters Explanation:

Example:
EXEC [NAP_WinLimit_AllGroupSel]
*/


     SET NOCOUNT ON;
     SELECT GroupId AS Id,
            Groupname AS Name
     FROM dbo.WinLimit_Group WITH (NOLOCK);
GO
