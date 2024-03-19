/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" isFunction="0" isNested="0"></info>*/
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
		- 20230731@Eden: Simplify Live Casino Customer Setting - move from bodb02 to custdb [Redmine: #189389]
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tmpProducts (ProductId TINYINT)
	CREATE TABLE #tmpProducts_Show (ProductId TINYINT)

	CREATE TABLE #ProductSettingDetail(
		[SettingType] [smallint],
		[SportType] [smallint],
		[BetType] [smallint],
		[IsLive] [bit] ,
		[ProductID] [tinyint],
		[RealProductID] [tinyint],
		[SettingName] varchar(200),
	PRIMARY KEY([SettingType] ASC,[SportType] ASC,[BetType] ASC,[IsLive] ASC)
	)

	INSERT INTO #ProductSettingDetail(SportType,BetType,SettingType,IsLive,ProductID,RealProductID,SettingName)
	SELECT SportType,BetType,d.SettingType,IsLive,ProductID,RealProductID,t.settingName
	FROM custdb.dbo.f_CustSetting_ProductSettingDetailSel(@SettingStatus) d
		INNER JOIN custdb.dbo.ProductSettingType t WITH(NOLOCK) ON d.SettingType = t.SettingType
	WHERE t.SettingName IN ('Product Status','Bet Setting','Stake Level')

	-- Get all enabled products
	INSERT INTO #tmpProducts (ProductId)
	SELECT ProductId
	FROM DBPRO.bodb02.dbo.Products p WITH (NOLOCK)
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

	INSERT INTO #tmpProducts_Show(ProductId)
	SELECT DISTINCT d.ProductId
	FROM @products p
		INNER JOIN #ProductSettingDetail d WITH(NOLOCK)
			ON p.ProductId = d.RealProductId
	WHERE p.ProductId NOT IN (1,16) 
		AND d.SettingName = 'Product Status'
		AND d.ProductID NOT IN (41)

	INSERT INTO #tmpProducts_Show(ProductId)
	SELECT TOP 1 d.ProductId
	FROM #ProductSettingDetail d WITH(NOLOCK)
		INNER JOIN CustDB.dbo.SportBettypeSettingMatrix mt WITH(NOLOCK) ON mt.SportType = d.SportType AND mt.BetType = d.BetType AND mt.isLicensee = 0 AND mt.Site = 'ALL'
		INNER JOIN @products p  ON p.ProductId = mt.RealProductId
	WHERE d.ProductId IN (41) 
		AND d.SettingName IN('Bet Setting','Stake Level')

	SELECT ProductId 
	FROM #tmpProducts_Show 
	ORDER BY ProductId
	
	DROP TABLE #tmpProducts
	DROP TABLE #ProductSettingDetail
	DROP TABLE #tmpProducts_Show
END
GO