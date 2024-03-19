
/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_UnassignedBettypeUdp] 
	@ProductID  INT, 
	@BettypeIDs VARCHAR(2000)
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

	   CREATE TABLE #tplBettype
				 (
		   Bettype INT
				 );
	   INSERT INTO #tplBettype
			SELECT 
				  t.val
			FROM dbo.strSplit(@BettypeIDs, ',') t;


	   DELETE w
	   FROM [dbo].[Winlimit_GameGroupSetting] w WITH(NOLOCK)
		   INNER JOIN #tplBettype t ON w.BetTypeID = t.Bettype
	   WHERE 
		    w.ProductID = @ProductID;

	   DROP TABLE #tplBettype;
    END;
GO
