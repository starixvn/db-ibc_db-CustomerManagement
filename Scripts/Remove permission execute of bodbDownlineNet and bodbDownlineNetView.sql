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

REVOKE EXECUTE ON [DBO].[EAS_GetPTProductBySuper] TO bodbDownlineNet

REVOKE EXECUTE ON [DBO].[EAS_GetPTProductBySuper] TO bodbDownlineNetView