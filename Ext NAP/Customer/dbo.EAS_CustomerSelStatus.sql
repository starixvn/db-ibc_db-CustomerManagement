/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[EAS_CustomerSelStatus]
	@CustID INT
AS
/*
	Created: 20180228@Johnson
	Task : Get status of customer to get product list for multiple update status on EXT
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20180228@Johnson: new direction for status [Redmineid: #87328]
*/	
BEGIN
	SET NOCOUNT ON
		
	CREATE TABLE #SportBettypeFilter (ProductID TINYINT, SportType SMALLINT,Bettype SMALLINT,IsLive BIT, SettingType TINYINT)
	DECLARE @ProductID TINYINT = NULL--all product
			
	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT ProductID,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,4)
	
	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT ProductID,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,11)
	
	INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
	SELECT ProductID,SportType,Bettype,IsLive, SettingType   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,13)
	
	--dont filter Cricket
	DELETE #SportBettypeFilter 
	WHERE ProductID = 20
	
	SELECT  ISNULL(HideColossusBet,1) AS HideColossusBet,
		ISNULL(HideGoldDeluxe,1) AS HideGoldDeluxe,
		ISNULL(SyncCasino,0) AS SyncCasino,
		ISNULL(HideKeno,1) AS HideKeno
	FROM dbo.CustInfo WITH(NOLOCK)
	WHERE custid = @custid
	
	SELECT CAST(CASE WHEN stt.CustID IS NULL THEN 0 ELSE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapHasSynced, PSP.bitmapOrder)) END AS BIT) as IsSync,
		CAST(CASE WHEN stt.CustID IS NULL THEN 1 ELSE 
										(CASE WHEN (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0 THEN 0 ELSE 1 END) 
												END AS BIT) AS isHidden    
	FROM dbo.ProductSettingDetail pdt WITH (NOLOCK)  
			INNER JOIN #SportBettypeFilter ft ON pdt.SportType = ft.sporttype AND pdt.BetType = ft.bettype AND pdt.IsLive = ft.islive AND pdt.SettingType = ft.SettingType
			INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = pdt.BetType AND PSP.Sporttype = PDT.SportType                 
			LEFT JOIN dbo.CustProductStatus stt WITH (NOLOCK) ON stt.CustID = @CustID  
	WHERE pdt.SettingType IN (4,11,13)
	
END
GO