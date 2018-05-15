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
		- 20171113@Helen: Create new [Redmine: 86052]
    - 20180509@Kan: Update new global setting for World Cup event [Redmine: 92010]
      + 789y site: equivalent to USD 200,000
      + Other sites: equivalent to MYR 500,000

	
    Parameters Explanation:  
    
    Notes:
    + Soccer		:    Soccer global setting will be 300K MYR & 789Y SMA will be 200K USD.
    + Other Sports	:	150 K MYR
                                 
   
*/
RETURN (
   SELECT CAST(1 AS SMALLINT) sporttype, CAST('789y' AS NVARCHAR(50)) AS site,CAST(0 AS INT) ExchangeID, CAST(200000 AS MONEY) MaxTurnOver, CAST(3 AS INT) TOCurrency -- US$
   UNION ALL
   --SELECT 1 AS sporttype, '' site,0 ExchangeID, 300000 MaxTurnOver, 2 TOCurrency --RM	
   SELECT 1 AS sporttype, '' site,0 ExchangeID, 500000 MaxTurnOver, 2 TOCurrency --RM	
   UNION ALL
   SELECT 99 AS sporttype,'' site,0 ExchangeID, 150000 MaxTurnOver, 2 TOCurrency --RM	
   -------------------------CONFIG FOR TEST CURRENCY -----------------------------------------
   -- for UUS
   UNION ALL
   SELECT 1 sporttype, '789y' AS site,20 ExchangeID, 200000 MaxTurnOver, 20 TOCurrency -- UUS
   UNION ALL  
   SELECT 1 AS sporttype, '' site,20 ExchangeID, 300000 MaxTurnOver, 20 TOCurrency --UUS   
   UNION ALL  
   SELECT 99 AS sporttype,'' site,20 ExchangeID, 150000 MaxTurnOver, 20 TOCurrency --UUS   
   
   -- for H
   UNION ALL
   SELECT 1 sporttype, '789y' AS site,27 ExchangeID, 200000 MaxTurnOver, 27 TOCurrency -- H
   UNION ALL  
   SELECT 1 AS sporttype, '' site,27 ExchangeID, 300000 MaxTurnOver, 27 TOCurrency --H   
   UNION ALL  
   SELECT 99 AS sporttype,'' site,27 ExchangeID, 150000 MaxTurnOver, 27 TOCurrency --H
   
   -- for C
   UNION ALL
   SELECT 1 sporttype, '789y' AS site,28 ExchangeID, 200000 MaxTurnOver, 28 TOCurrency -- C
   UNION ALL  
   SELECT 1 AS sporttype, '' site,28 ExchangeID, 300000 MaxTurnOver, 28 TOCurrency --C   
   UNION ALL  
   SELECT 99 AS sporttype,'' site,28 ExchangeID, 150000 MaxTurnOver, 28 TOCurrency --C
   
)
GO

