/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_GetModeCustomerClassNonSports]()
RETURNS BIT
AS
/*
	Created: Winfred
	Date: 20240923
	Task : [NAP CM] Integrate for Non-Sports
	DB: DBCUST/CustDB
	Original: f_GetModeCustomerClass
		Revisions:
			- 20240923@Winfred: [NAP CM] CCMgt - Integrate for Non-Sports [RedmineID: #199852] 
	Example:
	@ModeTest :  1 = Test , 0 = Original
*/
BEGIN
	DECLARE @ModeTest AS BIT = 0
	RETURN @ModeTest
END
GO