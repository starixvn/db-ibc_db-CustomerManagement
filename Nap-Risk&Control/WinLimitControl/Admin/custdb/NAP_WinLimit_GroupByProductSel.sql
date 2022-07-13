
/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_GroupByProductSel] 
	@ProductID INT
AS  
   
/*
Created: Robert
Date: 2022-05-18
Task: #168458 - CWL - Enhance Currency Win Limit Setting page

DB: DBCUST/CustDB

Revisions:
20220518@Robert: Enhance Currency Win Limit Setting page [168458]
Parameters Explanation:     
     
Example:
EXEC [NAP_WinLimit_CurrencySelAll] 
*/

    BEGIN
	   SET NOCOUNT ON;


	   SELECT DISTINCT 
			w.GroupID, 
			g.GroupName
	   FROM [dbo].Winlimit_GameGroupSetting w WITH(NOLOCK)
		   INNER JOIN dbo.Winlimit_Group g WITH(NOLOCK) ON w.GroupID = g.GroupID
	   WHERE w.ProductID = @ProductID
	   ORDER BY 
			  g.GroupName;
    END;
GO
