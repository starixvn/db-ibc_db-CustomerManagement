/*<info serverAlias="DBACC-bodb02" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_ProductSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID		TINYINT
	, @SettingStatus	TINYINT
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
			- 20230918@Tacy: NAP - Global betlimit - Support to initial setting on UAT [Redmine: #192557]
			- 20251111@Dave: Live Casino - Adjust-pt-comm-for-live-casino [RedmineID: #242260]

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
	SELECT DISTINCT SportType,BetType,SettingType,IsLive,ProductID
	FROM dbo.f_CustSetting_ProductSettingDetailSel(@SettingStatus)
	WHERE (SettingType IN (2,7,8,9,16,17,20)) AND (@ProductID = 0 OR ProductID = @ProductID)
		AND ProductID NOT IN (1,3,8)

	INSERT INTO #Products  (ProductID,ProductName)	
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)
	WHERE Enabled=1
		AND (@ProductID = 0 OR ProductID = @ProductID)
	
	SELECT ProductID , ProductName
	FROM (			
		SELECT DISTINCT
			 psd.ProductID
			 ,p.ProductName
		FROM #ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Products p WITH(NOLOCK) ON psd.ProductID = p.ProductID
		UNION
		SELECT DISTINCT
			 ps.ProductID
			 ,p.ProductName
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Products p WITH(NOLOCK) ON ps.ProductID = p.ProductID
		WHERE (ps.SettingType IN (2,7,8,10,11,12)) 
			AND psd.SettingStatus<>2
		) KQ
	ORDER BY ProductID ASC
   
   DROP TABLE #Products
   DROP TABLE #ProductSettingDetail
END
GO
