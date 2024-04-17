/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassNonSportsSel] 
	  @CustomerClasses 	VARCHAR(MAX)=''
	, @Sites 			VARCHAR(MAX)=''
	, @Products 		VARCHAR(MAX)=''
	, @AllProducts		VARCHAR(MAX) = '3,8,18,28,40,63,256'
	, @IsTest TINYINT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Support for Non-Sports [
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231002@Winfred: [NAP CM] Customer Class - Support for Non-Sports [RedmineID: #186116] 

	Param's Explanation:
		@Products	: product ID search
		@AllProducts : All product ID
		@@CustomerClasses : All  = 0
	Example: exec NAP_LM_CustomerClassNonSportsSel @CustomerClasses = '', @Sites = '0', @Products = '256',@AllProducts = '3,8,18,28,40,63,256', @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @NewProducts  BINARY(32) = 0x0
	DECLARE @bitmapAll  SMALLINT = 256
	CREATE TABLE #CustomerClassNonSports(PolicyID INT PRIMARY KEY CLUSTERED, PolicyTitle VARCHAR(500), MaxBet INT, Enable BIT,IsTest TINYINT, CustomerClass VARCHAR(MAX), Sites VARCHAR(MAX), Products VARCHAR(MAX), LastModifiedUser INT, LastModifiedTime DATETIME, Products_old BINARY(32))
	CREATE TABLE #Site(SiteID SMALLINT, isDeposit	BIT)
	CREATE TABLE #CC(CustomerClass SMALLINT)  
	CREATE TABLE #CCProducts(PolicyID INT, ProductID SMALLINT, OfferProduct BIT)  
	CREATE CLUSTERED INDEX CIX_CCProducts ON #CCProducts(PolicyID, ProductID)
	
	SELECT @CustomerClasses = ISNULL(@CustomerClasses, '')
	
	INSERT INTO #CC(CustomerClass) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(@CustomerClasses,',') 
	WHERE VALUE <> ''
	
	IF @Sites <> '0'
	BEGIN
		INSERT INTO #Site(SiteID, isDeposit)  
		SELECT s.SiteID, s.isDeposit   
		FROM Site s WITH(NOLOCK)  
			INNER JOIN STRING_SPLIT(@Sites,',') a ON s.SiteID = a.value  
		WHERE a.VALUE <> ''
	END
	ELSE
	BEGIN
		INSERT INTO #Site(SiteID, isDeposit)  
		SELECT s.SiteID, s.isDeposit   
		FROM Site s WITH(NOLOCK)  
	END

	IF  EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 0)  
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -1 --AllCredit
	END  
  
	IF  EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 1)  
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -2 --AllDeposit
	END 

	INSERT INTO #Site (SiteID) SELECT 0

	IF @CustomerClasses <> '0'
	BEGIN
		INSERT INTO #CustomerClassNonSports(PolicyID, PolicyTitle, MaxBet, Enable, IsTest, LastModifiedUser, LastModifiedTime, Products_old)  
		SELECT DISTINCT c.PolicyID, PolicyTitle, MaxBet, Enable, IsTest, LastModifiedUser, LastModifiedTime, Products  
		FROM CustomerClassNonSports c WITH(NOLOCK)  
		CROSS APPLY (SELECT SiteID FROM #Site ) s
		CROSS APPLY (SELECT CustomerClass FROM #CC ) cc
		CROSS APPLY(SELECT TOP 1 cm.PolicyID 
					FROM CustomerClassNonSportsDetail cm WITH(NOLOCK) 
					WHERE c.PolicyID = cm.PolicyID  AND SiteID = s.SiteID AND CustomerClass IN (0, cc.CustomerClass) AND cm.isDeleted = 0
					) t2
		WHERE c.IsTest <= @IsTest AND c.isDeleted = 0 
	END
	ELSE
	BEGIN
		INSERT INTO #CustomerClassNonSports(PolicyID, PolicyTitle, MaxBet, Enable, IsTest, LastModifiedUser, LastModifiedTime, Products_old)  
		SELECT DISTINCT c.PolicyID, PolicyTitle, MaxBet, Enable, IsTest, LastModifiedUser, LastModifiedTime, Products  
		FROM CustomerClassNonSports c WITH(NOLOCK)  
		CROSS APPLY (SELECT SiteID FROM #Site ) s
		CROSS APPLY(SELECT TOP 1 cm.PolicyID 
					FROM CustomerClassNonSportsDetail cm WITH(NOLOCK) 
					WHERE c.PolicyID = cm.PolicyID  AND SiteID = s.SiteID AND cm.isDeleted = 0
					) t2
		WHERE c.IsTest <= @IsTest AND c.isDeleted = 0
	END
	-- Generate Product offer 
	INSERT INTO #CCProducts(PolicyID, ProductID, OfferProduct)
	SELECT a.PolicyID , p.ProductID, p.Offer
	FROM #CustomerClassNonSports a
	CROSS APPLY ( SELECT ProductID, Offer 
				  FROM dbo.f_GetValueBitmap_multiple(a.Products_old, @AllProducts) ) p
	ORDER BY a.PolicyID , p.ProductID
	
	IF @Products <> '256'
	BEGIN
		DELETE a  
		FROM #CustomerClassNonSports a
		WHERE NOT EXISTS(SELECT TOP 1 1 FROM #CCProducts WHERE PolicyID = a.PolicyID AND ProductID = @bitmapAll AND OfferProduct = 1 ) 
		AND  a.PolicyID NOT IN ( SELECT PolicyID FROM #CCProducts 
								WHERE  OfferProduct = 1 AND ProductID IN (SELECT VALUE FROM STRING_SPLIT(@Products,',')) )
	END 

	UPDATE a  
	SET a.CustomerClass =  c.CustomerClasses ,
		a.Sites =  s.Sites ,
		a.Products = p.ProductIDs
	FROM #CustomerClassNonSports a
		CROSS APPLY ( SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY CustomerClass) CustomerClasses
					  FROM(	SELECT DISTINCT CustomerClass
						FROM CustomerClassNonSportsDetail WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID AND isDeleted = 0) cc) c  
		CROSS APPLY ( SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY SiteID) Sites
					  FROM(	SELECT DISTINCT SiteID
						FROM CustomerClassNonSportsDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID AND isDeleted = 0) cc
						) s 
		CROSS APPLY ( SELECT STRING_AGG(CAST(ProductID AS NVARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY ProductID) ProductIDs
					  FROM(	SELECT DISTINCT ProductID
						FROM #CCProducts  
						WHERE PolicyID = a.PolicyID AND OfferProduct = 1) cc
						) p 

	SELECT PolicyID, PolicyTitle, MaxBet, CustomerClass, Sites, Products,
		   Enable, IsTest, LastModifiedUser, LastModifiedTime 
	FROM #CustomerClassNonSports
	ORDER BY Enable DESC, PolicyTitle

	DROP TABLE #CustomerClassNonSports
	DROP TABLE #Site
	DROP TABLE #CC
	DROP TABLE #CCProducts
END
GO
