/*<info serverAlias="DBCUST-CustDB,DBAGE-bodb02,DBACC-bodb02" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView"  viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CustSetting_CheckPGSoftEnable]
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
	*/
	SET NOCOUNT ON;
	DECLARE @PGEnable BIT  = 0   ,@SiteID int  ,@productID int = 22,@bitmapIsHidden	tinyint	= 1
	SELECT @SiteID = siteid FROM Site WITH(NOLOCK) WHERE site = @site
	
	IF NOT EXISTS(SELECT 1 FROM SportNonOfferedSiteCurrency WITH (NOLOCK) 
				  WHERE SiteID = @SiteID AND (Currency = 0 OR Currency = @currency) AND SportType = 232 AND BetType = 6001)
	BEGIN
		SET @PGEnable = 1 	
	END	
	-- check Product macau game	status
	SELECT @bitmapIsHidden =  (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder))
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,13) ft
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @CustID
		
	SELECT	
		CASE ft.SportType WHEN  212  THEN 22 -- Macau Game
					   WHEN  165  THEN 34 -- Card Club
					   WHEN  247  THEN 36 -- SG
					   WHEN  248  THEN 32 -- PP
					   ELSE 55 END as ProductID, -- PGSofft
			ft.SportType,
			ft.BetType			   
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,8) ft 
	WHERE ((@PGEnable = 0 AND ft.BetType <> 6001) OR @PGEnable = 1 ) AND @bitmapIsHidden = 0
	
END
GO
