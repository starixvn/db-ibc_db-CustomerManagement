/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
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
		- 20231101@Winfred: [NAP CM] Customer Class - Support to delete settings [RedmineID: #188590]  

	Param's Explanation:
	* @PolicySites:
		'<ROOT><r PolicyID = "1" Site = "6777777"/> 
			   <r PolicyID = "2" Site = "2222222"/>
		</ROOT>'

	Example: NAP_LM_CustomerClassPolicySiteDel @PolicySites ='<ROOT><r PolicyID="1" Site="6777777"/> 
		<r PolicyID="2" Site="2222222"/> </ROOT>' ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;   
   
	 DECLARE @StartRun   DATETIME  
	  , @EndRun    DATETIME  
	  , @Duration    INT  
	  , @iDoc     INT  
	  , @logSpData_Old  NVARCHAR(MAX)  
	  , @xml     XML  
   
	 --Check if XML is null or empty  
	 IF @PolicySites IS NULL OR @PolicySites = ''  
	  RETURN  
  
	 CREATE TABLE #CustomerClassSiteManagement_history( PolicyID INT, Site NVARCHAR(50), Currency TINYINT,   
		   Platform TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME)  
	 CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(50))  
  
	 BEGIN TRY  
	  EXECUTE sp_xml_preparedocument @iDoc OUTPUT, @PolicySites;  
  
	  INSERT INTO #CustomerClass (PolicyID , Site )  
	  SELECT CAST(Data.PolicyID AS INT) AS PolicyID , Data.Site     
	  FROM OPENXML (@iDoc, '/ROOT/r', 1)   
	  WITH (  
		PolicyID  VARCHAR(20),             
		Site     NVARCHAR(MAX)  
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
	 SELECT a.PolicyID, a.Site, b.Currency, b.Platform
	 FROM #CustomerClass a  
		INNER JOIN CustomerClassSiteManagement b WITH(NOLOCK) ON a.PolicyID = b.PolicyID AND a.Site = b.site
	 
	 DELETE a 
	 FROM CustomerClassSiteManagement a   
		 INNER JOIN #CustomerClass b WITH(NOLOCK) ON a.PolicyID = b.PolicyID AND a.Site = b.site
  
	 -- Log new updated data  
	 SET @xml = (  
	   SELECT @UserID      AS '@UserID',      
		 @IP       AS '@IP',     
		 COALESCE(CAST(@ErrMsg AS VARCHAR(400)),SPACE(1)) AS '@ErrMsg',  
		 COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) AS '@ErrCode',  
		 (  
		  SELECT DISTINCT cs.PolicyID  AS '@PID',  
			cs.Site     AS '@S',  
			c.Currencies    AS '@C' ,  
			p.Platforms    AS '@P'    
		  FROM #CustomerClassSiteManagement_history AS cs   
			CROSS APPLY(
					SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
					FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
						FROM #CustomerClassSiteManagement_history WITH(NOLOCK)
						WHERE PolicyID = cs.PolicyID AND cs.Site = Site) mis
					) p
			CROSS APPLY(
					SELECT STRING_AGG(Currency, ',') WITHIN GROUP (ORDER BY Currency)  AS Currencies
					FROM (SELECT DISTINCT CAST(Currency AS VARCHAR(20)) AS Currency
						FROM #CustomerClassSiteManagement_history WITH(NOLOCK)
						WHERE PolicyID = cs.PolicyID AND cs.Site = Site) mis
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
