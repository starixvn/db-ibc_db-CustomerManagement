/*<info serverAlias="DBACC-bodb02,DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassUtilityOfferIns] 
	  @PolicyID			INT						 OUTPUT
	, @PolicyTitle 		VARCHAR(500)
	, @CustomerClasses 	VARCHAR(MAX)
	, @Currencies 		VARCHAR(MAX)
	, @Sites 			VARCHAR(MAX)
	, @UtilityOffering	VARCHAR(500)
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT				= 0	 OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	 OUTPUT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Allow to offer Parlay Boost on rule setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231002@Winfred: NAP CM Customer Class - Allow to offer Parlay Boost on rule setting [RedmineID: #190607] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297] 

	Param's Explanation:
	* @Sites:  " 0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Currencies : 0 : All
	* @UtilityOffering : "1  : UtilityOffering"

	Example: NAP_LM_CustomerClassUtilityOfferIns @PolicyID = 0, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305', @Currencies = '13,2,45,6', 
		@Sites = '20,21,22,23,24,25,26,27,28,29', @UtilityOffering = '1,2,3,5,8', @ErrCode =0, @ErrMsg = '' ,  
		@IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @xml			  XML
		, @VewUtilityOffering	  SMALLINT
		, @Threshold	INT = 5000
	
	CREATE TABLE #tempCCUtilityOffer(SiteID	INT, Currency INT, CustomerClass SMALLINT)
	CREATE TABLE #tempCC(SiteID	INT, Currency INT, CustomerClass SMALLINT)	

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassUtilityOffer a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 102 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	

	IF ISNULL(@CustomerClasses ,'') = '' OR ISNULL(@Sites ,'') = '' OR ISNULL(@Currencies ,'') = ''  OR ISNULL(@UtilityOffering ,'') = ''
	BEGIN
		SELECT @ErrCode = 103 , @ErrMsg = 'Required field' 
		RETURN
	END	

	INSERT INTO #tempCCUtilityOffer(SiteID, CustomerClass,Currency)
	SELECT s.VALUE AS SiteID , c.CustomerClass , d.Currency
	FROM STRING_SPLIT(@Sites,',') s   
	  CROSS APPLY ( SELECT VALUE AS CustomerClass FROM STRING_SPLIT(@CustomerClasses,',') WHERE VALUE <> '' ) c  
	  CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(@Currencies,',') WHERE VALUE <> '' ) d  
	WHERE s.VALUE <> '' 

	-- Conver Products string to Products smallint
	SET @VewUtilityOffering = (SELECT VALUE FROM dbo.f_OfferValueToSmallInt(@UtilityOffering))
	-- End Cover
	INSERT INTO CustomerClassUtilityOffer (
 		PolicyTitle 	
	,	UtilityOffering
	,	IsTest
	,   LastModifiedUser
	,   LastModifiedTime)	
	SELECT
		@PolicyTitle 	
		,@VewUtilityOffering					
		,@IsTest
		,@UserID
		,GETDATE()
		
	SET @PolicyID = SCOPE_IDENTITY()

	WHILE (0 = 0)
	BEGIN				
		DELETE TOP (@Threshold) c
		OUTPUT DELETED.SiteID, DELETED.CustomerClass, DELETED.Currency 
		INTO #tempCC(SiteID, CustomerClass,Currency)
		FROM #tempCCUtilityOffer c 
		
		IF @@ROWCOUNT = 0 BREAK

		INSERT INTO CustomerClassUtilityOfferDetail(PolicyID, SiteID, CustomerClass,Currency)	
		SELECT @PolicyID AS PolicyID, SiteID , CustomerClass , Currency
		FROM #tempCC 			
				
		TRUNCATE TABLE #tempCC					
	END;

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					@PolicyTitle			AS '@PolicyTitle',				
					@CustomerClasses		AS '@CustomerClasses',					
					@Sites					AS '@Sites',										
					@UtilityOffering		AS '@UtilityOffering',						
					@Currencies				AS '@Currencies',						
					@IsTest					AS '@IsTest',	
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
				@ActionID = 31912,
				@TrackingValue = @LogSPData,
				@duration = @Duration

	DROP TABLE #tempCCUtilityOffer
	DROP TABLE #tempCC
END
GO
