/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="1"></info>*/

ALTER FUNCTION dbo.f_Winlimit_GetProductSetting()
RETURNS TABLE
AS
/*
	Created: 2015107@Patrick	
	Task: Setting SMA & Company have check max winning or not
	DB: DBTRANS/BODB02
	Revisions:
		- 20151224@Patrick: Support RnG Casino [Redmine: #49803]
		- 20160511@Dominic: Support Voidbridge [Redmine: #57151]
		- 20160524@Helen: Support OneRnG [Redmine: #57680]
		- 20161019@Winnie: Fishing World [Redmine:#62547]
		- 20161011@Helen: CWL - Phase 3 [Redmine:61220]
		- 20170611@Helen: CWL Phase 3 - Apply for Virtual Sport [Redmine:72603]
		- 20170707@Elodie: Apply SMA Winlimit for Lottery [Redmine:#77927]
		- 20170710@Helen: Keno Lottery, BetradarVS into CWL [Redmine:77567,77564]
		- 20171027@Johnson: Add Lucky 3 [Redmine: #75883]
		- 20171001@Elodie: Apply SMA Winlimit and Company Win Limit for BullFighting [Redmine:#81664]
		- 20180125@Vicky: Apply SMA Winlimit for Virtual Sport [Redmine:#89284]
		- 20180319@Robert: CWL - Pragmatic Integration [Redmine:#91762]
		- 20180703@Elodie: Apply SMA Winlimit and CWL for Poker Games Product - [Redmine: #97675]
		- 20191028@Robert: Create new table WinLimit_ProductOffer [#122849]


	Parameters Explanation:	
*/
RETURN(
		SELECT a.ProductId
			, p.ProductName
			, a.BetType
			, a.IsActive_SMA
			, a.IsActive_Company
		FROM dbo.WinLimit_ProductOffer AS a WITH(NOLOCK)
			INNER JOIN DBPRO.bodb02.dbo.Products AS p WITH(NOLOCK) ON a.ProductID = p.ProductID
		)
