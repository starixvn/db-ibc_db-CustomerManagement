/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,Dot_Member" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CustomerClassUtilityOfferingSel] 
	@SiteID INT, 
	@Currency INT,
	@CustomerClass SMALLINT,
	@IsDeposit BIT = 0,
	@IsTest BIT = 0, 
	@IsParlayBoot BIT OUTPUT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Allow to offer Parlay Boost on rule setting [#190607]
	DB: DBCUST/CustDB
	Original: 

	Revisions:
		- 20231002@Winfred: [NAP CM] Allow to offer Parlay Boost on rule setting [RedmineID: #190607] 

	Param's Explanation:
	Example: Dot_Member_CustomerClassUtilityOfferingSel @SiteID = 20, @Currency = 20 , @IsTest=1, @CustomerClass =901, @IsDeposit=0, @IsParlayBoot = @IsParlayBoot OUTPUT
	* @IsDeposit : 0: Credit - 1 : Deposit
	* @Site : 0: All -  -1: Credit - -2: Deposit
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ModeTest BIT = 0
	DECLARE @SiteTbl TABLE(SiteID INT)
	DECLARE @OfferTbl TABLE(SiteID INT, Currency TINYINT, CustomerClass SMALLINT)
	INSERT INTO @SiteTbl (SiteID) SELECT  0 --All
	INSERT INTO @SiteTbl (SiteID) SELECT @SiteID
	IF @IsDeposit = 0 
	BEGIN
		INSERT INTO @SiteTbl (SiteID) SELECT  -1 --AllCredit
	END
	ELSE
	BEGIN
		INSERT INTO @SiteTbl (SiteID) SELECT  -2 --AllDeposit
	END

	INSERT INTO @OfferTbl (SiteID, Currency, CustomerClass) 
	SELECT SiteID , c.Currency, d.CustomerClass
	FROM @SiteTbl s
		CROSS APPLY (SELECT @Currency AS  Currency UNION SELECT 0 AS  Currency) c
		CROSS APPLY (SELECT @CustomerClass AS  CustomerClass UNION SELECT 0 AS CustomerClass) d

	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClass]()

	IF @ModeTest = 0 
	BEGIN
		SET @IsParlayBoot = ISNULL((SELECT TOP 1  cs.UtilityOffering & POWER(2,0)
									FROM CustomerClassUtilityOffer cs WITH(NOLOCK)
										INNER JOIN  CustomerClassUtilityOfferDetail csd WITH(NOLOCK) ON cs.PolicyID = csd.PolicyID AND cs.isDeleted = csd.isDeleted
										INNER JOIN @OfferTbl s ON csd.SiteID = s.SiteID AND csd.Currency = s.Currency AND csd.CustomerClass = s.CustomerClass
									WHERE cs.isDeleted = 0 AND cs.IsTest = @IsTest AND cs.UtilityOffering & POWER(2,0) = 1),0)
	END
	ELSE
	BEGIN
		SET @IsParlayBoot = ISNULL((SELECT TOP 1  cs.UtilityOffering & POWER(2,0)
									FROM CustomerClassUtilityOffer_UAT cs WITH(NOLOCK)
										INNER JOIN  CustomerClassUtilityOfferDetail_UAT csd WITH(NOLOCK) ON cs.PolicyID = csd.PolicyID AND cs.isDeleted = csd.isDeleted
										INNER JOIN @OfferTbl s ON csd.SiteID = s.SiteID AND csd.Currency = s.Currency AND csd.CustomerClass = s.CustomerClass
									WHERE cs.isDeleted = 0  AND cs.IsTest = @IsTest AND cs.UtilityOffering & POWER(2,0) = 1),0)
	END
END