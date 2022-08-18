/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Acc_UMTool_MarketSel]
AS

/*
Created by: Eddie
Date: 2022-07-26
Task : get market
DB: DBCUST-CUSTDB
Revisions:
	- 20220726@Eddie: Dropdownlist Sites -> IBCBET, 789y and IBCIndo [RedmineID: #174852]
	
*/

SET NOCOUNT ON

DECLARE @Market TABLE(MarketId INT, MarketName VARCHAR(300))

INSERT INTO @Market(MarketId, MarketName)
VALUES (0 , 'All')
	  ,(-1, 'IBCBET')
	  ,(-2, '789y')
	  ,(-3, 'IBCIndo')

SELECT MarketId, MarketName
FROM @Market

GO