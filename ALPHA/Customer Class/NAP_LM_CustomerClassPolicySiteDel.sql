/*<info serverAlias="DBACC-bodb02,DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteDel] 
	@PolicySites  NVARCHAR(MAX)
	, @IsTest TINYINT
	, @UserID		INT
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20231005
	Task : [NAP CM] Build Customer Class Management [#195100]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231005@Winfred: [NAP CM] Enhance for Site Management [RedmineID: #195100]
		- 20231107@Winfred: [NAP CM] Customer Class - Auto include new items for rows that is selected option "All" [RedmineID: #186699]  
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  

	Param's Explanation:
	* @PolicySites:
		'<ROOT><r PolicyID = 1 Site = "6777777" Currency = "20,75" Platform = "1,2,3,6"/> 
			   <r PolicyID = 2 Site = "2222222" Currency = "4" Platform = "2,4"/>
		</ROOT>'

	Example: NAP_LM_CustomerClassPolicySiteDel @PolicySites ='<ROOT><r PolicyID = 1 Site = "6777777" Currency = "20,75" Platform = "1,2,3,6"/> <r PolicyID = 2 Site = "2222222" Currency = "4" Platform = "2,4"/> </ROOT>' ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;   
   
	 DECLARE @StartRun   DATETIME  
	  , @EndRun    DATETIME  
	  , @Duration    INT  
	  , @iDoc     INT  
	  , @logSpData_Old  NVARCHAR(MAX)  
	  , @xml     XML  
	  , @Threshold	INT = 5000
   
	 --Check if XML is null or empty  
	 IF @PolicySites IS NULL OR @PolicySites = ''  
	  RETURN  
  
	 CREATE TABLE #CustomerClassSiteManagement_history( PolicyID INT, Site NVARCHAR(50), Currency TINYINT,   
		   Platform TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME, isFinished BIT DEFAULT(0))  
	 CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(MAX), Currency VARCHAR(MAX), Platform VARCHAR(MAX))  
	 CREATE TABLE #tempCC(PolicyID INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT)	
	 CREATE NONCLUSTERED INDEX inx_temp ON #CustomerClassSiteManagement_history(  PolicyID ) INCLUDE ( Currency, Platform )
	 CREATE CLUSTERED INDEX inx_tempCC ON #tempCC( PolicyID, Site, Currency, Platform )

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
  	
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					INNER JOIN #CustomerClass b ON a.PolicyID = b.PolicyID AND a.IsTest <> @IsTest)
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot delete PROD data' 
		RETURN
	END	

	 INSERT INTO #CustomerClassSiteManagement_history(PolicyID, Site, Currency, Platform)  
	 SELECT a.PolicyID, b.Site, CAST(c.Currency AS TINYINT) AS Currency, CAST(d.Platform  AS TINYINT) AS Platform
	 FROM #CustomerClass a  
		CROSS APPLY ( SELECT VALUE AS site FROM STRING_SPLIT(a.Site,',') WHERE VALUE <> '' ) b
		CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(a.Currency,',') WHERE VALUE <> '' ) c  
		CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(a.Platform,',') WHERE VALUE <> '' ) d  

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (@Threshold) c
		SET isFinished = 1
		OUTPUT DELETED.PolicyID, DELETED.Site, DELETED.Currency , DELETED.Platform
		INTO #tempCC(PolicyID, Site,Currency,Platform)
		FROM #CustomerClassSiteManagement_history c
		WHERE isFinished = 0	
			
		IF @@ROWCOUNT = 0 BREAK 

		DELETE a FROM CustomerClassSiteManagement a WITH (ROWLOCK)
		INNER JOIN #tempCC b ON a.PolicyID = b.PolicyID AND a.Site = b.Site AND a.Currency = b.Currency AND a.Platform = b.Platform 

		TRUNCATE TABLE #tempCC	
	END

	 -- Log new updated data  
	 SET @xml = (  
	   SELECT @UserID      AS '@UserID',      
		 @IP       AS '@IP',     
		 COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) AS '@ErrMsg',  
		 COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) AS '@ErrCode',  
		 (  
		  SELECT DISTINCT cs.PolicyID  AS '@PID',  
			cs.Site			AS '@S',  
			c.Currencies    AS '@C' ,  
			p.Platforms		AS '@P'    
		  FROM #CustomerClass AS cs 
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
	 SELECT @EndRun = GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)  

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31911,
				@TrackingValue = '',
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration
END
GO
