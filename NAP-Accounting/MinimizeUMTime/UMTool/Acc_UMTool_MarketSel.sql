/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [Acc_UMTool_MarketSel]
AS

/*
Created by: Eddie
Date: 2022-07-26
Task : get market
DB: DBACC.bodb02
Revisions:
	- 20220726@Eddie: Dropdownlist Sites -> IBCBET, 789y and IBCIndo [RedmineID: #174852]
	
*/

SET NOCOUNT ON

SELECT 0  AS [Marketid], 'All' 	   AS [Market]
UNION ALL                        
SELECT -1 AS [Marketid], 'IBCBET'  AS [Market]
UNION ALL                        
SELECT -2 AS [Marketid], '789y'    AS [Market]
UNION ALL
SELECT -3 AS [Marketid], 'IBCIndo' AS [Market]

GO