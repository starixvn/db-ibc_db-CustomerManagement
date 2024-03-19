/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteIns] 
	@PolicySites  NVARCHAR(MAX)
	, @IsTest		TINYINT
	, @IsOverwrite	BIT = 1
	, @UserID		INT
	, @IP			VARCHAR(50)		= ''
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
		- 20231101@Winfred: [NAP CM] Customer Class - Auto include new items for rows that is selected option "All" [RedmineID: #186699] 
		- 20240223@Winfred: [NAP CM] - CCMgt - Update SP to call loop for updating policies [RedmineID: #201256] 

	Param's Explanation:
	* @Policys:
		'<ROOT><r PolicyID = 1 Site = "6777777" Currency = "20,75" Platform = "1,2,3,6"/> 
			   <r PolicyID = 2 Site = "2222222" Currency = "4" Platform = "2,4"/>
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
	* @IsOverwrite : 1. Overwrite, 0. Not Overwrite
	Example: NAP_LM_CustomerClassPolicySiteIns @PolicySites ='<ROOT><r PolicyID=1 Site="6777777" Currency=20 Platform=1/> 
		<r PolicyID=2 PolicyTitle="2222222" Currency=4 Platform=2/> </ROOT>' ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;   
   
	 DECLARE @StartRun   DATETIME  
	  , @EndRun    DATETIME  
	  , @Duration    INT  
	  , @iDoc     INT  
	  , @PolicyID    INT  
	  , @logSpData   NVARCHAR(MAX)  
	  , @logSpData_Old  NVARCHAR(MAX)  
	  , @RuleIDs    VARCHAR(MAX)  
	  , @xml     XML  
	  , @Threshold	INT = 5000
   
	 --Check if XML is null or empty  
	 IF @PolicySites IS NULL OR @PolicySites = ''  
	  RETURN  
   
	 CREATE TABLE #CustomerClassSiteManagement( PolicyID INT, Site NVARCHAR(50), Currency TINYINT,   
		   Platform TINYINT, IsTest TINYINT,SportType SMALLINT, isDeposit BIT, STT INT IDENTITY (1,1), isFinished BIT DEFAULT(0))  
	 CREATE TABLE #CustomerClassSiteManagement_history( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT,isFinished BIT DEFAULT(0)) 
	 CREATE TABLE #ConverOldData( PolicyID_new INT, Site_new NVARCHAR(50), Currency_new TINYINT, Platform_new TINYINT, 
								  PolicyID_old INT, Site_old NVARCHAR(50), Currency_old TINYINT, Platform_old TINYINT, isDeposit BIT)
	 CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX))  
	CREATE TABLE #tempPS(PolicyID INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT)
	 CREATE NONCLUSTERED INDEX ix_temp ON #CustomerClassSiteManagement(  PolicyID, STT,  Currency, Platform, isDeposit, Site ) 
	 CREATE CLUSTERED INDEX cix_tempPS ON #tempPS( PolicyID, Site, Currency, Platform )

	 BEGIN TRY  
	  EXECUTE sp_xml_preparedocument @iDoc OUTPUT, @PolicySites;  
  
	  INSERT INTO #CustomerClass (PolicyID , Site , Currency , Platform )  
	  SELECT CASE WHEN Data.PolicyID = '' THEN null ELse  CAST(Data.PolicyID AS INT) END AS PolicyID          
		, Data.Site            
		, Data.Currency              
		, Data.Platform  
	  FROM OPENXML (@iDoc, '/ROOT/r', 1)   
	  WITH (  
		PolicyID  VARCHAR(20),             
		Site     NVARCHAR(MAX),  
		Currency  VARCHAR(MAX),  
		Platform  VARCHAR(MAX)  
	  ) AS Data;  
  
	  EXECUTE sp_xml_removedocument @iDoc;  
	 END TRY  
	 BEGIN CATCH  
	  SELECT  @ErrMsg = N'Invalid XML format' , @ErrCode = 3 ;    
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

	CREATE TABLE #SiteTbl ( site_parent NVARCHAR(50),Site NVARCHAR(50), isDeposit BIT)
	CREATE CLUSTERED INDEX CIX_SiteTbl ON #SiteTbl( site_parent, Site, isDeposit) 
	CREATE NONCLUSTERED INDEX IX_SiteTbl ON #SiteTbl( Site, isDeposit) 

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

	IF @IsOverwrite = 1
	BEGIN
		INSERT INTO #ConverOldData(PolicyID_new	, Site_new, Currency_new, Platform_new, PolicyID_old, Site_old, Currency_old, Platform_old, isDeposit)
		SELECT  DISTINCT  a.PolicyID, a.Site, a.Currency, a.Platform, b.PolicyID, b.Site, b.Currency, b.Platform, s.isDeposit
		FROM #CustomerClassSiteManagement a 
			CROSS APPLY( SELECT TOP 1 SportType , IsTest FROM CustomerClassPolicyManagement  WITH(NOLOCK) WHERE PolicyID = a.PolicyID) aRule
			CROSS APPLY( SELECT Site , isDeposit FROM #SiteTbl  WITH(NOLOCK) WHERE site_parent = a.Site) s
			CROSS APPLY( SELECT cc.PolicyID , cc.Site, cc.Currency , cc.Platform
						FROM CustomerClassSiteManagement cc WITH(NOLOCK) 
								CROSS APPLY( SELECT TOP 1 SportType , IsTest FROM CustomerClassPolicyManagement  WITH(NOLOCK) WHERE PolicyID = cc.PolicyID) bRule
						WHERE cc.PolicyID <> a.PolicyID AND aRule.SportType = bRule.SportType AND aRule.IsTest = bRule.IsTest
									AND s.Site = cc.Site
									AND (cc.Currency IN (0,  a.Currency) OR a.Currency = 0)
									AND (cc.Platform IN (0,  a.Platform) OR a.Platform = 0 )) b
		IF EXISTS( SELECT TOP 1 1 FROM #ConverOldData WHERE Site_old IN ('All', 'AllDeposit', 'AllCredit') OR Currency_old = 0 OR Platform_old  = 0)
		BEGIN
			INSERT INTO #CustomerClassSiteManagement(PolicyID, Site, Currency, Platform, isDeposit)
			SELECT DISTINCT a.PolicyID_old, s.site, c.Currency, p.Platform, a.isDeposit
			FROM #ConverOldData a
			CROSS APPLY ( -- split Detail site in table Site , not in detail insert
						SELECT site , isDeposit FROM site WITH(NOLOCK) 
						WHERE isActive = 1 AND 1 = CASE WHEN a.Site_old = 'AllDeposit' AND isDeposit = a.isDeposit AND a.Site_new NOT IN ('All', 'AllDeposit') THEN 1
														WHEN a.Site_old = 'AllCredit' AND isDeposit = a.isDeposit AND a.Site_new NOT IN ('All', 'AllCredit')  THEN 1
														WHEN a.Site_old = 'All' AND a.Site_new <> a.Site_old AND isDeposit = a.isDeposit THEN 1 
														ELSE 0 END
							AND Site NOT IN (SELECT Site From #CustomerClassSiteManagement WHERE site <> Site_new)
						UNION -- Site Data  = All, Input new site Deposit and not in detail insert
						SELECT 'AllDeposit' , NULL AS isDeposit WHERE a.Site_old = 'All' AND (a.isDeposit IS NULL OR a.isDeposit = 0) AND a.Site_new <> a.Site_old
																	AND 1 = CASE WHEN a.Site_new <> 'AllDeposit' THEN 1 
																				 WHEN a.Site_new = 'AllDeposit' AND ((a.Currency_old IN (0, A.Currency_new)) OR (a.Currency_new = 0 AND a.Platform_new <> 0 AND a.Platform_old = 0)) THEN 1 
																				 ELSE 0 END
																	AND NOT EXISTS( SELECT TOP 1 1 FROM #ConverOldData 
																					WHERE isDeposit IS NULL 
																					AND 1 = CASE WHEN a.isDeposit =  0 AND Site_old IN ('All', 'AllCredit') THEN 1
																								 WHEN a.isDeposit =  1 AND Site_old IN ('All', 'AllDeposit') THEN 1 
																								 ELSE 0 END
																						AND Currency_old IN (0, a.Currency_new) AND Platform_old IN (0, Platform_new))
						UNION -- Site Data  = All, Input new site Deposit and not in detail insert
						SELECT 'AllCredit' , NULL AS isDeposit WHERE a.Site_old = 'All' AND (a.isDeposit IS NULL OR a.isDeposit = 1) AND a.Site_new <> a.Site_old
																	AND 1 = CASE WHEN a.Site_new <> 'AllCredit' THEN 1 
																				 WHEN a.Site_new = 'AllCredit' AND ((a.Currency_old IN (0, A.Currency_new)) OR (a.Currency_new = 0 AND a.Platform_new <> 0 AND a.Platform_old = 0)) THEN 1 
																				 ELSE 0 END
																	AND NOT EXISTS( SELECT TOP 1 1 FROM #ConverOldData 
																					WHERE isDeposit IS NULL 
																					AND 1 = CASE WHEN a.isDeposit =  0 AND Site_old IN ('All', 'AllCredit') THEN 1
																								 WHEN a.isDeposit =  1 AND Site_old IN ('All', 'AllDeposit') THEN 1 
																								 ELSE 0 END
																					AND Currency_old IN (0, a.Currency_new) AND Platform_old IN (0, Platform_new)) 
						UNION -- Site Data  not in (All or AllDeposit or AllCredit) , Input new site All
						SELECT a.Site_old  , a.isDeposit AS isDeposit WHERE a.Site_old <> a.Site_new
																	AND  1 = CASE WHEN  a.Site_old IN ('AllDeposit', 'AllCredit') AND Site_new = 'All' THEN 1 
																				   WHEN a.Site_old NOT IN ( 'All','AllDeposit', 'AllCredit') AND Site_new IN ( 'All','AllDeposit', 'AllCredit')  THEN 1 
																				   ELSE 0 END 		
																	 AND  1 = CASE WHEN  a.Currency_old IN (0, a.Currency_new) THEN 1 
																				   WHEN a.Currency_new IN (0, a.Currency_old) AND a.Platform_old IN (0, a.Platform_new) THEN 1 
																				   ELSE 0 END 
						UNION -- split for currency, platform
						SELECT a.Site_new , a.isDeposit WHERE  1 = CASE WHEN a.Site_new = a.Site_old THEN 1 
																		WHEN a.isDeposit = 1 AND a.Site_old IN ('All', 'AllDeposit') AND a.Site_new NOT IN ('All', 'AllDeposit') 
																			AND ((a.Currency_old IN (0, A.Currency_new)) OR (a.Currency_new = 0 AND a.Platform_new <> 0 AND a.Platform_old = 0)) THEN 1 
																		WHEN a.isDeposit = 0 AND a.Site_old IN ('All', 'AllCredit') AND a.Site_new NOT IN ('All', 'AllCredit')
																			AND ((a.Currency_old IN (0, A.Currency_new)) OR (a.Currency_new = 0 AND a.Platform_new <> 0 AND a.Platform_old = 0)) THEN 1 
																		ELSE 0 END 
			) s
			CROSS APPLY (
						SELECT ExchangeId AS Currency FROM exchange WITH(NOLOCK) 
						WHERE ExchangeID NOT IN (27,28) AND a.Currency_old = 0 AND a.Currency_new <> 0 AND ExchangeId <> a.Currency_new AND s.site IN (a.Site_new , a.Site_old)
							  --AND ExchangeId NOT IN (SELECT currency From #CustomerClassSiteManagement WHERE site = s.Site)
						UNION 
						SELECT a.Currency_old WHERE 1 = CASE WHEN a.Site_new = a.Site_old AND a.Platform_old = 0 AND a.Platform_new <> 0 THEN 1

															 WHEN a.Site_new IN ('AllDeposit', 'AllCredit') AND a.Site_old = 'All' 
																	AND (s.site <> a.Site_new OR (s.site = a.Site_new AND a.Currency_new IN (0, a.Currency_old))) THEN 1	
															 WHEN a.Site_new NOT IN ( 'All','AllDeposit', 'AllCredit') AND Site_old IN ( 'All','AllDeposit', 'AllCredit')  
																 AND (s.site <> a.Site_new OR (s.site = a.Site_new AND a.Currency_new IN (0, a.Currency_old))) THEN 1 

															 WHEN a.Site_old IN ('AllDeposit', 'AllCredit') AND a.Site_new = 'All' 
																  AND a.Currency_new IN (0, a.Currency_old) AND a.Platform_old = 0 AND a.Platform_new <> 0  THEN 1	
															 WHEN a.Site_old NOT IN ('All','AllDeposit', 'AllCredit') AND Site_new IN ( 'All','AllDeposit', 'AllCredit')  
																  AND a.Currency_new IN (0, a.Currency_old) AND a.Platform_old = 0 AND a.Platform_new <> 0 THEN 1 
														ELSE 0 END
						UNION 
						SELECT a.Currency_new WHERE a.Currency_old = 0 AND a.Currency_new <> 0 AND a.Platform_old = 0 AND a.Platform_new <> 0
											AND 1 = CASE WHEN s.site = a.Site_new THEN 1
														 WHEN a.Site_old IN ('AllDeposit', 'AllCredit') AND a.Site_new = 'All' THEN 1	
														 WHEN a.Site_old NOT IN ('All','AllDeposit', 'AllCredit') AND Site_new IN ( 'All','AllDeposit', 'AllCredit') THEN 1 
													ELSE 0 END

			) c
			CROSS APPLY (
						SELECT CAST (Platform  AS TINYINT) AS Platform
						FROM (SELECT 1 AS Platform UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) q 
						WHERE a.Platform_old = 0 AND a.Platform_new <> 0 AND Platform <> a.Platform_new 
							AND 1 = CASE WHEN c.Currency = a.Currency_new AND s.site IN (a.Site_new , a.Site_old) THEN 1
								   		 WHEN c.Currency = a.Currency_old AND a.Currency_old <> 0 AND a.Currency_new = 0  AND s.site IN (a.Site_new , a.Site_old) THEN 1	
								   ELSE 0 END
						UNION 
						SELECT a.Platform_old WHERE a.Platform_old <> a.Platform_new 
												   AND 1 = CASE WHEN a.Site_new = a.Site_old AND a.Site_new = s.site AND c.Currency NOT IN ( a.Currency_new, a.Currency_old) THEN 1

															WHEN a.Site_new IN ('AllDeposit', 'AllCredit') AND a.Site_old = 'All' 
																	AND (s.site <> a.Site_new OR ( s.site = a.Site_new AND c.Currency NOT IN ( a.Currency_new, a.Currency_old))) THEN 1	
															 WHEN a.Site_new NOT IN ( 'All','AllDeposit', 'AllCredit') AND Site_old IN ( 'All','AllDeposit', 'AllCredit')  
																 AND (s.site <> a.Site_new OR ( s.site = a.Site_new AND c.Currency NOT IN ( a.Currency_new, a.Currency_old))) THEN 1 

															 WHEN a.Site_old IN ('AllDeposit', 'AllCredit') AND a.Site_new = 'All' 
																 AND  s.site = a.Site_old AND c.Currency NOT IN ( a.Currency_new, a.Currency_old) THEN 1	
															 WHEN a.Site_old NOT IN ('All','AllDeposit', 'AllCredit') AND Site_new IN ( 'All','AllDeposit', 'AllCredit')  
																 AND  s.site = a.Site_old AND c.Currency NOT IN ( a.Currency_new, a.Currency_old) THEN 1

														ELSE 0 END
						UNION 
						SELECT a.Platform_new WHERE a.Platform_old = a.Platform_new
													 AND NOT EXISTS( SELECT TOP 1 1 FROM #ConverOldData 
																	 WHERE  1 = CASE WHEN isDeposit IS NULL AND a.isDeposit =  0 AND site IN ('All', 'AllCredit') THEN 1
																					WHEN isDeposit IS NULL AND a.isDeposit =  1 AND site IN ('All', 'AllDeposit') THEN 1 
																					WHEN s.site = Site_old THEN 1 
																					ELSE 0 END
																			AND Currency IN (0, Currency_old) AND a.Platform_new IN (0, Platform_old))
			) p
			WHERE (a.Site_old IN ('All', 'AllDeposit', 'AllCredit') OR a.Currency_old = 0 OR a.Platform_old  = 0)
				 AND NOT EXISTS( SELECT TOP 1 1 FROM #CustomerClassSiteManagement 
												WHERE   1 = CASE WHEN (site = s.site OR (s.isDeposit = 0 AND site IN ('All', 'AllCredit')) OR (s.isDeposit = 1 AND site IN ('All', 'AllDeposit')) ) THEN 1
																 WHEN s.isDeposit IS NULL AND s.Site = 'AllCredit'  AND (isDeposit = 0 OR s.site = site OR site = 'All' ) THEN 1 
																 WHEN s.isDeposit IS NULL AND s.Site = 'AllDeposit' AND (isDeposit = 1 OR s.site = site OR site = 'All') THEN 1 
																 WHEN s.isDeposit IS NULL AND s.Site = 'All' AND s.site = site THEN 1 
																 ELSE 0 END 
													AND Currency IN (0, c.Currency) AND Platform IN (0, p.Platform))
		END
		
		INSERT INTO #CustomerClassSiteManagement_history(PolicyID, Site, Currency, Platform)
		SELECT DISTINCT PolicyID_old, Site_old, Currency_old, Platform_old
		FROM #ConverOldData
	END

	DELETE a FROM #CustomerClassSiteManagement a WHERE EXISTS( SELECT TOP 1 1 FROM CustomerClassPolicyManagement WITH(NOLOCK) WHERE PolicyID = a.PolicyID AND IsTest <> @IsTest)
	
	IF NOT EXISTS( SELECT TOP 1 1 FROM #CustomerClassSiteManagement)
	BEGIN
		RETURN
	END

	-- insert new policy for site - currency - platform  
	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (@Threshold) c
		SET isFinished = 1
		OUTPUT DELETED.PolicyID, DELETED.Site, DELETED.Currency , DELETED.Platform
		INTO #tempPS(PolicyID, Site,Currency,Platform)
		FROM #CustomerClassSiteManagement c
		WHERE isFinished = 0	
			
		IF @@ROWCOUNT = 0 BREAK 

		INSERT INTO CustomerClassSiteManagement(PolicyID, Site, Currency, Platform, LastModifiedUser, LastModifiedTime)   
		SELECT a.PolicyID, a.Site, a.Currency, a.Platform, @UserID AS LastModifiedUser, GETDATE() AS LastModifiedTime  
		FROM #tempPS a  
		WHERE NOT EXISTS(SELECT TOP 1 1 
						FROM CustomerClassSiteManagement WITH(NOLOCK)  
						WHERE Site = a.Site AND Currency = a.Currency AND Platform = a.Platform AND PolicyID = a.PolicyID) 

		TRUNCATE TABLE #tempPS	
	END
	TRUNCATE TABLE #tempPS	
	-- Remove policy for site - currency - platform duplicate
	IF @IsOverwrite = 1
	BEGIN
		WHILE (1 = 1)
		BEGIN
			UPDATE TOP (@Threshold) c
			SET isFinished = 1
			OUTPUT DELETED.PolicyID, DELETED.Site, DELETED.Currency , DELETED.Platform
			INTO #tempPS(PolicyID, Site,Currency,Platform)
			FROM #CustomerClassSiteManagement_history c
			WHERE isFinished = 0	
			
			IF @@ROWCOUNT = 0 BREAK 

			DELETE a FROM CustomerClassSiteManagement a WITH (ROWLOCK)
			INNER JOIN #tempPS b ON a.PolicyID = b.PolicyID AND a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform 

			TRUNCATE TABLE #tempPS	
		END
	END
	
	IF EXISTS( SELECT TOP 1 1 FROM #CustomerClassSiteManagement WHERE Site IN ('All', 'AllDeposit', 'AllCredit') OR Currency = 0 OR Platform  = 0)
	BEGIN

		INSERT INTO #CustomerClassSiteManagement_history(PolicyID, Site, Currency, Platform)  
		SELECT a.PolicyID, KQ.Site, KQ.Currency, KQ.Platform
		FROM #CustomerClassSiteManagement a  
			CROSS APPLY( SELECT Site , isDeposit FROM #SiteTbl  WITH(NOLOCK) WHERE site_parent = a.Site) s
			CROSS APPLY( SELECT b.Site, b.Currency, b.Platform 
							FROM CustomerClassSiteManagement b WITH(NOLOCK)
							WHERE a.PolicyID = b.PolicyID 
							AND 1 = CASE WHEN a.Site IN ('All') AND s.Site = b.Site THEN 1
										 WHEN a.Site IN ('AllDeposit', 'AllCredit') AND s.Site NOT IN ('All') AND s.Site = b.Site THEN 1
										 WHEN a.Site NOT IN ('All', 'AllDeposit', 'AllCredit') AND a.Site = b.Site THEN 1
										 ELSE 0 END
							AND a.Currency IN (0,  b.Currency) AND a.Platform IN (0,  b.Platform)) KQ
		WHERE a.Site IN ('All', 'AllDeposit', 'AllCredit') OR a.Currency = 0 OR a.Platform  = 0

		DELETE a FROM #CustomerClassSiteManagement_history a 
			INNER JOIN #CustomerClassSiteManagement b ON a.PolicyID = b.PolicyID AND a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform

		WHILE (1 = 1)
		BEGIN
			UPDATE TOP (@Threshold) c
			SET isFinished = 1
			OUTPUT DELETED.PolicyID, DELETED.Site, DELETED.Currency , DELETED.Platform
			INTO #tempPS(PolicyID, Site,Currency,Platform)
			FROM #CustomerClassSiteManagement_history c
			WHERE isFinished = 0	
			
			IF @@ROWCOUNT = 0 BREAK 

			DELETE a FROM CustomerClassSiteManagement a WITH (ROWLOCK)
			INNER JOIN #tempPS b ON a.PolicyID = b.PolicyID AND a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform 

			TRUNCATE TABLE #tempPS	
		END
	END

	 -- Log new updated data  
	 SET @xml = (  
	   SELECT @UserID      AS '@UserID',      
			  @IP       AS '@IP',       
		     @IsOverwrite   AS '@IsOverwrite',
		 COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) AS '@ErrMsg',  
		 COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) AS '@ErrCode',  
		 (  
		  SELECT DISTINCT cs.PolicyID  AS '@PID',  
			s.Sites			AS '@S',  
			c.Currencies    AS '@C' ,  
			p.Platforms		AS '@P'    
		  FROM #CustomerClassSiteManagement_history AS cs   
			CROSS APPLY(
					SELECT STRING_AGG(Site, ',') WITHIN GROUP (ORDER BY Site)  AS Sites
					FROM (SELECT DISTINCT CAST(Site AS VARCHAR(MAX)) AS Site
						FROM #CustomerClassSiteManagement_history WITH(NOLOCK)
						WHERE PolicyID = cs.PolicyID) mis
					) s
			CROSS APPLY(
					SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
					FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(MAX)) AS Platform
						FROM #CustomerClassSiteManagement_history WITH(NOLOCK)
						WHERE PolicyID = cs.PolicyID) mis
					) p
			CROSS APPLY(
					SELECT STRING_AGG(Currency, ',') WITHIN GROUP (ORDER BY Currency)  AS Currencies
					FROM (SELECT DISTINCT CAST(Currency AS VARCHAR(MAX)) AS Currency
						FROM #CustomerClassSiteManagement_history WITH(NOLOCK)
						WHERE PolicyID = cs.PolicyID) mis
					) c  
		  ORDER BY cs.PolicyID  
		  FOR XML PATH('PS'),  
		  TYPE  
		 )  
	   FOR XML PATH('R'),  
	   TYPE  
	  )  
	 SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"') 

	SET @xml = (  
	SELECT @UserID        AS '@UserID',      
		   @IP			  AS '@IP',       
		   @IsOverwrite   AS '@IsOverwrite',      
		COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) AS '@ErrMsg',  
		COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) AS '@ErrCode',  
		(  
		SELECT DISTINCT cs.PolicyID     AS '@PID',  
		s.Sites     AS '@S',  
		c.Currencies      AS '@C',  
		p.Platforms      AS '@P'   
		FROM #CustomerClassSiteManagement AS cs  
		CROSS APPLY(
				SELECT STRING_AGG(Site, ',') WITHIN GROUP (ORDER BY Site)  AS Sites
				FROM (SELECT DISTINCT CAST(Site AS VARCHAR(MAX)) AS Site
					FROM #CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = cs.PolicyID) mis
				) s
		CROSS APPLY(
				SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
				FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(MAX)) AS Platform
					FROM #CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = cs.PolicyID) mis
				) p
		CROSS APPLY(
				SELECT STRING_AGG(Currency, ',') WITHIN GROUP (ORDER BY Currency)  AS Currencies
				FROM (SELECT DISTINCT CAST(Currency AS VARCHAR(MAX)) AS Currency
					FROM #CustomerClassSiteManagement WITH(NOLOCK)
					WHERE PolicyID = cs.PolicyID) mis
				) c
		ORDER BY cs.PolicyID  
		FOR XML PATH('PS'),  
		TYPE  
		)  
	FOR XML PATH('R'),  
	TYPE  
	)  
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')  
	SELECT @EndRun = GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)  

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31905,
				@TrackingValue = @LogSPData,
				@TrackingValue2 = @logSpData_Old,
				@duration = @Duration
	
	DROP TABLE #tempPS
	DROP TABLE #SiteTbl
	DROP TABLE #CustomerClassSiteManagement
	DROP TABLE #CustomerClassSiteManagement_history
	DROP TABLE #ConverOldData
END
GO
