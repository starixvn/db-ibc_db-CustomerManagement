/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteCheck] 
	@PolicySites  VARCHAR(MAX)
	, @IsTest TINYINT
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20231005@Winfred: [NAP CM] Enhance for Site Management [RedmineID: #195100] 
		- 20231107@Winfred: [NAP CM] Customer Class - Auto include new items for rows that is selected option "All" [RedmineID: #186699] 
		- 20240223@Winfred: [NAP CM] - CCMgt - Update SP to call loop for updating policies [RedmineID: #201256] 

	Param's Explanation:
	* @Policys:
		'<ROOT><r PolicyID = 1 Site = "6777777" Currency = 20 Platform = 1/> 
			   <r PolicyID = 2 Site = "2222222" Currency = 4 Platform = 2/>
		</ROOT>'
	* Site : "All : All
			  AllCredit : All site Credit 
			  AllDeposit : All site Deposit"
	* Currency : 0 : All
	* Platform : "0 : All
				  1 : Desktop
				  2 : Mobile
				  3 : APP
				  4 : Oddsfeed
				  5 : DirectAPI"
	Example: NAP_LM_CustomerClassPolicySiteCheck @PolicySites ='<ROOT><r PolicyID=1 Site="6777777" Currency=20 Platform=1/> 
		<r PolicyID=2 PolicyTitle="2222222" Currency=4 Platform=2/> </ROOT>' ,@ErrCode =0, @ErrMsg = ''
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	DECLARE @iDoc INT
	
	--Check if XML is null or empty
	IF @PolicySites IS NULL	OR @PolicySites = ''
		RETURN
	
	CREATE TABLE #CustomerClassSiteManagement( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, 
							Platform TINYINT, IsTest TINYINT,SportType SMALLINT, isDeposit BIT, STT INT IDENTITY (1,1))
	CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX))
	CREATE TABLE #CustomerClassCurrency( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, CurrencyName	nvarchar(50), Platform VARCHAR(MAX))
	CREATE CLUSTERED INDEX CIX_CustomerClassSiteManagement ON #CustomerClassSiteManagement(PolicyID, Site, Currency, Platform)
	CREATE NONCLUSTERED INDEX IX_CustomerClassSiteManagement ON #CustomerClassSiteManagement(Site, Currency, Platform) INCLUDE (STT)
	CREATE NONCLUSTERED INDEX ix_temp ON #CustomerClassCurrency(PolicyID, Site) INCLUDE (Platform,Currency)
	CREATE TABLE #SiteTbl ( site_parent NVARCHAR(50),Site NVARCHAR(50), isDeposit BIT)
	CREATE CLUSTERED INDEX CIX_SiteTbl ON #SiteTbl( site_parent, Site, isDeposit) 
	CREATE NONCLUSTERED INDEX IX_SiteTbl ON #SiteTbl( Site, isDeposit) 

	BEGIN TRY
		EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT,	@PolicySites;

		INSERT INTO	#CustomerClass (PolicyID , Site , Currency , Platform	)
		SELECT	CASE WHEN Data.PolicyID = '' THEN null ELse  CAST(Data.PolicyID AS INT) END AS PolicyID  				
			 ,	Data.Site 					    
			 ,	Data.Currency 					    
			 ,	Data.Platform
		FROM OPENXML (@iDoc, '/ROOT/r', 1) 
		WITH (
			 PolicyID  VARCHAR(20),           
			 Site 	   NVARCHAR(MAX),
			 Currency  VARCHAR(MAX),
			 Platform  VARCHAR(MAX)
		) AS Data;

		EXECUTE	sp_xml_removedocument	@iDoc;
	END TRY
	BEGIN CATCH
		SELECT  @ErrMsg = N'Invalid XML format'	, @ErrCode = 3 ;		
		RETURN
	END CATCH

	INSERT INTO #CustomerClassSiteManagement(PolicyID, Site, Currency, Platform, SportType, IsTest, isDeposit)  
	 SELECT a.PolicyID, b.Site, CAST(c.Currency AS TINYINT) AS Currency, CAST(d.Platform  AS TINYINT) AS Platform  , aRule.SportType , @IsTest , s.isDeposit
	FROM #CustomerClass a
	  INNER JOIN CustomerClassPolicyManagement aRule WITH(NOLOCK) ON a.PolicyID = aRule.PolicyID
	  CROSS APPLY ( SELECT VALUE AS site FROM STRING_SPLIT(a.Site,',') WHERE VALUE <> '' ) b  
	  CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(a.Currency,',') WHERE VALUE <> '' ) c  
	  CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(a.Platform,',') WHERE VALUE <> '' ) d   
	  OUTER APPLY ( SELECT TOP 1 IsDeposit FROM Site WITH(NOLOCK) WHERE isActive = 1 AND site = b.site ) s 
	ORDER BY PolicyID, IsDeposit, site, Currency, Platform
	
	INSERT INTO #SiteTbl (Site , site_parent, isDeposit)
	SELECT DISTINCT site, site, s.isDeposit
	FROM #CustomerClassSiteManagement a
		OUTER APPLY ( SELECT TOP 1 IsDeposit FROM Site WITH(NOLOCK) WHERE isActive = 1 AND site = a.site ) s 

	IF EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'All' )
	BEGIN
		INSERT INTO #SiteTbl (Site, site_parent , isDeposit) 
		SELECT site , 'All', isDeposit 
		FROM Site a WITH(NOLOCK) 
		WHERE  isActive = 1 
		UNION ALL SELECT 'AllDeposit' , 'All',  1 AS isDeposit 
		UNION ALL SELECT 'AllCredit' , 'All',  0 AS isDeposit 
	END

	IF EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'AllCredit' )
	BEGIN
		INSERT INTO #SiteTbl (Site, site_parent , isDeposit) 
		SELECT site , 'AllCredit', isDeposit 
		FROM Site a WITH(NOLOCK) 
		WHERE  IsDeposit = 0 AND isActive = 1 
		UNION ALL SELECT 'All' , 'AllCredit', NULL AS isDeposit 
	END

	IF EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'AllDeposit' )
	BEGIN
		INSERT INTO #SiteTbl (Site ,site_parent, isDeposit) 
		SELECT site , 'AllDeposit', isDeposit
		FROM Site a WITH(NOLOCK) 
		WHERE  IsDeposit = 1 AND isActive = 1 
		UNION ALL SELECT 'All' , 'AllDeposit', NULL AS isDeposit 
	END
	
	IF  EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE IsDeposit = 0) AND NOT EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'AllCredit' AND isDeposit IS NOT NULL)
	BEGIN
		INSERT INTO #SiteTbl (Site, site_parent, isDeposit) 
		SELECT DISTINCT 'AllCredit', site , 0 AS isDeposit FROM #CustomerClassSiteManagement a WHERE IsDeposit = 0
		AND NOT EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'AllCredit' AND site_parent = a.site)
		AND Site NOT IN ('All', 'AllDeposit', 'AllCredit')
		UNION
		SELECT DISTINCT 'All', site , 0 AS isDeposit FROM #CustomerClassSiteManagement a WHERE IsDeposit = 0
		AND NOT EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'All' AND site_parent = a.site)
		AND Site NOT IN ('All', 'AllDeposit', 'AllCredit')
	END

	IF EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE IsDeposit = 1) AND NOT EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'AllDeposit' AND isDeposit IS NOT NULL)
	BEGIN
		INSERT INTO #SiteTbl (Site, site_parent, isDeposit) 
		SELECT DISTINCT 'AllDeposit', site , 1 AS isDeposit FROM #CustomerClassSiteManagement a WHERE IsDeposit = 1
		AND NOT EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'AllDeposit' AND site_parent = a.site)
		AND Site NOT IN ('All', 'AllDeposit', 'AllCredit')
		UNION
		SELECT DISTINCT 'All', site , 1 AS isDeposit FROM #CustomerClassSiteManagement a WHERE IsDeposit = 1
		AND NOT EXISTS(SELECT TOP 1 1 FROM #SiteTbl WHERE site = 'All' AND site_parent = a.site)
		AND Site NOT IN ('All', 'AllDeposit', 'AllCredit')
	END
	
	 -- delete duplicate detail for all or duplicate detail of param (only delete detail)
	 DELETE a FROM #CustomerClassSiteManagement a  
		CROSS APPLY( SELECT DISTINCT Site , isDeposit FROM #SiteTbl WHERE site_parent = a.Site) s
	 WHERE EXISTS( SELECT TOP 1 1 
				FROM #CustomerClassSiteManagement b
				WHERE a.PolicyID = b.PolicyID 
					AND 1 = CASE WHEN s.isDeposit = 1 AND b.Site IN ('All', 'AllDeposit' , s.Site) THEN 1
								 WHEN s.isDeposit = 0 AND b.Site IN ('All', 'AllCredit' , s.Site) THEN 1 
								 WHEN s.isDeposit IS NULL AND s.Site  IN ( 'AllCredit') AND b.Site IN ('All', 'AllCredit' ) THEN 1 
								 WHEN s.isDeposit IS NULL AND s.Site  IN ( 'AllDeposit') AND b.Site IN ('All', 'AllDeposit') THEN 1 
								 WHEN s.isDeposit IS NULL AND s.Site  IN ( 'All') AND b.Site IN ('All') THEN 1 
								ELSE 0 END 
				AND b.Currency IN (0,  a.Currency) AND b.Platform IN (0,  a.Platform)
				AND a.STT > b.STT)
		AND (a.Site NOT IN ('All', 'AllCredit','AllDeposit') OR s.isDeposit IS NULL)
	--> row all and row detail (input)

	-- delete duplicate detail for all or duplicate detail of data (only delete detail)
	DELETE a FROM #CustomerClassSiteManagement a   
			CROSS APPLY( SELECT DISTINCT Site , isDeposit FROM #SiteTbl WHERE site_parent = a.Site) s
	WHERE EXISTS( SELECT TOP 1 1 FROM CustomerClassSiteManagement b WITH(NOLOCK)
					WHERE a.PolicyID = b.PolicyID 
					AND 1 = CASE WHEN s.isDeposit = 1 AND b.Site IN ('All', 'AllDeposit' , s.Site) THEN 1
								 WHEN s.isDeposit = 0 AND b.Site IN ('All', 'AllCredit' ,  s.Site) THEN 1 
								 WHEN s.isDeposit IS NULL AND s.Site  IN ( 'AllCredit') AND b.Site IN ('All', 'AllCredit' ) THEN 1 
								 WHEN s.isDeposit IS NULL AND s.Site  IN ( 'AllDeposit') AND b.Site IN ('All', 'AllDeposit') THEN 1 
								 WHEN s.isDeposit IS NULL AND s.Site  IN ( 'All') AND b.Site IN ('All') THEN 1 
							ELSE 0 END 
					AND (b.Currency IN (0,  a.Currency) ) AND (b.Platform IN (0,  a.Platform)))
		AND (a.Site NOT IN ('All', 'AllCredit','AllDeposit') OR s.isDeposit IS NULL)
	--> row all and row detail (input and data) 

	-- Get all Platform for policy 
	INSERT INTO #CustomerClassCurrency(PolicyID, Site, Currency, Platform)
	SELECT  DISTINCT b.PolicyID, b.Site, b.Currency, c.Platforms
	FROM #CustomerClassSiteManagement a 
		CROSS APPLY( SELECT TOP 1 SportType , IsTest FROM CustomerClassPolicyManagement  WITH(NOLOCK) WHERE PolicyID = a.PolicyID) aRule
		CROSS APPLY( SELECT DISTINCT Site , isDeposit FROM #SiteTbl WHERE site_parent = a.Site) s
		CROSS APPLY( SELECT DISTINCT cc.PolicyID , cc.Site, cc.Currency 
					FROM CustomerClassSiteManagement cc WITH(NOLOCK) 
						CROSS APPLY( SELECT TOP 1 SportType , IsTest FROM CustomerClassPolicyManagement  WITH(NOLOCK) WHERE PolicyID = cc.PolicyID) bRule
					WHERE cc.PolicyID <> a.PolicyID AND aRule.SportType = bRule.SportType AND aRule.IsTest = bRule.IsTest
								AND cc.Site IN ( s.Site , 'All')
								AND (a.Currency IN (0,  cc.Currency) OR cc.Currency = 0) 
								AND (a.Platform IN (0,  cc.Platform) OR cc.Platform = 0 )) b
		CROSS APPLY(
			SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
			FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
				FROM CustomerClassSiteManagement WITH(NOLOCK)
				WHERE PolicyID = b.PolicyID AND b.Site = Site AND b.Currency = currency) mis
		) c

	-- Group Currency

	SELECT DISTINCT  a.PolicyID,
			b.PolicyTitle,
			a.Site,
			d.CurrencyName,
			a.Platform
		FROM #CustomerClassCurrency a WITH(NOLOCK)
			INNER JOIN CustomerClassPolicyManagement b WITH(NOLOCK) ON a.PolicyID = b.PolicyID
			CROSS APPLY(
				SELECT STRING_AGG(CurrencyName, ',') WITHIN GROUP (ORDER BY CurrencyName)  AS CurrencyName
				FROM (SELECT DISTINCT (CASE WHEN b.currency = 0 THEN 'ALL' ELSE e.currency END) AS CurrencyName
				FROM #CustomerClassCurrency b
					LEFT JOIN exchange e WITH(NOLOCK) ON b.Currency = e.ExchangeId
				WHERE b.PolicyID = a.PolicyID AND a.Site = b.Site AND a.Platform = b.Platform ) mis
			) d

	DROP TABLE #CustomerClass
	DROP TABLE #CustomerClassSiteManagement
	DROP TABLE #CustomerClassCurrency

END
GO
