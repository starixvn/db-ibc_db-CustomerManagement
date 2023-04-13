/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="1" isNested="1"></info>*/
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
	Example:
	@ModeTest :  1 = Test , 0 = Original
*/
BEGIN
	DECLARE @ModeTest AS BIT = 0
	RETURN @ModeTest
END
GO