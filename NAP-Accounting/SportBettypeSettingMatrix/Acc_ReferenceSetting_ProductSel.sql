/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ReferenceSetting_ProductSel] 
	-- Add the parameters for the stored procedure here
	  @pMutilProductID	VARCHAR(Max)=''
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255] 
		- 20230803@Tacy: NAP - Manage SportBettypeSettingMatrix - Add more fields [Redmine: #192732]
		
	Param's Explanation:
		@pMutilProductID  0 : All, <> 0 : ProductID

	Example:
		EXEC [Acc_ReferenceSetting_ProductSel] @pMutilProductID='0'
*/
BEGIN
	SET NOCOUNT ON;

	IF @pMutilProductID=''
		RETURN

	CREATE TABLE #Products(
			ProductID	SMALLINT PRIMARY KEY, 
			ProductName NVARCHAR(50)
	)

	INSERT INTO #Products (ProductID, ProductName)
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)
	WHERE Enabled=1
	AND (@pMutilProductID='0' OR ProductID IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilProductID, ',')))

	SELECT p.ProductID, p.ProductName
	FROM #Products p
	CROSS APPLY (SELECT TOP 1 1 as value 
				 FROM SportBettypeSettingMatrix sm WITH (NOLOCK) 
				 WHERE p.ProductID=sm.RealProductId AND sm.isDeleted=0) t
	ORDER BY p.ProductID
END
GO