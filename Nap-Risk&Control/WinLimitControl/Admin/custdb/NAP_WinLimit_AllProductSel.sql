/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [NAP_WinLimit_AllProductSel]
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBGLOB-GlobCustDB

Revisions:
	- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
	- 20250227@Johnson: move sp to GlobCustDB [redmine: #216870]
Parameters Explanation:

Example: 
EXEC [NAP_WinLimit_AllProductSel]
*/

     SET NOCOUNT ON;
     SELECT DISTINCT
            p.ProductId Id,
            p.ProductName Name
     FROM dbo.f_Nap_WinLimit_ProductSettingSel(DEFAULT) s
          LEFT JOIN DBTXN.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID = s.ProductId
     ORDER BY p.ProductName;
GO
