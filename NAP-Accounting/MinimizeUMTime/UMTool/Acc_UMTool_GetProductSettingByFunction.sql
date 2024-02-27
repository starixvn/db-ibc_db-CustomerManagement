/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
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
	- 20220817@Eddie:  change code by function 'f_CustReport_UM_ProductsSel' [RedmineID: #174852]
	- 20220929@Eddie:  Add 'My Watchlist' into option list [Redmine: #174852]
	- 20230323@Eden: Migrate NG and Keno to DCS structure [Redmine: #179711]
	- 20230720@Lewis: Add Funtion Type - Last Bets(New) [Redmine: #186142]
	- 20231023@Helios: SportsBook_PartialUM [RedmineID: #199603]

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
		216 : My Watchlist
		217 : Last Bets(New)
		
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
	--SELECT 1,1,0,0 UNION ALL --SB + NG
	--SELECT 1,6,0,0 UNION ALL --RNG Casino
	--SELECT 1,8,0,0 UNION ALL -- RNG Keno
	--SELECT 1,12,0,0 UNION ALL  --GD
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
	SELECT 215,0,0,0 UNION ALL
	-- My Watchlist
	SELECT 216,0,0,0 UNION ALL
	-- Last Bets(New)
	SELECT 217,0,0,0

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

	DECLARE @tmp_Sports TABLE (SportType SMALLINT, SportName NVARCHAR(50))

	INSERT INTO @tmp_Sports (SportType, SportName)
	EXEC DBACC.bodb02.dbo.Acc_SporttypeSel @Mode=1

	SELECT c.FunctionType,
		c.ProductID,
		c.SportType,
		c.SettingType,
		0 AS Bettype, 
		0 as IsLive,
		FunctionTypeName = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(FunctionType)),
		ISNULL(p.ProductName,'All') AS ProductName,
		ISNULL(sp.SportName,'All') AS SportName,
		ISNULL(st.SettingName,'All') AS SettingName
	FROM @ProductSportSettingType c
		LEFT JOIN ProductSettingType st WITH(NOLOCK) ON c.SettingType = st.SettingType
		LEFT JOIN DBPRO.bodb02.dbo.Products p WITH(NOLOCK) ON c.ProductID = p.ProductID
		LEFT JOIN @tmp_Sports sp  ON c.sporttype = sp.sporttype
	ORDER BY c.FunctionType,c.ProductID,c.SportType,c.SettingType
END
GO