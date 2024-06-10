/*<info serverAlias="DBACC-bodb02,DBCUST-CustDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_GetModeCustomerClass]()
RETURNS BIT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : Build Customer Class Management
	DB: DBCUST/CustDB
	Original: f_GetModeCustomerClass
		Revisions:
			- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
			- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  
	Example:
	@ModeTest :  1 = Test , 0 = Original
*/
BEGIN
	DECLARE @ModeTest AS BIT = 0
	RETURN @ModeTest
END
GO