/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView"  viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustSetting_CheckMacauEnable]
	-- Add the parameters for the stored procedure here
	@site   varchar(10),
	@currency tinyint  ,
	@custid int,
	@SettingStatus TINYINT = 0
AS
BEGIN
	/*
		Task : Check PG Soft on site
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20200806@Winfred: Check PG Soft on site [Redmine: #137763]
			- 20200914@Winfred: Check Joker on site [Redmine: #131603]
			- 20201009@Tina: Add new parameter @SettingStatus [Redmine: #143077]
			- 20201229@Eden: MaxGame [Redmine: #147232]
			- 20210302@Winfred: add Habanero  [RedmineID: #145459]
			- 20210324@Winfred: Check Creative Gaming on site [Redmine: #146016]
			- 20210506@Winfred: Check AdvantPlay on site [Redmine: #154258]
			- 20210514@Winfred: Check AdvantPlay Mini on site [Redmine: #155133]
			- 20220803@Eden:  Implement the dependency between Macau Games Product Status and Jackpot Status [Redmine: #171715]

		Param's Explanation: 
			- @SettingStatus: 0: Pro, 1: UAT 

	*/
	SET NOCOUNT ON;
	DECLARE @SiteID int  ,@productID int = 22,@bitmapIsHidden	tinyint	= 1
	SELECT @SiteID = siteid FROM Site WITH(NOLOCK) WHERE site = @site
	
	-- check Product macau game	status
	SELECT @bitmapIsHidden =  (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder))
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,21,@SettingStatus) ft
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @CustID
	-- all sport bettype on macau 	
	CREATE TABLE #SportBettypeFilter(sporttype SMALLINT,bettype SMALLINT)
	
	INSERT INTO #SportBettypeFilter(sporttype,bettype)
	SELECT
			ft.SportType,
			ft.BetType						   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,8,@SettingStatus) ft 
	WHERE @bitmapIsHidden = 0
	-- delete non offer site
	DELETE  a
	FROM #SportBettypeFilter a
	INNER JOIN SportNonOfferedSiteCurrency b WITH (NOLOCK) on a.SportType = b.SportType AND a.Bettype = b.BetType
	WHERE b.SiteID = @SiteID  AND (b.Currency = 0 OR b.Currency = @currency)
	
	-- delete non offer currrency
	DELETE  a
	FROM #SportBettypeFilter a
	INNER JOIN	SportNonOfferedSiteCurrency b WITH (NOLOCK) on a.SportType = b.SportType AND a.Bettype = b.BetType
	WHERE b.Currency = @currency  AND (b.SiteID = 0 OR b.SiteID = @SiteID)
	
	SELECT   CASE ft.SportType WHEN  212  THEN 22 -- Macau Game
					   WHEN  165  THEN 34 -- Card Club
					   WHEN  247  THEN 36 -- SG
					   WHEN  248  THEN 32 -- PP
					   WHEN  234  THEN 56 -- Joker
					   WHEN  237  THEN 60 -- MaxGame
					   WHEN  238  THEN 61 -- Habanero 
					   WHEN  167  THEN 62 -- Creative Gaming
					   WHEN  172  THEN 67 -- AdvantPlay
					   WHEN  174  THEN 68 -- AdvantPlay Mini
					   ELSE 55 END as ProductID, -- PGSofft
			ft.SportType,
			ft.BetType	
	FROM #SportBettypeFilter ft
	
	DROP TABLE #SportBettypeFilter			
	
END
GO
