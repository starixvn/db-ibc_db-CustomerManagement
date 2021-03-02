/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
GO
CREATE PROCEDURE [dbo].[Age_GetOfferedProductByCust]
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

	Param's Explanation:
		- @SettingStatus: 0: Pro, 1: UAT

	Example: EXEC Age_GetOfferedProductByCust @CustID = 1176086
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @SyncCasino BIT, @HideKeno BIT, @HideGoldDeluxe BIT	,@Currency INT,@Site varchar(10)

	--Product Status
	SELECT	@SyncCasino = ci.SyncCasino,
			@HideKeno = ci.HideKeno,
			@HideGoldDeluxe = ci.HideGoldDeluxe,
			@Site = site,
			@Currency = c.currency
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid
	
	DECLARE @PGDisable BIT  = 1   ,@SiteID int 
	SELECT @SiteID = siteid FROM Site WITH(NOLOCK) WHERE site = @site
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 232 AND BetType = 6001)
	BEGIN
		SET @PGDisable = 0 
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
		SELECT 12, @HideGoldDeluxe
		UNION ALL
		SELECT 6, CASE WHEN @SyncCasino = 1 THEN 0 ELSE 1 END
		UNION ALL
		SELECT 1, 0 --Sportbook always offer for all customer
		UNION ALL
		SELECT 3, 0 --NumberGame always offer for all customer
		UNION ALL
		SELECT 34, isHidden FROM #OfferProduct WHERE ProductID = 22	-- Card Club
		UNION ALL
		SELECT 36, isHidden FROM #OfferProduct WHERE ProductID = 22	-- SG
		UNION ALL
		SELECT 32, isHidden FROM #OfferProduct WHERE ProductID = 22	-- PP
		UNION ALL
		SELECT 55, CASE WHEN  isHidden = 0 THEN  @PGDisable ELSE isHidden END 
		FROM #OfferProduct WHERE ProductID = 22 -- PGSofft
		UNION ALL
		SELECT 56, isHidden FROM #OfferProduct WHERE ProductID = 22	-- PP
		UNION ALL
		SELECT 60, isHidden FROM #OfferProduct WHERE ProductID = 22	-- Max Game
		UNION ALL
		SELECT 61, isHidden FROM #OfferProduct WHERE ProductID = 22	-- Habanero
		) r
		INNER JOIN dbo.Products p WITH (NOLOCK) ON p.ProductID = r.ProductID
	WHERE p.GroupType = 0
	ORDER BY r.ProductID
END
GO