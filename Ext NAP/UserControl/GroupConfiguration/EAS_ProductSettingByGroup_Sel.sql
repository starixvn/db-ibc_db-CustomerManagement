/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_ProductSettingByGroup_Sel]
	@GroupId	INT = NULL
AS
/*  
	Created by: 20200923@Eden
	Task: Ext NAP --> Customer --> Super List --> Edit multiple Product Status --> Product List
	DB: DBPOL.NAP_UserControl

	Revisions:  
		- 20200923@Eden: First commit [Redmine: #141832]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
*/
BEGIN
	SET NOCOUNT ON

	-- Get all enabled products
	SELECT ProductId
	INTO #tmpProducts
	FROM DBACC.bodb02.dbo.Products p WITH (NOLOCK)
	WHERE p.Enabled = 1

	DECLARE @products TABLE (
		 ProductId TINYINT
		)

	INSERT INTO @products(ProductId)
	SELECT DISTINCT c.ProductId
	FROM #tmpProducts p
		INNER JOIN dbo.eaGroupConfiguration c WITH (NOLOCK) ON p.ProductId = c.ProductId
	WHERE (c.GroupId = @groupId OR @groupId IS NULL)
		AND c.IsShow = 1

	SELECT ProductId
	FROM @products
	WHERE ProductId IN(3,8,12) --Non-DCS products
	UNION ALL --DCS products
	SELECT DISTINCT d.ProductId
	FROM @products p
		INNER JOIN DBACC.bodb02.dbo.ProductSettingDetail d WITH(NOLOCK)
			ON p.ProductId = d.RealProductId
	WHERE p.ProductId NOT IN (1,3,8,12,16) 
		AND d.SettingType IN (4,11,13)
	ORDER BY ProductId
END
GO