/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_ProductSettingByGroup_Sel]
	@GroupId	INT = NULL, 
	@SettingStatus TINYINT = 0
AS
/*  
	Created by: 20200923@Eden
	Task: Ext NAP --> Customer --> Super List --> Edit multiple Product Status --> Product List
	DB: DBPOL.NAP_UserControl

	Revisions:  
		- 20200923@Eden: First commit [Redmine: #141832]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
		- 20220803@Eden:  Implement the dependency between Macau Games Product Status and Jackpot Status [Redmine: #171715]
		- 20221006@Winfred: Macau Game - Rename the setting page into RNG Slot and hide all bet limit setting [Redmine: #174513]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230320@Eden: Migrate Number games to DCS structure [Redmine: #179711]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tmpProducts (ProductId TINYINT)

	CREATE TABLE #ProductSettingDetail(
		[SettingType] [smallint],
		[SportType] [smallint],
		[BetType] [smallint],
		[IsLive] [bit] ,
		[ProductID] [tinyint],
		[RealProductID] [tinyint],
	PRIMARY KEY([SettingType] ASC,[SportType] ASC,[BetType] ASC,[IsLive] ASC)
	)

	IF @SettingStatus = 3
	BEGIN 
		INSERT INTO #ProductSettingDetail(SportType,BetType,SettingType,IsLive,ProductID,RealProductID)
		SELECT SportType,BetType,SettingType,IsLive,ProductID,RealProductID
		FROM DBACC.bodb02.dbo.ProductSettingDetail_UAT WITH(NOLOCK)
	END
	ELSE
	BEGIN
		INSERT INTO #ProductSettingDetail(SportType,BetType,SettingType,IsLive,ProductID,RealProductID)
		SELECT SportType,BetType,SettingType,IsLive,ProductID,RealProductID
		FROM DBACC.bodb02.dbo.ProductSettingDetail WITH(NOLOCK)
	END

	-- Get all enabled products
	INSERT INTO #tmpProducts (ProductId)
	SELECT ProductId
	FROM DBACC.bodb02.dbo.Products p WITH (NOLOCK)
	WHERE p.Enabled = 1

	DECLARE @products TABLE (
		 ProductId TINYINT
		)

	INSERT INTO @products(ProductId)
	SELECT DISTINCT CASE WHEN c.ProductId = 22 THEN 18 ELSE c.ProductId END AS ProductId
	FROM #tmpProducts p
		INNER JOIN dbo.eaGroupConfiguration c WITH (NOLOCK) ON p.ProductId = c.ProductId
	WHERE (c.GroupId = @groupId OR @groupId IS NULL)
		AND c.IsShow = 1

	SELECT DISTINCT d.ProductId
	FROM @products p
		INNER JOIN #ProductSettingDetail d WITH(NOLOCK)
			ON p.ProductId = d.RealProductId
	WHERE p.ProductId NOT IN (1,16) 
		AND d.SettingType IN (4,11,13,21)
	ORDER BY ProductId

	DROP TABLE #tmpProducts
	DROP TABLE #ProductSettingDetail
END
GO