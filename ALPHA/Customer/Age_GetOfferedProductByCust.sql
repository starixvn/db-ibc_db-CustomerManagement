/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_GetOfferedProductByCust]
	@custid INT
	, @SettingStatus TINYINT = 0
AS
/*
	Created: 20180906@Elodie
	DB: DBAGE/bodb02
	Task: Get all product which offered for customer

	Revisions:
		- 20180906@Elodie: Get all product which offered for customer [Redmine: #95940]
		- 20190926@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20200806@Elodie: Get real productid [Redmine: #139017]
		- 20200821@Winfred: Get all productid in MaCau Game [Redmine: #167768]
		- 20200911@Winfred: add product joker [Redmine: #131603]
		- 20201009@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20210104@Eden: add product Max Game [Redmine: #147232]
		- 20210302@Winfred: add Habanero  [RedmineID: #145459]
		- 20210324@Winfred: Get product Creative Gaming in MaCau Game [Redmine: #146016]
		- 20210506@Winfred: Get product AdvantPlay in MaCau Game [Redmine: #154258]
		- 20210514@Winfred: Get product AdvantPlay Mini in MaCau Game [Redmine: #155133]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220803@Eden:  Implement the dependency between Macau Games Product Status and Jackpot Status [Redmine: #171715]
		- 20220922@Tacy: Add SEAL Entertainment [RedmineID: #176209]
		- 20220922@Tacy: Add Microgaming [RedmineID: #175853]
		- 20221102@Winfred: Get PP, SG, Arcadia Gaming in Macau Games Product Status [RedmineID: #180032] 

	Param's Explanation:
		- @SettingStatus: 0: Pro, 1: UAT

	Example: EXEC Age_GetOfferedProductByCust @CustID = 1176086
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @HideKeno BIT, @Currency INT,@Site varchar(10)

	--Product Status
	SELECT	@HideKeno = ci.HideKeno,
			@Site = site,
			@Currency = c.currency
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid
	
	DECLARE @PGDisable BIT  = 1   ,@SiteID INT, @JokerDisable BIT  = 1 ,@MaxGameDisable BIT  = 1,@HabaneroDisable BIT  = 1 ,@CGDisable BIT  = 1 ,@AdvantPlayDisable BIT  = 1 ,@AdvantPlayMiniDisable BIT  = 1,
			@SEALDisable BIT  = 1,@MicrogamingDisable BIT  = 1 ,@PPDisable BIT  = 1,@SGDisable BIT  = 1,@ArcadiaGamingDisable BIT 
	SELECT @SiteID = siteid FROM Site WITH(NOLOCK) WHERE site = @site
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 232 AND BetType = 6001)
	BEGIN
		SET @PGDisable = 0 
	END
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 234 AND BetType = 6401 )
	BEGIN
		SET @JokerDisable = 0 
	END
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 237 AND BetType = 5401 )
	BEGIN
		SET @MaxGameDisable = 0 
	END
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 238 AND BetType = 7001 )
	BEGIN
		SET @HabaneroDisable = 0 
	END
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 167 AND BetType = 7301 )
	BEGIN
		SET @CGDisable = 0 
	END
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 172 AND BetType = 7701 )
	BEGIN
		SET @AdvantPlayDisable = 0 
	END
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 174 AND BetType = 7801 )
	BEGIN
		SET @AdvantPlayMiniDisable = 0 
	END
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 156 AND BetType = 8900 )
	BEGIN
		SET @SEALDisable = 0 
	END
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 155 AND BetType = 8400 )
	BEGIN
		SET @MicrogamingDisable = 0 
	END

	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 248 AND BetType = 4101 )
	BEGIN
		SET @PPDisable = 0 
	END

	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 247 AND BetType = 4301 )
	BEGIN
		SET @SGDisable = 0 
	END

	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 165 AND BetType = 1901 )
	BEGIN
		SET @ArcadiaGamingDisable = 0 
	END

	DECLARE @SuperID INT, @IsIMBC BIT = 0   
   
	SELECT @SuperID = ci.srecommend
	FROM dbo.custInfo ci WITH(NOLOCK)    
	WHERE ci.custid = @CustID   
   
	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @SuperID AND [Site] = 'IMBC')  
		SET @IsIMBC = 1  
    
	CREATE TABLE #SportBettypeFilter (ProductID TINYINT, SportType SMALLINT,Bettype SMALLINT,IsLive BIT, SettingType TINYINT)

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,4,@SettingStatus)	

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,11,@SettingStatus)	

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,13,@SettingStatus)

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,21,@SettingStatus)
	
	SELECT DISTINCT ft.ProductID, 
			CAST(CASE WHEN @IsIMBC = 0 AND ft.ProductID = 20 THEN 1 
				ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, psp.bitmapOrder)) END AS BIT) AS isHidden
	INTO #OfferProduct			
	FROM #SportBettypeFilter ft 
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON psp.Bettype = ft.BetType AND psp.Sporttype = ft.SportType                 
		CROSS JOIN dbo.CustProductStatus stt WITH (NOLOCK)
	WHERE stt.CustID = @CustID

	SELECT p.ProductID, r.isHidden, p.EndOfSupportDate
	FROM (
		SELECT ProductID, isHidden FROM #OfferProduct
		UNION ALL
		SELECT 8, @HideKeno
		UNION ALL
		SELECT 1, 0 --Sportbook always offer for all customer
		UNION ALL
		SELECT 3, 0 --NumberGame always offer for all customer
		UNION ALL
		SELECT 34, CASE WHEN  isHidden = 0 THEN  @ArcadiaGamingDisable ELSE isHidden END FROM #OfferProduct WHERE ProductID = 22	-- Arcadia Gaming
		UNION ALL
		SELECT 36, CASE WHEN  isHidden = 0 THEN  @SGDisable ELSE isHidden END FROM #OfferProduct WHERE ProductID = 22 -- SG
		UNION ALL
		SELECT 32, CASE WHEN  isHidden = 0 THEN  @PPDisable ELSE isHidden END FROM #OfferProduct WHERE ProductID = 22	-- PP
		UNION ALL
		SELECT 55, CASE WHEN  isHidden = 0 THEN  @PGDisable ELSE isHidden END 
		FROM #OfferProduct WHERE ProductID = 22 -- PGSofft
		UNION ALL
		SELECT 56, CASE WHEN  isHidden = 0 THEN  @JokerDisable ELSE isHidden END FROM #OfferProduct WHERE ProductID = 22	-- Joker
		UNION ALL
		SELECT 60, CASE WHEN  isHidden = 0 THEN  @MaxGameDisable ELSE isHidden END FROM #OfferProduct WHERE ProductID = 22	-- Max Game
		UNION ALL
		SELECT 61, CASE WHEN  isHidden = 0 THEN  @HabaneroDisable ELSE isHidden END FROM #OfferProduct WHERE ProductID = 22	-- Habanero
		UNION ALL
		SELECT 62, CASE WHEN  isHidden = 0 THEN  @CGDisable ELSE isHidden END  FROM #OfferProduct WHERE ProductID = 22	-- Creative Gaming
		UNION ALL
		SELECT 67, CASE WHEN  isHidden = 0 THEN  @AdvantPlayDisable ELSE isHidden END  FROM #OfferProduct WHERE ProductID = 22	-- AdvantPlay	
		UNION ALL
		SELECT 68, CASE WHEN  isHidden = 0 THEN  @AdvantPlayMiniDisable ELSE isHidden END  FROM #OfferProduct WHERE ProductID = 22	-- AdvantPlay Mini	
		UNION ALL
		SELECT 72, CASE WHEN  isHidden = 0 THEN  @SEALDisable ELSE isHidden END  FROM #OfferProduct WHERE ProductID = 22	-- SEAL	
		UNION ALL
		SELECT 73, CASE WHEN  isHidden = 0 THEN  @MicrogamingDisable ELSE isHidden END  FROM #OfferProduct WHERE ProductID = 22	-- Microgaming	
		) r
		INNER JOIN dbo.Products p WITH (NOLOCK) ON p.ProductID = r.ProductID
	WHERE p.GroupType = 0
	ORDER BY r.ProductID
END
GO