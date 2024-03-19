/*<info serverAlias="DBCUST-CUSTDB" selecters="bodbAdminNet,wsv_nap" viewers="" isFunction="1"></info>*/
CREATE FUNCTION [dbo].[f_CustReport_UM_ProductsSel](@Functiontype	TINYINT)
RETURNS TABLE
AS
	/*
	Created: 20220817@Eddie
	Task :  get FunctionTypeName By Functiontype
	DB: DBCUST.CustDB
	Revisions:	
		- 20220817@Eddie: Initialize Function [Redmine: #174852]
		- 20220929@Eddie: Add 'My Watchlist' into option list [Redmine: #174852]
		- 20230103@Eddie: Change name 'My Watchlist' to 'Watchlist & Thresholds' [Redmine: #179067]
		- 20230720@Lewis: Add new FunctionType - 'Last Bets (New)' [Redmine: #186142]
	Param's Explanation:
		1   : 'Edit Setting'
		2   : 'Add New Customer'
		101 : 'Transfer'
		201 : 'Group Win Loss Reports'
		202 : 'Outstandings'
		203 : 'Group Win Loss Analysis'
		204 : 'Win Loss by Product'
		205 : 'Commission by Bettype'
		206 : 'Results'
		207 : 'Progressive Games Contribution'
		208 : 'Statement'
		209 : 'Bet Credit Tracking'
		210 : 'Risk Analysis'
		211 : 'Group Bets & Forecast OST'
		212 : 'Group Bets & Forecast BOF'
		213 : 'Last Bets'
		214 : 'Group Bet List Drilldown'
		215 : 'Group Bet List'
		216 : 'Watchlist & Thresholds'
		217 : 'Last Bets (New)'
	Examples : 
		SELECT * FROM [dbo].[f_CustReport_UM_ProductsSel](1)
	*/

RETURN
	SELECT CASE WHEN @Functiontype = 1   THEN 'Edit Setting'
				WHEN @Functiontype = 2   THEN 'Add New Customer'
				WHEN @Functiontype = 101 THEN 'Transfer'
				WHEN @Functiontype = 201 THEN 'Group Win Loss Reports'
				WHEN @Functiontype = 202 THEN 'Outstandings'
				WHEN @Functiontype = 203 THEN 'Group Win Loss Analysis'
				WHEN @Functiontype = 204 THEN 'Win Loss by Product'
				WHEN @Functiontype = 205 THEN 'Commission by Bettype'
				WHEN @Functiontype = 206 THEN 'Results'
				WHEN @Functiontype = 207 THEN 'Progressive Games Contribution'
				WHEN @Functiontype = 208 THEN 'Statement'
				WHEN @Functiontype = 209 THEN 'Bet Credit Tracking'
				WHEN @Functiontype = 210 THEN 'Risk Analysis'
				WHEN @Functiontype = 211 THEN 'Group Bets & Forecast OST'
				WHEN @Functiontype = 212 THEN 'Group Bets & Forecast BOF'
				WHEN @Functiontype = 213 THEN 'Last Bets'
				WHEN @Functiontype = 214 THEN 'Group Bet List Drilldown'
				WHEN @Functiontype = 215 THEN 'Group Bet List'
				WHEN @Functiontype = 216 THEN 'Watchlist & Thresholds' 
				WHEN @Functiontype = 217 THEN 'Last Bets (New)' 
	END [FunctionTypeName]
GO