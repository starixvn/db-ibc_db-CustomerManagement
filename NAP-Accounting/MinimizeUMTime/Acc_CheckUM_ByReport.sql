/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CheckUM_ByReport]
	@MarketId	INT = NULL
AS
	/*
	Created: 20220816@Eddie
	Task :  Check UM config by Market
	DB: DBCUST.CustDB
	Revisions:	
		- 20220816@Eddie: Initialize SPs [RedmineID: #174852]
	
	Param's Explanation:
		- @MarketId : 
			0 : 'All'
			-1: 'IBCBET'
			-2: '789y'
			-3: 'IBCIndo'			
	*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Market_spec TABLE(MarketId INT PRIMARY KEY, MarketName VARCHAR(300))
	
	INSERT INTO @Market_spec(MarketId, MarketName)
	EXEC dbo.Acc_UMTool_MarketSel;
	
	SELECT [FunctionTypeName] = CASE WHEN uc.FunctionType = 201 THEN 'Group Win Loss Reports'
								WHEN uc.FunctionType = 202 THEN 'Outstandings'
								WHEN uc.FunctionType = 203 THEN 'Group Win Los Analysis'
								WHEN uc.FunctionType = 204 THEN 'Win Loss by Product'
								WHEN uc.FunctionType = 205 THEN 'Commission by Bettype'
								WHEN uc.FunctionType = 206 THEN 'Results'
								WHEN uc.FunctionType = 207 THEN 'Progressive Games Contribution'
								WHEN uc.FunctionType = 208 THEN 'Statement'
								WHEN uc.FunctionType = 209 THEN 'Bet Credit Tracking'
								WHEN uc.FunctionType = 210 THEN 'Risk Analysis'
								WHEN uc.FunctionType = 211 THEN 'Group Bets & Forecast OST'
								WHEN uc.FunctionType = 212 THEN 'Group Bets & Forecast BOF'
								WHEN uc.FunctionType = 213 THEN 'Last Bets'
								WHEN uc.FunctionType = 214 THEN 'Group Bet List Drilldown'
								WHEN uc.FunctionType = 215 THEN 'Group Bet List'
							END
		, ms.MarketName, uc.BeginTime, uc.EndTime, uc.ShowTime  
	FROM dbo.UMConfig uc WITH (NOLOCK)
		INNER JOIN @Market_spec ms ON ms.MarketId = uc.SiteID
	WHERE uc.FunctionType NOT IN (1, 2, 101)
		AND (uc.SiteID = @MarketId OR @MarketId IS NULL)
END
GO