/*<info serverAlias="DBCUST-CUSTDB" executers="asv_cust" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[API_BetLimitIncrease_GetSite] 
	@IsTest BIT = 0
AS
/*
	Created: Winfred
	Date: 20250224
	Task : [NAP CM] Customer - Increase Bet Limit
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20250224@Winfred: [NAP CM] Customer - Increase Bet Limit [RedmineID: #218073] 

	Param's Explanation:
	Sample Format Json:
	exec API_SVIPMaxBetPlayer_GetSite 
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT DISTINCT SiteID 
	FROM SVIPMaxBetPlayer WITH(NOLOCK)
	WHERE  IsTest = @IsTest
END
GO
