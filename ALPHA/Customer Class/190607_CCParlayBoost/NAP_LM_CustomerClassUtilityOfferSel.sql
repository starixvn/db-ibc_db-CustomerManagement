/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassUtilityOfferSel] 
	  @CustomerClasses 	VARCHAR(MAX)=''
	, @Sites 			VARCHAR(MAX)=''
	, @Currencies 		VARCHAR(MAX)=''
	, @IsTest TINYINT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Allow to offer Parlay Boost on rule setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231002@Winfred: [NAP CM] Customer Class - Allow to offer Parlay Boost on rule setting [RedmineID: #190607] 

	Param's Explanation:
		* @CustomerClasses : All:''
	Example: exec NAP_LM_CustomerClassUtilityOfferSel @CustomerClasses = '', @Sites = '70', @Currencies = '0', @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #CustomerClassUtilityOffer(PolicyID INT PRIMARY KEY CLUSTERED, PolicyTitle VARCHAR(500), UtilityOffering VARCHAR(500), IsTest TINYINT, CustomerClass VARCHAR(MAX), Sites VARCHAR(MAX), Currencies VARCHAR(MAX), Platforms VARCHAR(MAX), LastModifiedUser INT, LastModifiedTime DATETIME)

	CREATE TABLE #Site(SiteID INT PRIMARY KEY CLUSTERED, isDeposit	BIT)
	CREATE TABLE #Currency(Currency INT PRIMARY KEY CLUSTERED)  
	CREATE TABLE #CC(CustomerClass SMALLINT PRIMARY KEY CLUSTERED) 

	SELECT @CustomerClasses = ISNULL(@CustomerClasses, '')
	
	INSERT INTO #CC(CustomerClass)  
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(@CustomerClasses,',') 
	WHERE VALUE <> ''

	IF @CustomerClasses <> '0'
	BEGIN
		INSERT INTO  #CC(CustomerClass)  SELECT 0 -- All customer class
	END

	IF @Currencies <> '0'
	BEGIN
		INSERT INTO  #Currency(Currency)
		SELECT e.exchangeid
		FROM exchange e WITH(NOLOCK)
			INNER JOIN STRING_SPLIT(@Currencies,',') a
				ON e.ExchangeId = a.value
		WHERE a.VALUE <> ''
	END
	ELSE
	BEGIN
		INSERT INTO  #Currency(Currency)
		SELECT e.exchangeid
		FROM exchange e WITH(NOLOCK)
	END

	IF @Sites <> '0'
	BEGIN
		INSERT INTO #Site(SiteID, isDeposit)
		SELECT s.siteid, s.isDeposit   
		FROM Site s WITH(NOLOCK)  
			INNER JOIN STRING_SPLIT(@Sites,',') a ON s.siteid = a.value  
		WHERE a.VALUE <> ''
	END
	ELSE
	BEGIN
		INSERT INTO #Site(SiteID, isDeposit) 
		SELECT s.siteid, s.isDeposit   
		FROM Site s WITH(NOLOCK)  
	END

	IF  (EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 0) OR CHARINDEX('-1', @Sites) > 0  )
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -1 -- All site Credit
	END  
  
	IF  (EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 1)   OR CHARINDEX('-2', @Sites) > 0  )
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -2 -- All site Deposit
	END 

	INSERT INTO #Site (SiteID) SELECT 0 -- All
	INSERT INTO #Currency (Currency) SELECT 0

	IF @CustomerClasses	= '0' AND @Currencies = '0' AND @Sites = '0'
	BEGIN
		INSERT INTO #CustomerClassUtilityOffer(PolicyID, PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime) 
			SELECT DISTINCT a.PolicyID , PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime 
			FROM CustomerClassUtilityOffer a WITH(NOLOCK) 
				CROSS APPLY( SELECT TOP 1 PolicyID 
						FROM CustomerClassUtilityOfferDetail c WITH(NOLOCK) 
						WHERE  c.PolicyID = a.PolicyID 
							AND c.isDeleted = 0
						) d
			WHERE isDeleted = 0  AND IsTest <= @IsTest 
	END
	ELSE IF @CustomerClasses = '0' 
	BEGIN
		INSERT INTO #CustomerClassUtilityOffer(PolicyID, PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime) 
		SELECT  DISTINCT a.PolicyID , PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime
		FROM CustomerClassUtilityOffer a WITH(NOLOCK) 
			INNER JOIN CustomerClassUtilityOfferDetail b WITH(NOLOCK)  ON a.PolicyID = b.PolicyID AND a.isDeleted = b.isDeleted
			INNER JOIN #Currency c on b.Currency = c.Currency
			INNER JOIN #Site s on s.SiteID = b.SiteID
		WHERE a.isDeleted = 0  AND IsTest <= @IsTest
	END
	ELSE IF @Currencies = '0' 
	BEGIN
		INSERT INTO #CustomerClassUtilityOffer(PolicyID, PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime) 
		SELECT  DISTINCT a.PolicyID , PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime
		FROM CustomerClassUtilityOffer a WITH(NOLOCK) 
			INNER JOIN CustomerClassUtilityOfferDetail b WITH(NOLOCK)  ON a.PolicyID = b.PolicyID AND a.isDeleted = b.isDeleted
		WHERE a.isDeleted = 0  AND IsTest <= @IsTest 
		AND EXISTS(SELECT TOP 1 1 FROM #Site where SiteID = b.SiteID ) 
		AND EXISTS(SELECT TOP 1 1 FROM #CC where CustomerClass = b.CustomerClass )
	END
	ELSE
	BEGIN
		INSERT INTO #CustomerClassUtilityOffer(PolicyID, PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime) 
		SELECT  DISTINCT v.PolicyID , PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime
		FROM #Currency a
		CROSS APPLY (SELECT CustomerClass FROM #CC) b
		CROSS APPLY (SELECT SiteID FROM #Site) s
		CROSS APPLY( SELECT DISTINCT PolicyID 
					FROM CustomerClassUtilityOfferDetail c WITH(NOLOCK) 
					WHERE a.Currency = c.Currency
						AND c.CustomerClass = b.CustomerClass
						AND c.SiteID = s.SiteID 
						AND c.isDeleted = 0
					) d
		CROSS APPLY( SELECT TOP 1 PolicyID , PolicyTitle, UtilityOffering, IsTest, LastModifiedUser, LastModifiedTime 
					FROM CustomerClassUtilityOffer WITH(NOLOCK) 
					WHERE PolicyID = d.PolicyID AND isDeleted = 0  AND IsTest <= @IsTest 
					) v
	END

	UPDATE a  
	SET a.CustomerClass =  c.CustomerClasses ,
		a.Currencies =  cu.Currencies ,
		a.Sites =  s.Sites 
	FROM #CustomerClassUtilityOffer a
		CROSS APPLY ( SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY CustomerClass) CustomerClasses
					  FROM(	SELECT DISTINCT CustomerClass
						FROM CustomerClassUtilityOfferDetail WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID AND isDeleted = 0) cc) c  
		CROSS APPLY ( SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY Currency) Currencies
					  FROM(	SELECT DISTINCT Currency
						FROM CustomerClassUtilityOfferDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID AND isDeleted = 0) cc
						) cu 
		CROSS APPLY ( SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY SiteID) Sites
					  FROM(	SELECT DISTINCT SiteID
						FROM CustomerClassUtilityOfferDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID AND isDeleted = 0) cc
						) s 

	SELECT a.PolicyID, a.PolicyTitle, s.UtilityOffering, CustomerClass, Currencies, Sites, IsTest, LastModifiedUser, LastModifiedTime 
	FROM #CustomerClassUtilityOffer a
		CROSS APPLY	(SELECT VALUE AS UtilityOffering FROM dbo.f_SmallIntToOfferValue(a.UtilityOffering)) s
	ORDER BY PolicyTitle

	DROP TABLE #CustomerClassUtilityOffer
	DROP TABLE #Site
	DROP TABLE #Currency
	DROP TABLE #CC
END
GO
