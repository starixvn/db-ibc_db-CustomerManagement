/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView"  viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustSetting_CheckStakeMacau]
	-- Add the parameters for the stored procedure here
	@site   varchar(10),
	@currency tinyint  ,
	@custid int
AS
BEGIN
	/*
		Task : Check PG Soft on site
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20200806@Winfred: Check PG Soft on site [Redmine: #137763]
			- 20200914@Winfred: Check Joker on site [Redmine: #131603]
	*/
	SET NOCOUNT ON;
	DECLARE @SiteID int  ,@productID int = 22,@bitmapIsHidden	tinyint	= 1
	SELECT @SiteID = siteid FROM Site WITH(NOLOCK) WHERE site = @site
	
	-- check Product macau game	status
	SELECT @bitmapIsHidden =  (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder))
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,13) ft
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @CustID
	-- all sport bettype on macau 	
	SELECT
			ft.SportType,
			ft.BetType
	INTO #SportBettypeFilter					   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,8) ft 
	WHERE @bitmapIsHidden = 0
	-- delete non offer site
	DELETE  a
	FROM #SportBettypeFilter a
	INNER JOIN	SportNonOfferedSiteCurrency b on a.SportType = b.SportType AND a.Bettype = b.BetType
	WHERE b.SiteID = @SiteID  AND (b.Currency = 0 OR b.Currency = @currency)
	
	-- delete non offer currrency
	DELETE  a
	FROM #SportBettypeFilter a
	INNER JOIN	SportNonOfferedSiteCurrency b on a.SportType = b.SportType AND a.Bettype = b.BetType
	WHERE b.Currency = @currency  AND (b.SiteID = 0 OR b.SiteID = @SiteID)
	
	SELECT   CASE ft.SportType WHEN  212  THEN 22 -- Macau Game
					   WHEN  165  THEN 34 -- Card Club
					   WHEN  247  THEN 36 -- SG
					   WHEN  248  THEN 32 -- PP
					   WHEN  234  THEN 56 -- Joker
					   ELSE 55 END as ProductID, -- PGSofft
			ft.SportType,
			ft.BetType	
	FROM #SportBettypeFilter ft
	
	DROP TABLE #SportBettypeFilter			
	
END
GO
