
/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingByProductSel] 
	@ProductId INT, 
	@GroupId   INT
AS  
   
/*
Created: Robert
Date: 2022-05-18
Task: #168458 - CWL - Enhance Currency Win Limit Setting page

DB: DBCUST/CustDB

Revisions:
20220518@Jacob: Enhance Currency Win Limit Setting page [168458]
Parameters Explanation:     
     
Example:
EXEC [NAP_WinLimit_CurrencySelAll] 
*/

    BEGIN
	   SET NOCOUNT ON;
	   DECLARE 
		   @SiteId INT;

	   CREATE TABLE #tplCurrencySetting
				 (
		   ExchangeId        INT, 
		   Level1            DECIMAL, 
		   Level2            DECIMAL, 
		   Level3            DECIMAL, 
		   Level101          DECIMAL, 
		   Level102          DECIMAL, 
		   IsBlockedPlaceBet BIT, 
		   IsBlockedTransfer BIT
				 );
	   CREATE INDEX IDX_tplCurrencySetting_ExchangeId ON #tplCurrencySetting(ExchangeId);

	   SELECT TOP 1 
			@SiteId = w.SiteID
	   FROM [dbo].[WinLimit_ProductSettingDetail] w(NOLOCK)
	   WHERE w.ProductID = @ProductId
		    AND w.GroupID = @GroupId
	   GROUP BY 
			  w.SiteID
	   ORDER BY 
			  COUNT(1) DESC;


	   INSERT INTO #tplCurrencySetting
		 (
			ExchangeId, 
			Level1, 
			Level2, 
			Level3, 
			Level101, 
			Level102
		 )
			SELECT 
				  piv.ExchangeID, 
				  piv.[1] Level1, 
				  piv.[2] Level2, 
				  piv.[3] Level3, 
				  piv.[101] Level101, 
				  piv.[102] Level102
			FROM(SELECT 
					  w.ExchangeID, 
					  w.LevelID, 
					  w.MaxWinLimit_RM
				FROM [dbo].[WinLimit_ProductSettingDetail] w WITH(NOLOCK)
				WHERE w.ProductID = @ProductId
					 AND w.GroupID = @GroupId
					 AND w.SiteID = 23) src PIVOT(MAX(MaxWinLimit_RM) FOR [LevelID] IN(
																		  [1], 
																		  [2], 
																		  [3], 
																		  [101], 
																		  [102])) piv;

	   UPDATE t
		SET 
		    t.IsBlockedPlaceBet = w.IsBlockedPlaceBet, 
		    t.IsBlockedTransfer = w.IsBlockedTransfer
	   FROM #tplCurrencySetting t
		   INNER JOIN [dbo].[WinLimit_ProductSettingDetail] w WITH(NOLOCK) ON t.ExchangeId = w.ExchangeID
	   WHERE 
		    w.ProductID = @ProductId
		    AND w.SiteID = @SiteId
		    AND w.GroupID = @GroupId
		    AND w.LevelID = 3;

	   SELECT 
			t.ExchangeId, 
			e.currency, 
			t.Level1, 
			t.Level2, 
			t.Level3, 
			t.Level101, 
			t.Level102, 
			t.IsBlockedPlaceBet, 
			t.IsBlockedTransfer
	   FROM #tplCurrencySetting t
		   INNER JOIN dbo.exchange e WITH(NOLOCK) ON t.ExchangeId = e.ExchangeId;

	   DROP TABLE #tplCurrencySetting;

    END;
GO
