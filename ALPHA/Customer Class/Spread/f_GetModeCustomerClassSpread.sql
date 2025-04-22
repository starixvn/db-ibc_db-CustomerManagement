/*<info serverAlias="DBCUST-CustDB" executers="Dot_Admin,svc_tig" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_GetModeCustomerClassSpread]()
RETURNS BIT
AS
/*
	Created: Winfred
	Date: 20240215
	Task : Customer Class - SP Integrate
	DB: DBCUST/CustDB
	Original: f_GetModeCustomerClassSpread
		Revisions:
		- 20240215@Winfred: [NAP CM] Customer Class - SP Integrate Spread setting [RedmineID: #200996] 
		- 20250421@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread and switch Place bet to _UAT [Redmine: #186118]
	Example:
	@ModeTest :  1 = Test , 0 = Original
*/
BEGIN
	DECLARE @ModeTest AS BIT = 1
	RETURN @ModeTest 
END
GO