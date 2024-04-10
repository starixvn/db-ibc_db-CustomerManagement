/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSpreadSel] 
	  @CustomerClasses 	VARCHAR(MAX)=''
	, @SportTypes VARCHAR(2000)
	, @Sites 			VARCHAR(MAX)=''
	, @Currencies 		VARCHAR(MAX)=''
	, @Spread 			DECIMAL(4,2)
	, @IsTest TINYINT
AS
/*
	Created: Winfred
	Date: 20230627
	Task : [NAP CM] Customer Class - Add Spread on rule setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20230627@Winfred: [NAP CM] Customer Class - Add Spread on rule setting [RedmineID: #187354] 
		- 20240115@Luke: [NAP CM] Customer Class - Spread mng - Set Spread by Sport [Redmine: #195328]
		- 20240314@Winfred: [NAP CM] Customer Class - Grant permission for each Sport type [RedmineID: #199465] 

	Param's Explanation:

	Example: exec NAP_LM_CustomerClassSpreadSel @CustomerClasses = '', @Sites = '0', @Currencies = '0', @Spread = 0, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #CustomerClassSpread(PolicyID INT PRIMARY KEY CLUSTERED, PolicyTitle VARCHAR(500), SportType SMALLINT, Spread DECIMAL(4,2), Enable BIT,IsTest TINYINT, 
		CustomerClass VARCHAR(MAX), Sites VARCHAR(MAX), Currencies VARCHAR(MAX), Platforms VARCHAR(MAX), 
		LastModifiedUser INT, LastModifiedTime DATETIME)
	CREATE TABLE #Site(SiteID INT, isDeposit BIT)
	CREATE TABLE #Currency(Currency INT)  
	CREATE TABLE #CC(CustomerClass SMALLINT)  
	CREATE TABLE #SportType(SportType SMALLINT)  
	
	SELECT @CustomerClasses = ISNULL(@CustomerClasses, '')
	
	INSERT INTO #CC(CustomerClass) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(@CustomerClasses,',') 
	WHERE VALUE <> ''

	INSERT INTO #SportType(SportType) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(ISNULL(@SportTypes,''),',') 
	WHERE VALUE <> ''

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

	IF  EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 0)  
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -1
	END  
  
	IF  EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 1)  
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -2
	END 

	INSERT INTO #Site (SiteID) SELECT 0
	INSERT INTO #Currency (Currency) SELECT 0

	CREATE CLUSTERED INDEX CIX_Site		ON #Site(SiteID)
	CREATE CLUSTERED INDEX CIX_Currency ON #Currency(Currency)
	CREATE CLUSTERED INDEX CIX_CC		ON #CC(CustomerClass)
	-- Apply index IX_CustomerClassSpread_Spread
	IF @Spread IS NULL 
	BEGIN
		INSERT INTO #CustomerClassSpread(PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime)  
		SELECT c.PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime   
		FROM CustomerClassSpread c WITH(NOLOCK)   
		CROSS APPLY(  SELECT TOP 1 cs.PolicyID
					FROM CustomerClassSpreadClass cs WITH(NOLOCK) 
					WHERE c.PolicyID = cs.PolicyID  
					AND (cs.CustomerClass IN (SELECT CustomerClass FROM #CC) OR @CustomerClasses = '')
					) t1
		CROSS APPLY(  SELECT TOP 1 cm.PolicyID, cm.SportType
					FROM CustomerClassSpreadDetail cm WITH(NOLOCK) 
					WHERE c.PolicyID = cm.PolicyID  
						AND cm.SiteID IN (SELECT SiteID FROM #Site) 
						AND cm.Currency IN (SELECT Currency FROM #Currency)
						AND cm.SportType IN (SELECT SportType FROM #SportType)
					) t2
		WHERE c.IsTest <= @IsTest  
		OPTION (RECOMPILE)
	END
	ELSE 
	BEGIN
		INSERT INTO #CustomerClassSpread(PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime)  
		SELECT c.PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime   
		FROM CustomerClassSpread c WITH(NOLOCK)   
		CROSS APPLY(  SELECT TOP 1 cs.PolicyID
					FROM CustomerClassSpreadClass cs WITH(NOLOCK) 
					WHERE c.PolicyID = cs.PolicyID  
						AND (cs.CustomerClass IN (SELECT CustomerClass FROM #CC) OR @CustomerClasses = '')
					) t1
		CROSS APPLY(  SELECT TOP 1 cm.PolicyID, cm.SportType
					FROM CustomerClassSpreadDetail cm WITH(NOLOCK) 
					WHERE c.PolicyID = cm.PolicyID  
						AND cm.SiteID IN (SELECT SiteID FROM #Site) 
						AND cm.Currency IN (SELECT Currency FROM #Currency)
						AND cm.SportType IN (SELECT SportType FROM #SportType)
					) t2
		WHERE c.Spread = @Spread AND c.IsTest <= @IsTest 
		OPTION (RECOMPILE)
	END

	UPDATE a  
	SET a.CustomerClass =  c.CustomerClasses ,
		a.Currencies =  cu.Currencies ,
		a.Sites =  s.Sites ,
		a.Platforms =  p.Platforms 
	FROM #CustomerClassSpread a
		CROSS APPLY ( SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY CustomerClass) CustomerClasses
						FROM(	SELECT DISTINCT CustomerClass
						FROM CustomerClassSpreadClass WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc) c  
		CROSS APPLY ( SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY Currency) Currencies
						FROM(	SELECT DISTINCT Currency
						FROM CustomerClassSpreadDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc
						) cu 
		CROSS APPLY ( SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY SiteID) Sites
						FROM(	SELECT DISTINCT SiteID
						FROM CustomerClassSpreadDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc
						) s 
		CROSS APPLY ( SELECT STRING_AGG(CAST(Platform AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY Platform) Platforms
						FROM(	SELECT DISTINCT Platform
						FROM CustomerClassSpreadDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc
						) p 

	SELECT PolicyID, PolicyTitle, SportType, Spread, CustomerClass, Currencies, Sites, Platforms,
		   Enable, IsTest, LastModifiedUser, LastModifiedTime 
	FROM #CustomerClassSpread WITH (NOLOCK)
	ORDER BY Enable DESC, PolicyTitle

	DROP TABLE #CustomerClassSpread
	DROP TABLE #Site, #CC, #Currency , #SportType
END
GO
