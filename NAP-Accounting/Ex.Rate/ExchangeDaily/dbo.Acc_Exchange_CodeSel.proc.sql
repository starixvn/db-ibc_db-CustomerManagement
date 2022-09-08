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
  
	SELECT DISTINCT Code, Currency, @Type AS Type  
	FROM exchange WITH (NOLOCK)  
	WHERE isnull(Code,'') <> ''   
	AND Code not in ('C', 'H')  
	--AND Code in ('GBP', 'TWD')  
	AND 
		1 = CASE WHEN  @Type = 0 AND Code NOT IN ('SHI','ELO','TRX','DOG','ETH','BTC') THEN 1
				WHEN @Type = 1 AND Code  IN ('SHI','ELO','TRX','DOG','ETH','BTC') THEN 1 
			ELSE 0 END
END
 

