/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
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

	Param's Explanation:
	* @Policys:
		'<ROOT><r PolicyID = 1 Site = "6777777" Currency = 20 Platform = 1/> 
			   <r PolicyID = 2 Site = "2222222" Currency = 4 Platform = 2/>
		</ROOT>'

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
							Platform TINYINT, PolicyID_Dup INT,IsTest TINYINT, STT INT IDENTITY (1,1))
	CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX))
	CREATE TABLE #CustomerClassCurrency( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, CurrencyName	nvarchar(50), Platform VARCHAR(MAX))
	CREATE CLUSTERED INDEX CIX_CustomerClassSiteManagement ON #CustomerClassSiteManagement(PolicyID, Site, Currency, Platform)
	CREATE NONCLUSTERED INDEX inx_temp ON #CustomerClassCurrency(PolicyID, Site) INCLUDE (Platform,Currency)

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

	INSERT INTO #CustomerClassSiteManagement(PolicyID, Site, Currency, Platform, IsTest)	
	SELECT a.PolicyID, b.Site, CAST(c.Currency AS TINYINT) AS Currency, CAST(d.Platform  AS TINYINT) AS Platform , @IsTest
	FROM #CustomerClass a
		CROSS APPLY ( SELECT VALUE AS site FROM STRING_SPLIT(a.Site,',') WHERE VALUE <> '' ) b
		CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(a.Currency,',') WHERE VALUE <> '' ) c
		CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(a.Platform,',') WHERE VALUE <> '' ) d
	
	-- delete duplicate
	DELETE a FROM #CustomerClassSiteManagement a 
	INNER JOIN #CustomerClassSiteManagement b ON a.PolicyID = b.PolicyID AND a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform AND a.STT > b.STT

	--UPDATE a
	--SET a.PolicyID_Dup = b.PolicyID , a.IsTest = aRule.IsTest
	--FROM #CustomerClassSiteManagement a 
	--	INNER JOIN CustomerClassPolicyManagement aRule WITH(NOLOCK) ON a.PolicyID = aRule.PolicyID
	--	INNER JOIN CustomerClassSiteManagement b WITH(NOLOCK) ON a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform
	--	INNER JOIN CustomerClassPolicyManagement bRule WITH(NOLOCK) ON b.PolicyID = bRule.PolicyID
	--WHERE a.PolicyID <> b.PolicyID AND aRule.IsTest = bRule.IsTest AND aRule.SportType = bRule.SportType
	--AND aRule.IsTest = @IsTest
	
	DELETE a FROM #CustomerClassSiteManagement a WHERE PolicyID_Dup IS NULL OR 
	 EXISTS( SELECT TOP 1 1 FROM CustomerClassPolicyManagement WITH(NOLOCK)
			WHERE PolicyID = a.PolicyID AND   IsTest <> @IsTest)
	
	-- Get all Platform for policy 
	INSERT INTO #CustomerClassCurrency(PolicyID, Site, Currency, Platform)
	SELECT DISTINCT a.PolicyID_Dup,
			a.Site,
			a.Currency,
			d.Platforms
	FROM #CustomerClassSiteManagement a WITH(NOLOCK)
		CROSS APPLY(
			SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
			FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
				FROM CustomerClassSiteManagement WITH(NOLOCK)
				WHERE PolicyID = a.PolicyID_Dup AND a.Site = Site AND a.Currency = currency) mis
		) d
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
				FROM (SELECT e.currency AS CurrencyName
				FROM #CustomerClassCurrency b
					INNER JOIN exchange e WITH(NOLOCK) ON b.Currency = e.ExchangeId
				WHERE b.PolicyID = a.PolicyID AND a.Site = b.Site AND a.Platform = b.Platform ) mis
			) d

	DROP TABLE #CustomerClass
	DROP TABLE #CustomerClassSiteManagement

END
GO
