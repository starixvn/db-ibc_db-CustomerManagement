/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet, bodbExtAccNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_ExchangeSel]
	 @System varchar(50) = 'ACCOUNTING',
	 @IsTest BIT = 0
AS
/*
	DB: DBCUST/CUSTDB
	Original: member/addmaster.asp

	Revisions:
		- 20090526@Phuc: get allowed HR currency from f_GetHRAllowedCurr
		- 20100720@Shifu: get system name
		- 20111020@Johnson: remove currency C and H from result
		- 20160620@Elodie: Add parameter @IsTest for testing purpose
*/
SET NOCOUNT ON

IF(@System = 'ACCOUNTING')
BEGIN
	select 
		ExchangeID, Currency,
		case when currency IN(select currency from dbo.[f_GetHRAllowedCurr]()) then 1 else 0 end HRAllowed
	from 
		exchange with (NOLOCK)
	WHERE ((@IsTest = 0 AND exchangeID NOT IN (27,28)) OR @IsTest = 1)
	ORDER BY 
		currency
END
ELSE
BEGIN
	

	SELECT 
		ExchangeID, Currency,
		case when currency IN(select currency from dbo.[f_GetHRAllowedCurr]()) then 1 else 0 end HRAllowed
	FROM 
		exchange with (NOLOCK)
	WHERE ExchangeID IN (SELECT exchangeID FROM dbo.f_CurrencyBySystem(@System)) AND ExchangeID NOT IN (27,28)
	ORDER BY 
		currency
END

