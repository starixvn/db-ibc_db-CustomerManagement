/*<info serverAlias="DBAGE-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustSetting_CheckMacauEnable]
	-- Add the parameters for the stored procedure here
	@site   varchar(10),
	@currency tinyint  ,
	@custid int,
	@SettingStatus TINYINT = 0
AS
/*
	Task : Check PG Soft on site
	DB: DBAGE-bodb02
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
		- 20220919@Tacy: Check Microgaming on site [Redmine: #175853]
		- 20230118@Helios: add JiliGame [RedmineId: #182869]
		- 20231121@Tacy: ExtNAP/Alpha - Return Offered product lists by site/currency [RedmineId: #196141]

	Param's Explanation: 
		- @SettingStatus: 0: Pro, 1: UAT 

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @SiteID int, @productID int = 18, @IsHidden	tinyint	= 1

	SELECT @SiteID = siteid FROM Site WITH(NOLOCK) WHERE site = @site
	
	-- check Product macau game	status
	SELECT @IsHidden =  (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder))
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@productID,21,@SettingStatus) ft
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @CustID
	
	SELECT p.ProductID, p.ProductName
	FROM dbo.Products p WITH (NOLOCK)
	OUTER APPLY (SELECT TOP 1 s.RealProductID, s.SportType, s.BetType
				 FROM SportNonOfferedSiteCurrency s WITH (NOLOCK)
				 WHERE s.RealProductID=p.ProductID) s
	WHERE  @IsHidden=0
		AND p.GroupType = 0 AND p.Enabled=1 
		AND p.CasinoType=1 AND p.ProductID<>6 -- Saba Casino
		AND dbo.f_CustSetting_GetSportOfferStatusBySiteCurrency(@SiteID,@Currency,s.Sporttype,s.Bettype,@SettingStatus)=0
		AND p.Environment <= @SettingStatus
	ORDER BY p.ProductID DESC
END
GO