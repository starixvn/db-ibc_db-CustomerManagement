/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassUtilityOfferUpd] 
	  @PolicyID			INT						 
	, @PolicyTitle 		VARCHAR(500)
	, @CustomerClasses 	VARCHAR(MAX)
	, @Currencies 		VARCHAR(MAX)
	, @Sites 			VARCHAR(MAX)
	, @UtilityOffering	VARCHAR(500)
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
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
	* @Sites:  " 0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Currencies : 0 : All
	* @UtilityOffering : "1  : UtilityOffering"

	Example: NAP_LM_CustomerClassUtilityOfferUpd @PolicyID = 10, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305', @Currencies = '13,2,45,6', 
	@Sites = '20,21,22,23,24,25,26,27,28,29', @UtilityOffering = '3,8,1,5',
	@ErrCode =0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			  XML
		, @CustomerClasses_Old VARCHAR(MAX) = ''
		, @Sites_Old VARCHAR(MAX)= ''
		, @Currency_Old VARCHAR(MAX)= ''
		, @UtilityOffering_Old	VARCHAR(500)
		, @LastModifiedTime DATETIME
		, @VewUtilityOffering SMALLINT
		, @Threshold	INT = 5000
		, @RepUpdateTime datetime2
	
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassUtilityOffer_History(PolicyID INT, PolicyTitle VARCHAR(500), IsTest TINYINT, LastModifiedUser INT, LastModifiedTime DATETIME)
	CREATE TABLE #CustomerClassUtilityOfferDetail_New(PolicyID INT, SiteID INT, CustomerClass SMALLINT, Currency INT)
	CREATE TABLE #TempCCDetail(PolicyID INT, SiteID INT, CustomerClass SMALLINT, Currency INT)
	CREATE CLUSTERED INDEX CIX_CustomerClassUtilityOfferDetail ON #CustomerClassUtilityOfferDetail_New(PolicyID, SiteID, CustomerClass, Currency)
	CREATE CLUSTERED INDEX CIX_TempCCDetail ON #TempCCDetail(PolicyID, SiteID, CustomerClass, Currency)

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassUtilityOffer a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	
	SET @RepUpdateTime = sysdatetime()
	-- Conver Products string to Products smallint
	SET @VewUtilityOffering = (SELECT VALUE FROM dbo.f_OfferValueToSmallInt(@UtilityOffering))

	SET @UtilityOffering_Old = ( SELECT s.UtilityOffering
								FROM CustomerClassUtilityOffer a WITH(NOLOCK)
									CROSS APPLY	(SELECT VALUE AS UtilityOffering
												FROM dbo.f_SmallIntToOfferValue(a.UtilityOffering)) s
								WHERE a.PolicyID = @PolicyID )
	-- End Cover
	UPDATE a	
	SET a.PolicyTitle = @PolicyTitle 
		,a.UtilityOffering = @VewUtilityOffering
		,a.IsTest = @IsTest
		,a.LastModifiedUser = @UserID
		,a.LastModifiedTime = @LastModifiedTime
		,a.[RepUpdateTime]=@RepUpdateTime
	OUTPUT	deleted.PolicyTitle 	
		,	deleted.IsTest
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
	INTO #CustomerClassUtilityOffer_History(PolicyTitle 
			 ,	IsTest
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime )
	FROM CustomerClassUtilityOffer a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID
	
	IF ISNULL(@CustomerClasses,'') <> '' AND  ISNULL(@Sites,'') <> '' AND  ISNULL(@Currencies,'') <> ''   
	BEGIN
		INSERT INTO #CustomerClassUtilityOfferDetail_New(PolicyID, SiteID, CustomerClass, Currency)	
		SELECT @PolicyID AS PolicyID, s.VALUE AS SiteID , c.CustomerClass, d.currency
		FROM STRING_SPLIT(@Sites,',') s   
		  CROSS APPLY ( SELECT VALUE AS CustomerClass FROM STRING_SPLIT(@CustomerClasses,',') WHERE VALUE <> '' ) c 
		  CROSS APPLY ( SELECT VALUE AS currency FROM STRING_SPLIT(@Currencies,',') WHERE VALUE <> '' ) d   
		WHERE s.VALUE <> '' 

		SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY CustomerClass)
								FROM(	SELECT DISTINCT CustomerClass
										FROM CustomerClassUtilityOfferDetail  WITH(NOLOCK)
										WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
								
		SELECT @Sites_Old = (SELECT STRING_AGG(CAST(SiteID AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY SiteID)
								FROM(	SELECT DISTINCT SiteID
										FROM CustomerClassUtilityOfferDetail  WITH(NOLOCK)
										WHERE PolicyID = @PolicyID AND isDeleted = 0
										)cc) 
								
		SELECT @Currency_Old = (SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY Currency)
								FROM(	SELECT DISTINCT Currency
										FROM CustomerClassUtilityOfferDetail  WITH(NOLOCK)
										WHERE PolicyID = @PolicyID AND isDeleted = 0
										)cc) 
		UPDATE a	
		SET   a.[isDeleted] = 1
			, a.[RepUpdateTime]=@RepUpdateTime
		FROM CustomerClassUtilityOfferDetail a WITH (ROWLOCK, UPDLOCK)
				LEFT JOIN #CustomerClassUtilityOfferDetail_New c ON c.Currency = a.Currency AND c.CustomerClass = a.CustomerClass AND c.SiteID = a.SiteID AND c.PolicyID = a.PolicyID
		WHERE a.PolicyID = @PolicyID AND isDeleted = 0  AND c.PolicyID IS NULL
		
		WHILE (0 = 0)
		BEGIN				
			DELETE TOP (@Threshold) c 
			OUTPUT DELETED.PolicyID, DELETED.SiteID, DELETED.CustomerClass, DELETED.Currency INTO #TempCCDetail(PolicyID, SiteID, CustomerClass,Currency)
			FROM #CustomerClassUtilityOfferDetail_New c 
		
			IF @@ROWCOUNT = 0 BREAK
			-- Delete data new Update

			UPDATE a	
			SET   a.[isDeleted] = 0
				, a.[RepUpdateTime]=@RepUpdateTime
			FROM CustomerClassUtilityOfferDetail a WITH (ROWLOCK, UPDLOCK)
			WHERE a.PolicyID = @PolicyID AND isDeleted = 1 AND 
			 EXISTS(SELECT TOP 1 1 FROM #TempCCDetail WITH(NOLOCK) WHERE Currency = a.Currency AND CustomerClass = a.CustomerClass AND SiteID = a.SiteID AND
			 PolicyID = a.PolicyID ) 
		
			INSERT INTO CustomerClassUtilityOfferDetail(PolicyID, SiteID, CustomerClass,Currency)	
			SELECT a.PolicyID, a.SiteID , a.CustomerClass, a.Currency
			FROM #TempCCDetail a   
			 WHERE NOT EXISTS(SELECT TOP 1 1 FROM CustomerClassUtilityOfferDetail WITH(NOLOCK) WHERE Currency = a.Currency AND CustomerClass = a.CustomerClass AND SiteID = a.SiteID AND PolicyID = a.PolicyID  ) 

			 TRUNCATE TABLE #TempCCDetail	
		END
	END

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					PolicyTitle				AS '@PolicyTitle',				
					@CustomerClasses_Old	AS '@CustomerClasses',					
					@Sites_Old				AS '@Sites',										
					@UtilityOffering_Old	AS '@UtilityOffering',						
					@Currency_Old			AS '@Currencies',						
					IsTest					AS '@IsTest',	
					CONVERT(VARCHAR(10), LastModifiedTime, 120) AS '@LastModifiedTime',	
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FROM #CustomerClassUtilityOffer_History
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					@PolicyTitle			AS '@PolicyTitle',				
					@CustomerClasses		AS '@CustomerClasses',					
					@Sites					AS '@Sites',										
					@UtilityOffering		AS '@UtilityOffering',						
					@Currencies				AS '@Currencies',		
					@IsTest						AS '@IsTest',	
					CONVERT(VARCHAR(10), @LastModifiedTime, 120) AS '@LastModifiedTime',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31913,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassUtilityOffer_History
	DROP TABLE #CustomerClassUtilityOfferDetail_New
	DROP TABLE #TempCCDetail
END
GO
