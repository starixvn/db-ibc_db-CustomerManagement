/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSpreadUpd] 
	  @PolicyID			INT						 
	, @PolicyTitle 		VARCHAR(500)
	, @CustomerClasses 	VARCHAR(MAX)
	, @SportType		SMALLINT
	, @Sites 			VARCHAR(MAX)
	, @Currencies 		VARCHAR(MAX)
	, @Platforms 		VARCHAR(MAX)
	, @Spread 			DECIMAL(4,2)
	, @Enable			BIT
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
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

	Param's Explanation: 
	* @Sites:  "0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Currencies : 0 : All
	* @Platforms : "0 : All
					1 : Desktop
					2 : Mobile
					3 : APP
					4 : Oddsfeed
					5 : DirectAPI"

	Example: NAP_LM_CustomerClassSpreadUpd @PolicyID = 0, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305', @SportType = 1,
	@Sites = '1,2,3,4,5', @Currencies = '13,2,45,6', @Platforms = '2,3,4', @Spread = 2.5, @Enable = 1 ,
	@ErrCode =0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @iDoc			  INT
		, @RuleID		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			  XML
		, @CustomerClasses_Old VARCHAR(MAX) = ''
		, @Sites_Old VARCHAR(MAX)= ''
		, @Currencies_Old VARCHAR(MAX)= ''
		, @Platforms_Old VARCHAR(MAX)= ''
		, @SportType_Old SMALLINT
		, @LastModifiedTime DATETIME
	
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassSpread_History(PolicyID INT, PolicyTitle VARCHAR(500), Spread DECIMAL(4,2), Enable BIT,IsTest TINYINT, LastModifiedUser INT, LastModifiedTime DATETIME)
	CREATE TABLE #CustomerClassSpreadClass_History(PolicyID INT, CustomerClass smallint)
	CREATE TABLE #CustomerClassSpreadDetail_History(PolicyID INT, SiteID INT, Currency INT, Platform TINYINT, SportType SMALLINT)
	
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassSpread a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	
	
	IF ISNULL(@Spread ,0) < 0 OR ISNULL(@Spread ,0) > 0.5
	BEGIN
		SELECT @ErrCode = 104 , @ErrMsg = 'Please input a value between [0:0.5]' 
		RETURN
	END


	UPDATE a	
	SET a.PolicyTitle 		= @PolicyTitle 
		,a.Spread = @Spread
		,a.Enable = @Enable
		,a.IsTest = @IsTest
		,a.LastModifiedUser = @UserID
		,a.LastModifiedTime = @LastModifiedTime
	OUTPUT	deleted.PolicyTitle 	
		,	deleted.Spread		
		,	deleted.Enable	
		,	deleted.IsTest
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
	INTO #CustomerClassSpread_History(PolicyTitle  	
			 ,	Spread 	
			 ,	Enable	
			 ,	IsTest
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime )
	FROM CustomerClassSpread a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID
	
	IF ISNULL(@CustomerClasses,'') <> ''
	BEGIN
		DELETE FROM CustomerClassSpreadClass WITH (ROWLOCK)
		OUTPUT	deleted.PolicyID,	deleted.CustomerClass 
		INTO #CustomerClassSpreadClass_History(PolicyID, CustomerClass )
		WHERE PolicyID = @PolicyID

		INSERT INTO CustomerClassSpreadClass(PolicyID ,  CustomerClass)	
		SELECT @PolicyID AS PolicyID, VALUE AS CustomerClass 
		FROM STRING_SPLIT(@CustomerClasses,',') WHERE VALUE <> ''

		SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
										WITHIN GROUP (ORDER BY CustomerClass)
									FROM( SELECT DISTINCT CustomerClass
									FROM #CustomerClassSpreadClass_History  WITH(NOLOCK))cc) 
	END

	IF ISNULL(@Currencies,'') <> '' AND  ISNULL(@Sites,'') <> '' AND  ISNULL(@Platforms,'') <> ''  
	BEGIN
		DELETE FROM CustomerClassSpreadDetail WITH (ROWLOCK)
		OUTPUT	deleted.PolicyID, deleted.SiteID, deleted.Currency, deleted.Platform, deleted.SportType 
		INTO #CustomerClassSpreadDetail_History(PolicyID, SiteID, Currency, Platform, SportType)
		WHERE PolicyID = @PolicyID

		INSERT INTO CustomerClassSpreadDetail(PolicyID, SiteID, Currency, Platform, SportType)	
		SELECT @PolicyID AS PolicyID, s.VALUE AS SiteID , c.Currency, p.Platform,  @SportType AS SportType
		FROM STRING_SPLIT(@Sites,',') s   
		  CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(@Currencies,',') WHERE VALUE <> '' ) c  
		  CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(@Platforms,',') WHERE VALUE <> '' ) p
		WHERE s.VALUE <> '' 

		SELECT TOP 1 @SportType_Old = SportType 
		FROM #CustomerClassSpreadDetail_History WITH (NOLOCK)

		SELECT @Currencies_Old = (SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY Currency)
								FROM(	SELECT DISTINCT Currency
								FROM #CustomerClassSpreadDetail_History  WITH(NOLOCK))cc) 
								
		SELECT @Sites_Old = (SELECT STRING_AGG(CAST(SiteID AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY SiteID)
								FROM(	SELECT DISTINCT SiteID
								FROM #CustomerClassSpreadDetail_History  WITH(NOLOCK))cc) 
								
		SELECT @Platforms_Old = (SELECT STRING_AGG(CAST(Platform AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY Platform)
								FROM(	SELECT DISTINCT Platform
								FROM #CustomerClassSpreadDetail_History  WITH(NOLOCK))cc) 
	END


	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					PolicyTitle				AS '@PolicyTitle',					
					@CustomerClasses_Old	AS '@CustomerClasses',
					@Sites_Old				AS '@Sites',					
					@Currencies_Old			AS '@Currencies',							
					@Platforms_Old			AS '@Platforms',
					@SportType_Old			AS '@SportType',
					Spread					AS '@Spread',						
					Enable					AS '@Enable',						
					IsTest					AS '@IsTest',	
					CONVERT(VARCHAR(10), LastModifiedTime, 120) AS '@LastModifiedTime',	
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FROM #CustomerClassSpread_History
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
					@SportType				AS '@SportType',
					@Sites					AS '@Sites',					
					@Currencies				AS '@Currencies',							
					@Platforms				AS '@Platforms',						
					@Spread					AS '@Spread',	
					CASE WHEN @Enable = 1 
						THEN 0 ELSE 1 END		AS '@Enable',
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
				@ActionID = 31909,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassSpread_History,
				#CustomerClassSpreadClass_History,
				#CustomerClassSpreadDetail_History				
END
GO
