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

Param's Explanation:
	FunctionType = : 
		1 : Edit Setting
		2 : Create New
		1 : Transfer			   
		
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
	SELECT 1,6,0,0 UNION ALL --RNG Casino
	SELECT 1,8,0,0 UNION ALL -- RNG Keno
	SELECT 1,12,0,0  --GD

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