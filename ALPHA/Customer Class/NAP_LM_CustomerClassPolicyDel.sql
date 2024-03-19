/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyDel] 
	  @Policies		VARCHAR(MAX)
	, @UserID		INT
	, @IsTest		TINYINT	
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20231101
	Task : [NAP CM] Support to delete settings [#188590]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231101@Winfred: [NAP CM] Customer Class - Support to delete settings [RedmineID: #188590] 

	Param's Explanation:
	* @RuleIDs: List ID Rule

	Example: NAP_LM_CustomerClassPolicyDel @Policies = '1,2,3,4,5,6,9,7,8,11' , @ErrCode = 0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML
		, @Threshold	INT = 5000
	CREATE TABLE #PolicyTemp(PolicyID INT) 
	INSERT INTO #PolicyTemp(PolicyID)
	SELECT VALUE AS PolicyID FROM STRING_SPLIT(@Policies,',') WHERE VALUE <> ''
	SELECT @StartRun = GETDATE()

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK) 
					CROSS APPLY ( SELECT  TOP 1 PolicyID FROM #PolicyTemp WHERE PolicyID = a.PolicyID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	
	
	CREATE TABLE #CustomerClassSiteManagement_history( PolicyID INT, Site NVARCHAR(50), Currency TINYINT,   
		   Platform TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME, isFinished BIT DEFAULT(0))  
	CREATE TABLE #tempCC(PolicyID INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT)	
	CREATE TABLE #CustomerClassPolicy_History( PolicyID INT PRIMARY KEY, PolicyTitle VARCHAR(500),RuleIDs VARCHAR(MAX),
			SportType SMALLINT, IsTest TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME)
	 CREATE NONCLUSTERED INDEX inx_temp ON #CustomerClassSiteManagement_history(  PolicyID ) INCLUDE ( Currency, Platform, Site ) 
	 CREATE CLUSTERED INDEX inx_tempCC ON #tempCC( PolicyID, Site, Currency, Platform )

	INSERT INTO #CustomerClassPolicy_History( PolicyID, PolicyTitle, SportType, IsTest, RuleIDs, LastModifiedUser, LastModifiedTime)
	SELECT a.PolicyID, a.PolicyTitle, a.SportType, a.IsTest, b.RuleIDs, a.LastModifiedUser, a.LastModifiedTime  
	FROM CustomerClassPolicyManagement a WITH(NOLOCK)
		OUTER APPLY(
				SELECT STRING_AGG(CAST(RuleID AS VARCHAR(20)), ',') WITHIN GROUP (ORDER BY RuleID)  AS RuleIDs
				FROM CustomerClassPolicyRule b WITH(NOLOCK)
					WHERE a.PolicyID = b.PolicyID
			) b (RuleIDs)
		CROSS APPLY ( SELECT TOP 1 PolicyID FROM #PolicyTemp WHERE PolicyID = a.PolicyID ) c
	WHERE a.IsTest <= @IsTest
	
	 INSERT INTO #CustomerClassSiteManagement_history(PolicyID, Site, Currency, Platform)  
	 SELECT a.PolicyID, b.Site, b.Currency, b.Platform
	 FROM #PolicyTemp a  
		INNER JOIN CustomerClassSiteManagement b WITH(NOLOCK) ON a.PolicyID = b.PolicyID

	DELETE a FROM CustomerClassPolicyManagement a WITH (ROWLOCK)
		INNER JOIN #PolicyTemp b ON a.PolicyID = b.PolicyID

	DELETE a FROM CustomerClassPolicyRule a WITH (ROWLOCK)
		INNER JOIN #PolicyTemp b ON a.PolicyID = b.PolicyID

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
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT cs.PolicyID		 AS '@PolicyID',
							cs.PolicyTitle				 AS '@PolicyTitle',
							cs.SportType				 AS '@SportType',
							cs.RuleIDs					 AS '@RuleIDs',
							cs.IsTest					 AS '@IsTest', 
							s.Sites						AS '@S',  
							c.Currencies				AS '@C' ,  
							p.Platforms					AS '@P' , 
							cs.LastModifiedUser			 AS '@LastModifiedUser',
							CONVERT(VARCHAR(10), cs.LastModifiedTime, 120) AS '@LastModifiedTime'
						FROM	#CustomerClassPolicy_History AS cs	
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
						FOR XML PATH('CP'),
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31916,
				@TrackingValue = '',
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassPolicy_History
	DROP TABLE #PolicyTemp
	DROP TABLE #CustomerClassSiteManagement_history
END
GO
