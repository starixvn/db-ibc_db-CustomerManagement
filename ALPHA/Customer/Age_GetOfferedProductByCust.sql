/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
GO
ALTER PROCEDURE [dbo].[Age_GetOfferedProductByCust]
	@custid INT
AS
/*
	Created: 20180906@Elodie
	DB: DBAGE/bodb02
	Task: Get all product which offered for customer

	Revisions:
		- 20180906@Elodie: Get all product which offered for customer [Redmine: #95940]
		- 20190926@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]

	Param's Explanation:
	Example: EXEC Age_GetOfferedProductByCust @CustID = 1176086
		
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @SyncCasino BIT, @HideKeno BIT, @HideGoldDeluxe BIT

	--Product Status
	SELECT	@SyncCasino = ci.SyncCasino,
			@HideKeno = ci.HideKeno,
			@HideGoldDeluxe = ci.HideGoldDeluxe
	FROM customer c WITH (NOLOCK)
	    INNER JOIN custinfo ci WITH (NOLOCK) ON c.custid = ci.custid	
    WHERE c.custid = @custid

	DECLARE @SuperID INT, @IsIMBC BIT = 0   
   
	SELECT @SuperID = ci.srecommend
	FROM dbo.custInfo ci WITH(NOLOCK)    
	WHERE ci.custid = @CustID   
   
	IF EXISTS (SELECT 1 FROM Customer WITH (NOLOCK) WHERE custid = @SuperID AND [Site] = 'IMBC')  
		SET @IsIMBC = 1  
    
	CREATE TABLE #SportBettypeFilter (ProductID TINYINT, SportType SMALLINT,Bettype SMALLINT,IsLive BIT, SettingType TINYINT)

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,4)	

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,11)	

	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT RealProductId,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,13)

	SELECT p.ProductID, r.isHidden, p.EndOfSupportDate
	FROM (
		SELECT DISTINCT ft.ProductID, 
			CAST(CASE WHEN @IsIMBC = 0 AND ft.ProductID = 20 THEN 1 
				ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, psp.bitmapOrder)) END AS BIT) AS isHidden
		FROM #SportBettypeFilter ft 
			INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON psp.Bettype = ft.BetType AND psp.Sporttype = ft.SportType                 
			CROSS JOIN dbo.CustProductStatus stt WITH (NOLOCK)
		WHERE stt.CustID = @CustID
		UNION ALL
		SELECT 8, @HideKeno
		UNION ALL
		SELECT 6, CASE WHEN @SyncCasino = 1 THEN 0 ELSE 1 END
		UNION ALL
		SELECT 1, 0 --Sportbook always offer for all customer
		UNION ALL
		SELECT 3, 0 --NumberGame always offer for all customer
		) r
		INNER JOIN dbo.Products p WITH (NOLOCK) ON p.ProductID = r.ProductID
	WHERE p.GroupType = 0
	ORDER BY r.ProductID
END
GO