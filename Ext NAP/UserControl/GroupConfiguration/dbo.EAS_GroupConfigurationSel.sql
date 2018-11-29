/*<info serverAlias="DBEAS-bodb_EAS" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
USE bodb_EAS
GO

ALTER PROCEDURE [dbo].[EAS_GroupConfigurationSel] @productId INT = NULL
	,@groupId INT = NULL
AS
/*  
Created by: 20181120@Razor
TASK : Function to control group display
DB: DBEAS/bodb_EAS
Revisions:  
	- 20181120@Razor: Function to control group display [Redmine: #89929]
*/
SET NOCOUNT ON

DECLARE @products TABLE (
	ProductId INT
	,ProductName VARCHAR(50)
	,GroupId INT
	,GroupName VARCHAR(100)
	,Currency VARCHAR(300)
	,CurrencyCode VARCHAR(300)
	,Site VARCHAR(300)
	,IsShow BIT
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
FROM bodb02.dbo.Products p WITH (NOLOCK)
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
	DECLARE @ProductName VARCHAR(50)
	SELECT @ProductName = ProductName 
	FROM bodb02.dbo.Products WITH (NOLOCK)
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
	FROM bodb02.dbo.Products p WITH (NOLOCK)
	WHERE ProductId = @productId 
		OR @productId IS NULL
END

SELECT *
FROM @products
ORDER BY GroupName
GO