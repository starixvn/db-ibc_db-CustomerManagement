/*<info serverAlias="DBAGE-bodb02" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_PromotionProductList]
	@Site VARCHAR(50), 
	@Currency INT,
	@SettingStatus TINYINT=0
AS
/*
    Created: 20250707@Johnson
	Task : Get all product list for promotion cash service which offered for Site/Currency
	DB: DBAGE/bodb02
  
	Revisions:
        - 20250707@Johnson: initial sp [redmine:#232347]
*/    
BEGIN
    SET NOCOUNT ON

    CREATE TABLE #TempProductInfo (
        ProductID TINYINT,
        ProductName VARCHAR(50),   
        isHidden bit, 
        EndOfSupportDate datetime, 
        OrderNo int,
        [Type] TINYINT
    )

    INSERT INTO #TempProductInfo (ProductID, ProductName,isHidden,EndOfSupportDate,OrderNo,[Type])
    EXEC Age_GetOfferedProductBySiteCurrency
        @Site = @site, 
        @Currency =  @Currency,
        @SettingStatus = @SettingStatus

    ;WITH T AS (
    SELECT ProductID, ProductName,isHidden,EndOfSupportDate,OrderNo, 
        CASE WHEN [Type] = 0 AND ProductID = 1 THEN 1 --Sportsbooks
            WHEN [Type] = 0 AND ProductID = 5 THEN 44 --RNG Games
            WHEN [Type] = 41 THEN 41 --RNG Casino
            WHEN [Type] = 53 THEN 53 --Live Casino
            END AS [ProductCategoryID]
    FROM #TempProductInfo
    )
    SELECT ProductID, ProductName,OrderNo,[ProductCategoryID]
    FROM T
    WHERE [ProductCategoryID] IS NOT NULL
        AND IsHidden = 0
        AND EndOfSupportDate IS NULL
   
    DROP TABLE #TempProductInfo
END