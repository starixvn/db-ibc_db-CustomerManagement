/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_ProductSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID	TINYINT
AS
/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
		
		Param's Explanation:
			@ProductID  0 : All, <> 0 : ProductID
	*/
BEGIN
	
	SET NOCOUNT ON;
	
	CREATE TABLE #Products(ProductID TINYINT PRIMARY KEY, ProductName VARCHAR(50))

	INSERT INTO #Products  (ProductID,ProductName)	
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)
	
	SELECT ProductID , ProductName
	FROM (			
		SELECT DISTINCT
			 psd.ProductID
			 ,p.ProductName
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Products p WITH(NOLOCK) ON psd.ProductID = p.ProductID
		WHERE (psd.SettingType IN (7, 8, 17)) AND (@ProductID = 0 OR psd.ProductID = @ProductID)
		UNION
		SELECT DISTINCT
			 ps.ProductID
			 ,p.ProductName
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Products p WITH(NOLOCK) ON ps.ProductID = p.ProductID
		WHERE (ps.SettingType IN (7, 8)) AND (@ProductID = 0 OR ps.ProductID = @ProductID)
		) KQ
	ORDER BY ProductID
   
   DROP TABLE #Products
END
GO
