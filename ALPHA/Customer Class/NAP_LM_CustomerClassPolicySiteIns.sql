/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteIns] 
	@PolicySites  NVARCHAR(MAX)
	, @IsTest TINYINT
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

	Param's Explanation:
	* @Policys:
		'<ROOT><r PolicyID = 1 Site = "6777777" Currency = "20,75" Platform = "1,2,3,6"/> 
			   <r PolicyID = 2 Site = "2222222" Currency = "4" Platform = "2,4"/>
		</ROOT>'

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
	  --, @logSpData_Old  NVARCHAR(MAX)  
	  , @RuleIDs    VARCHAR(MAX)  
	  , @xml     XML  
   
	 --Check if XML is null or empty  
	 IF @PolicySites IS NULL OR @PolicySites = ''  
	  RETURN  
   
	 CREATE TABLE #CustomerClassSiteManagement( PolicyID INT, Site NVARCHAR(50), Currency TINYINT,   
		   Platform TINYINT, PolicyID_Dup INT,IsTest TINYINT,SportType	SMALLINT, STT INT IDENTITY (1,1))  
	 CREATE TABLE #CustomerClassSiteManagement_history( PolicyID INT, Site NVARCHAR(50), Currency TINYINT,   
		   Platform TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME)  
	 CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX))  
	 CREATE TABLE #CustomerClassCurrency( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, CurrencyName nvarchar(50), Platform VARCHAR(MAX))  
  
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
  
	 INSERT INTO #CustomerClassSiteManagement(PolicyID, Site, Currency, Platform, SportType,IsTest)  
	 SELECT a.PolicyID, b.Site, CAST(c.Currency AS TINYINT) AS Currency, CAST(d.Platform  AS TINYINT) AS Platform  , aRule.SportType , @IsTest
	 FROM #CustomerClass a  
	  INNER JOIN CustomerClassPolicyManagement aRule WITH(NOLOCK) ON a.PolicyID = aRule.PolicyID
	  CROSS APPLY ( SELECT VALUE AS site FROM STRING_SPLIT(a.Site,',') WHERE VALUE <> '' ) b  
	  CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(a.Currency,',') WHERE VALUE <> '' ) c  
	  CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(a.Platform,',') WHERE VALUE <> '' ) d  
	 -- delete duplicate  
	 DELETE a FROM #CustomerClassSiteManagement a   
	 WHERE EXISTS( SELECT TOP 1 1 FROM #CustomerClassSiteManagement b WITH(NOLOCK)
			WHERE (a.PolicyID = b.PolicyID ) AND a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform AND a.STT < b.STT)    --OR a.SportType = b.SportType
  
	--UPDATE a
	--SET a.PolicyID_Dup = b.PolicyID , a.IsTest = aRule.IsTest
	--FROM #CustomerClassSiteManagement a 
	--	INNER JOIN CustomerClassPolicyManagement aRule WITH(NOLOCK) ON a.PolicyID = aRule.PolicyID
	--	INNER JOIN CustomerClassSiteManagement b WITH(NOLOCK) ON a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform
	--	INNER JOIN CustomerClassPolicyManagement bRule WITH(NOLOCK) ON b.PolicyID = bRule.PolicyID
	--WHERE a.PolicyID <> b.PolicyID AND aRule.IsTest = bRule.IsTest AND aRule.SportType = bRule.SportType
	--AND aRule.IsTest = @IsTest

	 DELETE a FROM #CustomerClassSiteManagement a WHERE PolicyID_Dup = PolicyID  OR 
	 EXISTS( SELECT TOP 1 1 FROM CustomerClassPolicyManagement WITH(NOLOCK)
			WHERE PolicyID = a.PolicyID AND   IsTest <> @IsTest)
	 -- Update new policy for site - currency - platform  
	 --UPDATE a   
	 --SET a.PolicyID   = b.PolicyID        
	 -- ,a.Site   = b.Site        
	 -- ,a.Currency  = b.Currency        
	 -- ,a.Platform  = b.Platform        
	 -- ,a.LastModifiedUser = @UserID  
	 -- ,a.LastModifiedTime = GETDATE()  
	 --OUTPUT deleted.PolicyID       
	 -- , deleted.Site      
	 -- , deleted.Currency      
	 -- , deleted.Platform       
	 -- , deleted.LastModifiedUser            
	 -- , deleted.LastModifiedTime   
	 --INTO #CustomerClassSiteManagement_history(PolicyID, Site ,Currency ,Platform, LastModifiedUser ,LastModifiedTime )  
	 --FROM CustomerClassSiteManagement a WITH (ROWLOCK, UPDLOCK)  
		--INNER JOIN CustomerClassPolicyManagement aRule WITH(NOLOCK) ON a.PolicyID = aRule.PolicyID
		--INNER JOIN #CustomerClassSiteManagement b ON a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform  
		--INNER JOIN CustomerClassPolicyManagement bRule WITH(NOLOCK) ON b.PolicyID = bRule.PolicyID
	 --WHERE a.PolicyID <> b.PolicyID  AND aRule.IsTest = b.IsTest AND aRule.SportType = bRule.SportType
   
	 -- insert new policy for site - currency - platform  
	 INSERT INTO CustomerClassSiteManagement(PolicyID, Site, Currency, Platform, LastModifiedUser, LastModifiedTime)   
	 SELECT a.PolicyID, a.Site, a.Currency, a.Platform, @UserID AS LastModifiedUser, GETDATE() AS LastModifiedTime  
	 FROM #CustomerClassSiteManagement a  
		INNER JOIN CustomerClassPolicyManagement aRule WITH(NOLOCK) ON a.PolicyID = aRule.PolicyID
	 WHERE NOT EXISTS(SELECT TOP 1 1 FROM CustomerClassSiteManagement b WITH(NOLOCK)  
					INNER JOIN CustomerClassPolicyManagement bRule WITH(NOLOCK) ON b.PolicyID = bRule.PolicyID
		 WHERE Site = a.Site AND Currency = a.Currency AND Platform = a.Platform AND aRule.SportType = bRule.SportType AND aRule.PolicyID = bRule.PolicyID)  
	  AND a.PolicyID_Dup IS NULL   
   
	 -- Log new updated data  
	 --SET @xml = (  
	 --  SELECT @UserID      AS '@UserID',      
		-- @IP       AS '@IP',     
		-- COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) AS '@ErrMsg',  
		-- COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) AS '@ErrCode',  
		-- (  
		--  SELECT cs.PolicyID  AS '@PolicyID',  
		--	cs.Site     AS '@Site',  
		--	cs.Currency    AS '@Currency' ,  
		--	cs.Platform    AS '@Platform'    
		--  FROM #CustomerClassSiteManagement_history AS cs   
		--  ORDER BY cs.PolicyID  
		--  FOR XML PATH('PolicySite'),  
		--  TYPE  
		-- )  
	 --  FOR XML PATH('R'),  
	 --  TYPE  
	 -- )  
	 --SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')  
  
	 SET @xml = (  
	   SELECT @UserID      AS '@UserID',      
		 @IP       AS '@IP',     
		 COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) AS '@ErrMsg',  
		 COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) AS '@ErrCode',  
		 (  
		  SELECT cs.PolicyID     AS '@PolicyID',  
			cs.Site     AS '@Site',  
			cs.Currency      AS '@Currency',  
			cs.Platform      AS '@Platform'   
		  FROM #CustomerClassSiteManagement AS cs   
		  ORDER BY cs.PolicyID  
		  FOR XML PATH('PolicySite'),  
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
			    @TrackingValue2 = '',-- @logSpData_Old,
				@duration = @Duration

END
GO
