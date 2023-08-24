/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupConfigurationUpd]
	@userId INT,
	@data NVARCHAR(MAX),
	@errCode INT = 0 OUTPUT,
	@errMsg NVARCHAR(200) = '' OUTPUT
AS
/*  
Created by: 20181120@Razor
TASK : Function to control group display
DB: DBPOL/NAP_UserControl
Revisions:  
	- 20181120@Razor: Function to control group display [Redmine: #89929]
	- 20190426@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
	- 2001020@Winfred: Fix miss product when add new group and add new product apply all group [Redmine: #140026]
	- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
	- 20230713@Lewis: Change Line Code Openquery -- due to Deploy Tool [RedmineID: #189207]

Param's Explanation:
	- @data:		
		<ROOT>
				<Row 
						ProductId="1" 
						GroupId="1"
						IsShow="1"
				></Row>
		</ROOT>		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
		,@endRun DATETIME
		,@duration INT
		,@productId INT
		,@groupId INT
		,@isShow BIT
		,@isNew BIT
		,@iDoc INT
		,@productName VARCHAR(50)
		,@groupName VARCHAR(100)
		,@logData NVARCHAR(MAX)
	DECLARE @tempTbl TABLE (
		ProductId INT
		,GroupId INT
		,IsShow BIT
		)
	DECLARE @tempUpdatedTbl TABLE (
		ProductId TINYINT
		,ProductName VARCHAR(50)
		,GroupId INT
		,GroupName VARCHAR(100)
		,IsShow BIT
		,IsNew BIT
		)

	CREATE TABLE #tmpProducts (ProductId TINYINT,ProductName VARCHAR(50))

	SELECT @startRun = GETDATE()

	-- Get all enabled products
	INSERT INTO #tmpProducts (ProductId, ProductName)
	SELECT ProductId, ProductName
	FROM OPENQUERY (DBAGE, 'SELECT CAST(ISNULL(gp.GroupProductId, p.ProductID) AS INT) AS ProductID,p.ProductName
							FROM bodb02.dbo.Products p WITH (NOLOCK) LEFT JOIN bodb02.dbo.f_GroupProduct() gp ON p.ProductID = gp.ProductId AND gp.ProductId <> gp.GroupProductId
							WHERE p.GroupType = 0 AND gp.ProductId IS NULL AND p.Enabled = 1')
	
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @data
		
		INSERT @tempTbl (ProductId, GroupId, IsShow)
		SELECT ProductId, GroupId, IsShow
		FROM OPENXML(@iDoc, '/ROOT/Row', 1) WITH (ProductId INT, GroupId INT, IsShow BIT)
		
	END TRY
	BEGIN CATCH
		RETURN
	END CATCH
	
	UPDATE c
	SET c.IsShow = t.IsShow
	OUTPUT INSERTED.ProductId, INSERTED.GroupId, INSERTED.IsShow, 0
	INTO @tempUpdatedTbl(ProductId, GroupId, IsShow, IsNew)
		FROM dbo.eaGroupConfiguration c WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @tempTbl t ON t.ProductId = c.ProductId
			AND t.GroupId = c.GroupId
		WHERE c.IsShow <> t.IsShow

	INSERT INTO dbo.eaGroupConfiguration
	OUTPUT INSERTED.ProductId, INSERTED.GroupId, INSERTED.IsShow, 1
	INTO @tempUpdatedTbl(ProductId, GroupId, IsShow, IsNew)
		SELECT ProductId, GroupId, IsShow
		FROM @tempTbl t
		WHERE NOT EXISTS ( SELECT 1 FROM dbo.eaGroupConfiguration WITH(NOLOCK) WHERE ProductId = t.ProductId AND GroupId = t.GroupId)
	
	INSERT INTO dbo.eaGroupConfiguration
	OUTPUT INSERTED.ProductId, INSERTED.GroupId, INSERTED.IsShow, 1
	INTO @tempUpdatedTbl(ProductId, GroupId, IsShow, IsNew)
	SELECT  a.ProductId, b.GroupID,0 as IsShow
	FROM #tmpProducts a
	LEFT JOIN dbo.eaGroup b WITH(NOLOCK) ON EXISTS ( SELECT 1 FROM dbo.eaGroupConfiguration WITH(NOLOCK) WHERE GroupId = b.GroupId)
	WHERE NOT EXISTS ( SELECT 1 FROM dbo.eaGroupConfiguration WITH(NOLOCK) WHERE ProductId = a.ProductId AND GroupId = b.GroupId)
	
	UPDATE t
	SET t.ProductName = p.ProductName
	FROM @tempUpdatedTbl t
	INNER JOIN DBPRO.bodb02.dbo.Products p WITH (NOLOCK) ON p.ProductID = t.ProductId
	
	UPDATE t
	SET t.GroupName = g.GroupName
	FROM @tempUpdatedTbl t
	INNER JOIN dbo.eaGroup g WITH(NOLOCK) ON g.GroupId = t.GroupId
		
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	WHILE (
			EXISTS (
				SELECT 1
				FROM @tempUpdatedTbl
				)
			)
	BEGIN
		SELECT TOP 1 @productId = t.ProductId
			,@groupId = t.GroupId
			,@isShow = t.IsShow
			,@groupName = t.GroupName
			,@productName = t.ProductName
			,@isNew = t.IsNew
		FROM @tempUpdatedTbl t		

		SELECT @logData = '<EAS_GroupConfigurationUpd>'+
								'<ProductId>' + CAST(@productId AS VARCHAR(10)) + '</ProductId>' +
								'<ProductName>' + @productName + '</ProductName>' +
								'<GroupId>' + CAST(@groupId AS VARCHAR(10)) + '</GroupId>' +
								'<GroupName>' + @groupName + '</GroupName>' +
								'<IsShow>' +
									' <Old>' + CASE @IsNew WHEN 1 THEN SPACE(1) ELSE CAST(~ @isShow AS VARCHAR(1)) END + '</Old>' +
									' <New>' + CAST(@isShow AS VARCHAR(1)) + '</New>' +
								'</IsShow>' +
							'</EAS_GroupConfigurationUpd>'

		
		EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper] @custID = @userId
			,@TrackingValue = @LogData
			,@userid = @UserID
			,@TypeID = 0
			,@actionid = 20131
			,@duration = @duration

		DELETE
		FROM @tempUpdatedTbl
		WHERE ProductId = @productId
			AND GroupId = @groupId
	END

	DROP TABLE #tmpProducts
END
