ALTER PROCEDURE [dbo].[Acc_ExchangeSel]
	 @System varchar(50) = 'ACCOUNTING'
AS
/*
DB: DBTRANS.BODB02
Original: member/addmaster.asp

Revisions:
	- 20090526@Phuc: get allowed HR currency from f_GetHRAllowedCurr
	- 20100720@Shifu: get system name
	- 20111020@Johnson: remove currency C and H from result
*/
SET NOCOUNT ON
IF(@System = 'ACCOUNTING')
BEGIN
	select 
		ExchangeID, Currency,
		case when currency IN(select currency from dbo.[f_GetHRAllowedCurr]()) then 1 else 0 end HRAllowed
	from 
		exchange with (NOLOCK)
	WHERE exchangeID NOT IN (27,28)-- Currency = C , H
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
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeSel] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeSel] TO [vnteam]
