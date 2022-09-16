/*<info serverAlias="DBEXT-bodb02" executers="bodbAdminNet" isFunction="0"></info>*/
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
	--AND Code in ('GBP', 'TWD')  
	AND 
		1 = CASE WHEN  @Type = 0 AND currency NOT IN ('TRX','DOGE','ELON','SHIB','BTC','ETH','USDT3','USDC','HOT','AMP','ZEON','RSR','VET','ZIL','PEOPLE','ADA','XRP','LOOKS','XPRT','CRO','FLOW','SAND','AVAX','APE','CAKE','ENS','UNI') THEN 1
				WHEN @Type = 1 AND currency  IN ('TRX','DOGE','ELON','SHIB','BTC','ETH','USDT3','USDC','HOT','AMP','ZEON','RSR','VET','ZIL','PEOPLE','ADA','XRP','LOOKS','XPRT','CRO','FLOW','SAND','AVAX','APE','CAKE','ENS','UNI') THEN 1 
			ELSE 0 END
END
 

