/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="vnteam" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_TOControl_GlobalSettingSel]() 
RETURNS TABLE
WITH SCHEMABINDING
AS

/*
    Created: 20171113@Helen
    Task: TO Control - Support to add default TO setting for new direct customers
    DB: DBCUST/CUSTDB
    
    Revisions:
		- 20171113@Helen: N/A
	
    Parameters Explanation:  
    
    Notes:
    + Soccer		:    Soccer global setting will be 300K MYR &  789Y SMA will be 200K USD.
    + Other Sports	:	150 K MYR
                                 
   
*/
RETURN (
   SELECT 1 sporttype, '789y' AS site,CAST(0 AS INT) ExchangeID, CAST(200000 AS MONEY) MaxTurnOver, CAST(3 AS INT) TOCurrency
   UNION ALL
   SELECT 1 AS sporttype, '' siteid,0 ExchangeID, 300000 MaxTurnOver, 2 TOCurrency --RM	
   UNION ALL
   SELECT 99 AS sporttype,'' siteid,0 ExchangeID, 150000 MaxTurnOver, 2 TOCurrency --RM	
   
)
GO
--GRANT EXECUTE ON [dbo].[f_NAP_GlobalSettingSel] TO [bodbAdminNet]
--GO
--GRANT EXECUTE ON [dbo].[f_NAP_GlobalSettingSel] TO [bodbDownlineNet]
--GO
--GRANT EXECUTE ON [dbo].[f_NAP_GlobalSettingSel] TO [bodbExtAccNet]
--GO




