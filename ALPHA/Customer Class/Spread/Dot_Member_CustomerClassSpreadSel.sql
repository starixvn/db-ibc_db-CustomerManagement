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

	Param's Explanation:
	Example: Dot_Member_CustomerClassSpreadSel @SiteID = 25, @Currency = 1, @CustomerClass =13 , @Platform =3 , @IsTest=0, @IsLicensee = 0
	
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @ModeTest BIT, @NewSiteID INT
		
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
				MAX(cc.Spread) AS SumSpread
			FROM CustomerClassSpreadDetail_UAT cp WITH(NOLOCK)
				CROSS APPLY (SELECT TOP 1 
								cs.Spread
							 FROM CustomerClassSpreadClass_UAT cm WITH(NOLOCK)
								INNER JOIN CustomerClassSpread_UAT cs WITH(NOLOCK) ON cm.PolicyID = cs.PolicyID 
							 WHERE cm.PolicyID = cp.PolicyID AND IsTest = @IsTest AND Enable = 1 AND CustomerClass = @CustomerClass AND Type = 1
							) cc
			WHERE	cp.SiteID IN (0, @NewSiteID, @SiteID)
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
				MAX(cc.Spread) AS SumSpread
			FROM CustomerClassSpreadDetail cp WITH(NOLOCK)
				CROSS APPLY (SELECT TOP 1 
								cs.Spread
							 FROM CustomerClassSpreadClass cm WITH(NOLOCK)
								INNER JOIN CustomerClassSpread cs WITH(NOLOCK) ON cm.PolicyID = cs.PolicyID 
							 WHERE cm.PolicyID = cp.PolicyID AND IsTest = @IsTest AND Enable = 1 AND CustomerClass = @CustomerClass AND Type = 1
							) cc
			WHERE	cp.SiteID IN (0, @NewSiteID, @SiteID)
				AND cp.Currency IN (0, @Currency)
				AND cp.Platform IN (0, @Platform)
			GROUP BY cp.SportType) KQ
	END 
END