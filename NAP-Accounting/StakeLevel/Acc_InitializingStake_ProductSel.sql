/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_ProductSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID	TINYINT
AS
BEGIN
	/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
	*/
	SET NOCOUNT ON;
	--@ProductID  0 : All, <> 0 : ProductID
	CREATE TABLE #Products(ProductID TINYINT PRIMARY KEY, ProductName VARCHAR(50))

	INSERT INTO #Products  (ProductID,ProductName)	
	SELECT ProductID,ProductName 
	FROM DBACC.bodb02.dbo.products WITH(NOLOCK)
				
	SELECT DISTINCT
		 psd.ProductID
		 ,p.ProductName
	FROM ProductSettingDetail psd WITH(NOLOCK)
		INNER JOIN #Products p WITH(NOLOCK) ON psd.ProductID = p.ProductID
	WHERE (psd.SettingType IN (7, 8, 17)) AND (@ProductID = 0 OR psd.ProductID = @ProductID)
	ORDER BY psd.ProductID
   
   DROP TABLE #Products
END
GO
