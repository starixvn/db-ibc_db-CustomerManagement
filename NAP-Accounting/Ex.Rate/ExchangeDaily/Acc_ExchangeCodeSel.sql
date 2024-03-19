/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet,wsv_nap" isFunction="0"></info>*/
CREATE PROCEDURE  [dbo].[Acc_ExchangeCodeSel]   
 @Type TINYINT = 0  
AS  
/*  
Created: Henry  
Task : Get the list of Code need to get the exchange rate  
DB: DB052.BODB02   
Revisions:  
 - 20140220@Dan: exclude code 'C','H'  
 - 20220908@Evan: Support crypto  [Redmine: #177481]  
*/    
BEGIN
	SET NOCOUNT ON  
  
	SELECT DISTINCT Code, CASE WHEN currency = 'USDT3' THEN 'USDT' ELSE Currency END Currency, @Type AS Type, stakerate AS CoinMarketCapID
	FROM exchange WITH (NOLOCK)  
	WHERE isnull(Code,'') <> ''   
	AND Code not in ('C', 'H')  
	AND CurrencyType = @Type
END
 

