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
		- 20240303@Helen: SP tuning [RedmineID: #201771] 

	Param's Explanation:
	Example: Dot_Member_CustomerClassUtilityOfferingSel @SiteID = 20, @Currency = 20 , @IsTest=1, @CustomerClass =901, @IsDeposit=0, @IsParlayBoot = @IsParlayBoot OUTPUT
	* @IsDeposit : 0: Credit - 1 : Deposit
	* @Site : 0: All -  -1: Credit - -2: Deposit
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ModeTest BIT = 0
	DECLARE @RefSiteID SMALLINT

	IF @IsDeposit = 0
	BEGIN
		SET @RefSiteID = -1
	END
	ELSE 
	BEGIN
		SET @RefSiteID = -2
	END

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
									WHERE cs.isDeleted = 0 AND cs.IsTest = @IsTest AND cs.UtilityOffering & POWER(2,0) = 1
										AND csd.SiteID IN (0,@SiteID, @RefSiteID) AND csd.Currency IN (0, @Currency) AND csd.CustomerClass IN (0, @CustomerClass)
									),0)
	END
	ELSE
	BEGIN
		SET @IsParlayBoot = ISNULL((SELECT TOP 1  cs.UtilityOffering & POWER(2,0)
									FROM CustomerClassUtilityOffer_UAT cs WITH(NOLOCK)
										INNER JOIN  CustomerClassUtilityOfferDetail_UAT csd WITH(NOLOCK) ON cs.PolicyID = csd.PolicyID AND cs.isDeleted = csd.isDeleted
									WHERE cs.isDeleted = 0  AND cs.IsTest = @IsTest AND cs.UtilityOffering & POWER(2,0) = 1
										AND csd.SiteID IN (0,@SiteID, @RefSiteID) AND csd.Currency IN (0, @Currency) AND csd.CustomerClass IN (0, @CustomerClass)
									),0)
	END
END