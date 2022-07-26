/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_GetProductSettingByFunction]
AS
BEGIN
/*
Created: 20201002@Eden
Task :  Get FuntionType/ProductID/Sportype/SettingType matrix to add UM config
DB: DBCUST.CustDB
Revisions:	
	- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
	- 20220726@Eddie:  config UM for Reports/ Bet List [RedmineID: #174852]

Param's Explanation:
	FunctionType = : 
		1 : Edit Setting
		2 : Create New
		101 : Transfer
		201 : Group Win Loss Reports
		202 : Outstandings
		203 : Group Win Los Analysis
		204 : Win Loss by Product
		205 : Commission by Bettype
		206 : Results
		207 : Progressive Games Contribution
		208 : Statement
		209 : Bet Credit Tracking
		210 : Risk Analysis
		211 : Group Bets & Forecast OST
		212 : Group Bets & Forecast BOF
		213 : Last Bets
		214 : Group Bet List Drilldown
		215 : Group Bet List
		
Examples : 
	EXEC [Acc_UMTool_GetProductSettingByFunction]
*/
SET NOCOUNT ON	
	DECLARE @ProductSportSettingType TABLE(
		FunctionType TINYINT, 
		ProductID    TINYINT, 
		SportType    SMALLINT, 
		SettingType  TINYINT
	)

	INSERT INTO @ProductSportSettingType(FunctionType,ProductID,SportType,SettingType)
	--Transfer
	SELECT 101,0,0,0 UNION ALL
	--Create New Customer
	SELECT 2,0,0,0 UNION ALL
	--Edit Setting (Non-DCS)
	SELECT 1,0,0,0 UNION ALL --All Sport
	SELECT 1,1,0,0 UNION ALL --SB + NG
	--SELECT 1,6,0,0 UNION ALL --RNG Casino
	SELECT 1,8,0,0 UNION ALL -- RNG Keno
	SELECT 1,12,0,0 UNION ALL  --GD
	-- Group Win Loss Reports
	SELECT 201,0,0,0 UNION ALL
	-- Outstandings
	SELECT 202,0,0,0 UNION ALL
	-- Group Win Los Analysis
	SELECT 203,0,0,0 UNION ALL
	-- Win Loss by Product
	SELECT 204,0,0,0 UNION ALL
	-- Commission by Bettype
	SELECT 205,0,0,0 UNION ALL
	-- Results
	SELECT 206,0,0,0 UNION ALL
	-- Progressive Games Contribution
	SELECT 207,0,0,0 UNION ALL
	-- Statement
	SELECT 208,0,0,0 UNION ALL
	-- Bet Credit Tracking
	SELECT 209,0,0,0 UNION ALL
	-- Risk Analysis
	SELECT 210,0,0,0 UNION ALL
	-- Group Bets & Forecast OST
	SELECT 211,0,0,0 UNION ALL
	-- Group Bets & Forecast BOF
	SELECT 212,0,0,0 UNION ALL
	-- Last Bets
	SELECT 213,0,0,0 UNION ALL
	-- Group Bet List Drilldown
	SELECT 214,0,0,0 UNION ALL
	-- Group Bet List
	SELECT 215,0,0,0

	--Edit Setting (DCS)
	INSERT INTO @ProductSportSettingType(FunctionType,ProductID,SportType,SettingType)
	SELECT DISTINCT 1 AS FunctionType, p.ProductID,p.SportType,p.SettingType
	FROM ProductSettingDetail p WITH(NOLOCK)
	WHERE SettingStatus = 0
	UNION ALL
	SELECT DISTINCT 1 AS FunctionType, p.ProductID,p.SportType,0 AS SettingType
	FROM ProductSettingDetail p WITH(NOLOCK)
	WHERE SettingStatus = 0
	UNION ALL
	SELECT DISTINCT 1 AS FunctionType, p.ProductID,0 AS SportType,p.SettingType
	FROM ProductSettingDetail p WITH(NOLOCK)
	WHERE SettingStatus = 0
	UNION ALL
	SELECT DISTINCT 1 AS FunctionType, p.ProductID,0 AS SportType,0 AS SettingType
	FROM ProductSettingDetail p WITH(NOLOCK)
	WHERE SettingStatus = 0

	SELECT c.FunctionType,
		c.ProductID,
		c.SportType,
		c.SettingType,
		0 AS Bettype, 
		0 as IsLive,
		FunctionTypeName = CASE WHEN FunctionType = 1 THEN 'Edit Setting'
								WHEN FunctionType = 2 THEN 'Add New Customer'
								WHEN FunctionType = 101 THEN 'Transfer'
								WHEN FunctionType = 201 THEN 'Group Win Loss Reports'
								WHEN FunctionType = 202 THEN 'Outstandings'
								WHEN FunctionType = 203 THEN 'Group Win Los Analysis'
								WHEN FunctionType = 204 THEN 'Win Loss by Product'
								WHEN FunctionType = 205 THEN 'Commission by Bettype'
								WHEN FunctionType = 206 THEN 'Results'
								WHEN FunctionType = 207 THEN 'Progressive Games Contribution'
								WHEN FunctionType = 208 THEN 'Statement'
								WHEN FunctionType = 209 THEN 'Bet Credit Tracking'
								WHEN FunctionType = 210 THEN 'Risk Analysis'
								WHEN FunctionType = 211 THEN 'Group Bets & Forecast OST'
								WHEN FunctionType = 212 THEN 'Group Bets & Forecast BOF'
								WHEN FunctionType = 213 THEN 'Last Bets'
								WHEN FunctionType = 214 THEN 'Group Bet List Drilldown'
								WHEN FunctionType = 215 THEN 'Group Bet List'
							END,
		ISNULL(p.ProductName,'All') AS ProductName,
		ISNULL(sp.SportName,'All') AS SportName,
		ISNULL(st.SettingName,'All') AS SettingName
	FROM @ProductSportSettingType c
		LEFT JOIN ProductSettingType st WITH(NOLOCK) ON c.SettingType = st.SettingType
		LEFT JOIN DBPRO.bodb02.dbo.Products p WITH(NOLOCK) ON c.ProductID = p.ProductID
		LEFT JOIN DBPRO.bodb02.dbo.Sports sp WITH(NOLOCK) ON c.sporttype = sp.sporttype
	ORDER BY c.FunctionType,c.ProductID,c.SportType,c.SettingType
END
GO