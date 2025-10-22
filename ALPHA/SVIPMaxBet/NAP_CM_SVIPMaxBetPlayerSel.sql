/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_SVIPMaxBetPlayerSel] 
	  @UserName		NVARCHAR(50) =	''
	, @SiteID		INT = 0
	, @Currency		SMALLINT = 0
	, @IsTest BIT = 0
AS
/*
	Created: Winfred
	Date: 20250224
	Task : [NAP CM] Customer - Increase Bet Limit
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20250224@Winfred: [NAP CM] Customer - Increase Bet Limit [RedmineID: #218073] 
		- 202511015@Winfred: [NAP CM] Risk Control - Upgrade ExchangeID Data Type [RedmineID: #241661] 

	Param's Explanation:
		@SiteID : All = 0
		@Currency : All = 0


	Example: exec NAP_CM_SVIPMaxBetPlayerSel @UserName = '', @SiteID = 0, @Currency = 0
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT SiteID, Site, e.currency, a.custid, c.username, SportType, Bettype, Multiplier, Note, IsTest, LastModifiedUser, lu.username AS LastModifiedUserName, LastModifiedTime
	FROM SVIPMaxBetPlayer a WITH(NOLOCK)
		CROSS APPLY ( SELECT TOP 1 custid, username, Site, currency FROM Customer cu WITH(NOLOCK) WHERE cu.custid = a.custid AND @Currency IN (0, cu.Currency) AND cu.username LIKE @UserName + '%' ) c 
		CROSS APPLY ( SELECT TOP 1 currency FROM exchange ex WITH(NOLOCK) WHERE ex.ExchangeId = c.currency ) e 
		OUTER APPLY ( SELECT TOP 1 username FROM Customer cuser WITH(NOLOCK) WHERE cuser.custid = a.LastModifiedUser ) lu 
	WHERE @SiteID IN (0, a.SiteID) AND IsTest <= @IsTest
	ORDER BY c.username ASC, Site ASC, e.currency ASC, Multiplier ASC
END
GO
