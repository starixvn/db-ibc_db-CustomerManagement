/*<info serverAlias="DBACC-bodb02,DBCUST-CustDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/
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
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297] 
	Example:
	@ModeTest :  1 = Test , 0 = Original
*/
BEGIN
	DECLARE @ModeTest AS BIT = 0
	RETURN @ModeTest 
END
GO