
/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_UnassignedBettypeSel] 
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
			mt.Bettype, 
			bt.Typenamee
	   FROM DBPRO.bodb02.dbo.Sportbettypematrix mt WITH(NOLOCK)
		   INNER JOIN DBPRO.bodb02.dbo.bettype bt WITH(NOLOCK) ON mt.Bettype = bt.TypeId
	   WHERE mt.ProductID = @ProductID
		    AND mt.Bettype NOT IN
							(
							    SELECT 
									 w.BetTypeID
							    FROM Winlimit_GameGroupSetting w WITH(NOLOCK)
							    WHERE ProductID = @ProductID
							 );
    END;
GO
