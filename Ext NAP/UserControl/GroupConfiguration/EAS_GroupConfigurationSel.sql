/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupConfigurationSel]
	@ProductId	INT = NULL
	,@GroupId	INT = NULL
AS
/*  
	Created by: 20181120@Razor
	Task: Function to control group display
	DB: DBPOL.NAP_UserControl

	Revisions:  
		- 20181120@Razor:	Function to control group display [Redmine: #89929]
		- 20190426@Kan:		DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		- 20191106@Percy:	Just get enabled products [RedmineID: #118699]
		- 20200812@Sophia:  Format at openquery code [Redmine: #137767]
		- 20200922@Danny:	Add OrderNo, Type column into result set [Redmine: #141832]
		- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
		- 20230713@Lewis: Change Line Code Openquery -- due to Deploy Tool [RedmineID: #189207]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tmpProducts (ProductId TINYINT, ProductName VARCHAR(50), OrderNo INT, Type TINYINT)

	-- Get all enabled products
	INSERT INTO #tmpProducts (ProductId, ProductName, OrderNo, Type)
	SELECT ProductId, ProductName, OrderNo, [Type]
	FROM OPENQUERY (DBAGE, 'SELECT	CAST(ISNULL(gp.GroupProductId, p.ProductID) AS INT) AS ProductID, p.ProductName, ISNULL(p.OrderNo,0) AS OrderNo, CASE WHEN p.CasinoType = 1 THEN 53 WHEN p.CasinoType = 2 THEN 41 ELSE 0 END AS [Type] 
							FROM	bodb02.dbo.Products p WITH (NOLOCK) LEFT JOIN	bodb02.dbo.f_GroupProduct() gp ON p.ProductID = gp.ProductId AND gp.ProductId <> gp.GroupProductId 
							WHERE p.GroupType = 0 AND gp.ProductId IS NULL AND p.Enabled = 1'
					)

	DECLARE @products TABLE (
		ProductId INT
		,ProductName VARCHAR(50)
		,GroupId INT
		,GroupName VARCHAR(100)
		,Currency VARCHAR(300)
		,CurrencyCode VARCHAR(300)
		,Site VARCHAR(300)
		,IsShow BIT
		,OrderNo INT
		,[Type] TINYINT
		)

	INSERT INTO @products
	SELECT CAST(c.ProductId AS INT) AS ProductId
		,p.ProductName
		,c.GroupId
		,g.GroupName
		,g.Currency
		,g.CurrencyCode
		,g.[Site]
		,c.IsShow
		,p.OrderNo
		,p.[Type]
	FROM #tmpProducts p
		INNER JOIN dbo.eaGroupConfiguration c WITH (NOLOCK) ON p.ProductId = c.ProductId
		INNER JOIN dbo.eaGroup g WITH (NOLOCK) ON g.GroupID = c.GroupId
	WHERE (
			p.ProductId = @productId
			OR @productId IS NULL
			)
		AND (
			c.GroupId = @groupId
			OR @groupId IS NULL
			)

	IF (
			NOT EXISTS (
				SELECT 1
				FROM dbo.eaGroupConfiguration WITH (NOLOCK)
				WHERE ProductId = @productId
					OR @productId IS NULL
				)
			)
	BEGIN
		DECLARE @ProductName	VARCHAR(50)
		DECLARE @OrderNo		INT
		DECLARE @Type			TINYINT

		SELECT	@ProductName	= ProductName,  
				@OrderNo		= OrderNo,
				@Type			= [Type]
		FROM #tmpProducts
		WHERE ProductId = @productId
	
		INSERT INTO @products
		SELECT @productId
			,@ProductName
			,g.GroupId
			,g.GroupName
			,g.Currency
			,g.CurrencyCode
			,g.[Site]
			,0
			,@OrderNo
			,@Type
		FROM dbo.eaGroup g WITH (NOLOCK)
		WHERE GroupId = @groupId
			OR @groupId IS NULL
	END

	IF (
			NOT EXISTS (
				SELECT 1
				FROM dbo.eaGroupConfiguration WITH (NOLOCK)
				WHERE GroupId = @groupId
					OR @groupId IS NULL
				)
			)
	BEGIN
		DECLARE @GroupName VARCHAR(100)
			,@Currency VARCHAR(300)
			,@CurrencyCode VARCHAR(300)
			,@Site VARCHAR(300)

		SELECT @GroupName = GroupName
			,@Currency = Currency
			,@CurrencyCode = CurrencyCode
			,@Site = Site
		FROM dbo.eaGroup WITH (NOLOCK)
		WHERE GroupId = @groupId

		INSERT INTO @products
		SELECT productId
			,ProductName
			,@groupId
			,@GroupName
			,@Currency
			,@CurrencyCode
			,@Site
			,0
			,OrderNo
			,[Type]
		FROM #tmpProducts
		WHERE (ProductId = @productId OR @productId IS NULL)
	END

	SELECT *
	FROM @products
	ORDER BY GroupName

	DROP TABLE #tmpProducts
END
GO