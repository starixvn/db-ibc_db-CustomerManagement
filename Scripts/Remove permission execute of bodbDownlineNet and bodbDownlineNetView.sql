/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0"></info>*/
GO
USE [bodb02]
GO
/*
	Created: 20201225@Tina
	DB: DBACC-bodb02
	Task: Remove permission execute of 2 accounts on alpha site

	Revisions:
		- 20201225@Tina: Big Gaming - Implement Alpha/NAP/ExtNAP/ Reset Winning [Redmine: #142459]
		
*/

REVOKE EXECUTE ON OBJECT:: [DBO].[EAS_GetPTProductBySuper] FROM bodbDownlineNet;
GO
REVOKE EXECUTE ON OBJECT:: [DBO].[EAS_GetPTProductBySuper] FROM bodbDownlineNetView;


SELECT object_name(id), user_name(uid), id 
FROM sysprotects 
WHERE user_name(uid) IN ('bodbDownlineNet', 'bodbDownlineNetView') 
	AND object_name(id) = 'EAS_GetPTProductBySuper'