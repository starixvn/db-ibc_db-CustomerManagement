/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_ProductSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID	TINYINT
AS
/*
		Task : NAP -  Flexible Initializing Stake Level/Bet Limit
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
			- 20220705@Tacy: NAP - Flexible Initializing Global Bet Limit [Redmine: #174509]
			- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
			- 20230628@Tacy: NG2 - Remove Setting [Redmine: #189762]
		Param's Explanation:
			@ProductID  0 : All, <> 0 : ProductID
	*/
BEGIN
	
	SET NOCOUNT ON;
	
	CREATE TABLE #Products(ProductID TINYINT PRIMARY KEY, ProductName VARCHAR(50))

	CREATE TABLE #ProductSettingDetail(
		[SettingType] [smallint],
		[SportType] [smallint],
		[BetType] [smallint],
		[IsLive] [bit] ,
		[ProductID] [tinyint],
	PRIMARY KEY([SettingType] ASC,[SportType] ASC,[BetType] ASC,[IsLive] ASC)
	)

	INSERT INTO #ProductSettingDetail(SportType,BetType,SettingType,IsLive,ProductID)
	SELECT SportType,BetType,SettingType,IsLive,ProductID
	FROM dbo.f_CustSetting_ProductSettingDetailSel(1)
	UNION 
	SELECT SportType,BetType,SettingType,IsLive,ProductID
	FROM dbo.f_CustSetting_ProductSettingDetailSel(3)

	INSERT INTO #Products  (ProductID,ProductName)	
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)
	WHERE Enabled=1
	
	SELECT ProductID , ProductName
	FROM (			
		SELECT DISTINCT
			 psd.ProductID
			 ,p.ProductName
		FROM #ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Products p WITH(NOLOCK) ON psd.ProductID = p.ProductID
		WHERE (psd.SettingType IN (2,7,8,9,16,17,20)) AND (@ProductID = 0 OR psd.ProductID = @ProductID)
			AND psd.ProductID NOT IN (1,3,8)
		UNION
		SELECT DISTINCT
			 ps.ProductID
			 ,p.ProductName
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Products p WITH(NOLOCK) ON ps.ProductID = p.ProductID
		WHERE (ps.SettingType IN (2,7,8,10,11,12)) 
			AND (@ProductID = 0 OR ps.ProductID = @ProductID)
			AND psd.SettingStatus<>2
		) KQ
	ORDER BY ProductID
   
   DROP TABLE #Products
   DROP TABLE #ProductSettingDetail
END
GO
