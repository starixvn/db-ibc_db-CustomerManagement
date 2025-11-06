/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,svc_tig" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CustomerClassSpreadSel] 
	@SiteID INT, 
	@Currency INT,
	@CustomerClass SMALLINT,
	@Platform TINYINT = 0,
	@IsTest BIT = 0,
    @IsLicensee bit
AS
/*
	Created: Winfred
	Date: 20240215
	Task : [NAP CM] Customer Class - SP Integrate [#200996]
	DB: DBCUST/CustDB

	Revisions:
		- 20240215@Winfred: [NAP CM] Customer Class - SP Integrate Spread setting [RedmineID: #200996] 
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]
		- 20251106@Winfred: [NAP CM] - Spread Management - Enhance Dot_Member_CustomerClassSpreadSel SP [Redmine: #243250]

	Param's Explanation:
	Example: Dot_Member_CustomerClassSpreadSel @SiteID = 25, @Currency = 1, @CustomerClass =13 , @Platform =3 , @IsTest=0, @IsLicensee = 0
	
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @ModeTest BIT, @NewSiteID INT, @n INT = 2000000
		
	IF 	@IsLicensee = 0
	BEGIN
		SELECT @NewSiteID = -1 --'AllCredit'
	END
	ELSE
	BEGIN
		SELECT @NewSiteID = -2 --'AllDeposit'
	END
	
	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClassSpread]()

	 IF @ModeTest = 1 
	 BEGIN
		SELECT 
			@CustomerClass AS ReturnedCustomerClass,
			@SiteID AS ReturnedSite,
			@Currency AS ReturnedCurrency,
			@Platform AS ReturnedPlatform,
			SportType AS ReturnedSportType,
			SumSpread AS ReturnedSpread
		FROM (
			SELECT
				cp.SportType,
				MAX(cs.Spread) AS SumSpread
			FROM CustomerClassSpreadDetail_UAT cp WITH(NOLOCK)
				INNER JOIN CustomerClassSpreadClass_UAT cm WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID
				INNER JOIN CustomerClassSpread_UAT cs WITH(NOLOCK) ON cm.PolicyID = cs.PolicyID 
			WHERE cm.CustomerClass = @CustomerClass 
				AND cs.IsTest = @IsTest 
				AND cs.Enable = 1 
				AND cs.Type = 1
				AND	cp.SiteID IN (0, @NewSiteID, @SiteID)
				AND cp.Currency IN (0, @Currency)
				AND cp.Platform IN (0, @Platform)
			GROUP BY cp.SportType) KQ
	 END
	 ELSE
	 BEGIN
		SELECT 
			@CustomerClass AS ReturnedCustomerClass,
			@SiteID AS ReturnedSite,
			@Currency AS ReturnedCurrency,
			@Platform AS ReturnedPlatform,
			SportType AS ReturnedSportType,
			SumSpread AS ReturnedSpread
		FROM (
			SELECT
				cp.SportType,
				MAX(cs.Spread) AS SumSpread
			FROM CustomerClassSpreadDetail cp WITH(NOLOCK)
				INNER JOIN CustomerClassSpreadClass cm WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID
				INNER JOIN CustomerClassSpread cs WITH(NOLOCK) ON cm.PolicyID = cs.PolicyID 
			WHERE cm.CustomerClass = @CustomerClass 
				AND cs.IsTest = @IsTest 
				AND cs.Enable = 1 
				AND cs.Type = 1
				AND	cp.SiteID IN (0, @NewSiteID, @SiteID)
				AND cp.Currency IN (0, @Currency)
				AND cp.Platform IN (0, @Platform)
			GROUP BY cp.SportType) KQ
	END 
END