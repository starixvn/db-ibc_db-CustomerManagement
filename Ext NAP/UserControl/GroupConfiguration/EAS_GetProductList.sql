/*<info serverAlias="DBAGE-bodb02" executers="bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GetProductList]
AS

/*  
	Created: 20191106@Percy  
	Task: Ext NAP - Get all enabled products
	DB: DBAGE.bodb02  
  
	Revisions:
		- 20191106@Percy: Initialize SP [Redmine: #118699]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		CAST(ISNULL(gp.GroupProductId, p.ProductID) AS INT) AS ProductID
	   ,p.ProductName
	FROM dbo.Products p WITH (NOLOCK)
		LEFT JOIN dbo.f_GroupProduct() gp ON p.ProductID = gp.ProductId AND gp.ProductId <> gp.GroupProductId
	WHERE p.GroupType = 0 AND gp.ProductId IS NULL
		AND p.Enabled = 1

	SET NOCOUNT OFF
END
GO