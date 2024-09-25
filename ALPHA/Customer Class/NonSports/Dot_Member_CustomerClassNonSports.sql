/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,Dot_Member,svc_tig" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CustomerClassNonSports] 
	@SiteID INT, 
	@CustomerClass SMALLINT,
	@SportType SMALLINT,
	@IsTest BIT = 0,
	@IsDeposit BIT
AS
/*
	Created: Winfred
	Date: 20240923
	Task : [NAP CM] Integrate for Non-Sports [#199852]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240923@Winfred: [NAP CM] CCMgt - Integrate for Non-Sports [RedmineID: #199852] 

	Param's Explanation:
	Example: Dot_Member_CustomerClassNonSports @SiteID= 20, @IsTest= 1, @CustomerClass= 901, @SportType= 1, @IsDeposit= 1
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ModeTest BIT, @SiteIDNew INT, 
			@n INT = 2000000, @ProductID TINYINT,
			@AllProducts VARCHAR(500) = '256' -- All Product

	SELECT  @SiteIDNew = CASE WHEN @IsDeposit = 0 THEN -1 ELSE -2 END

	SET @ProductID = (SELECT TOP 1 (CASE WHEN ProductID = 18 THEN ProductID ELSE RealProductId END)
	FROM SportBettypeSettingMatrix WITH(NOLOCK)
	WHERE SportType = @SportType AND (RealProductId IN (3,8,28,40,63) OR ProductID = 18))

	IF @ProductID IS NULL
	BEGIN
		SELECT @CustomerClass AS ReturnedCustomerClass,
			@siteID AS ReturnedSiteID, 
			@SportType AS ReturnedSportType, 
			NUll AS ReturnedMaxBet
		RETURN
	END

	SET @AllProducts = CAST(@ProductID AS VARCHAR(10)) + ',' + @AllProducts

	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClassNonSports]()

	 IF @ModeTest = 1 
	 BEGIN
		SELECT
			@CustomerClass AS ReturnedCustomerClass,
			@siteID AS ReturnedSiteID, 
			@SportType AS ReturnedSportType, 
			Min(cc.MaxBet) AS ReturnedMaxBet
		FROM 
			[dbo].[CustomerClassNonSportsDetail_UAT] cm WITH(NOLOCK)
			CROSS APPLY (SELECT TOP (@n) cn.MaxBet
						 FROM CustomerClassNonSports_UAT cn WITH(NOLOCK) 
							CROSS APPLY ( SELECT ProductID, Offer 
										  FROM dbo.f_GetValueBitmap_multiple(cn.Products, @AllProducts) ) p
						 WHERE cm.PolicyID = cn.PolicyID AND cn.IsTest = @IsTest AND cn.Enable = 1 
							   AND cn.isDeleted = 0 AND P.Offer = 1)cc
								
		WHERE cm.SiteID IN ( @SiteIDNew, @SiteID)
			AND cm.CustomerClass  = @CustomerClass
			AND cm.isDeleted = 0
		 OPTION(OPTIMIZE FOR (@n =1), FORCE ORDER)
	 END
	 ELSE
	 BEGIN		
		SELECT
			@CustomerClass AS ReturnedCustomerClass,
			@siteID AS ReturnedSiteID, 
			@SportType AS ReturnedSportType, 
			Min(cc.MaxBet) AS ReturnedMaxBet
		FROM 
			[dbo].[CustomerClassNonSportsDetail] cm WITH(NOLOCK)
			CROSS APPLY (SELECT TOP (@n) cn.MaxBet
						 FROM CustomerClassNonSports cn WITH(NOLOCK) 
							CROSS APPLY ( SELECT ProductID, Offer 
										  FROM dbo.f_GetValueBitmap_multiple(cn.Products, @AllProducts) ) p
						 WHERE cm.PolicyID = cn.PolicyID AND cn.IsTest = @IsTest AND cn.Enable = 1 
							   AND cn.isDeleted = 0 AND P.Offer = 1)cc
								
		WHERE cm.SiteID IN ( @SiteIDNew, @SiteID)
			AND cm.CustomerClass = @CustomerClass
			AND cm.isDeleted = 0
		 OPTION(OPTIMIZE FOR (@n =1), FORCE ORDER)
	END
END