/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_CustomerClassSpreadIns] 
	  @PolicyID			INT	OUTPUT
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
	, @LeagueGroups		VARCHAR(MAX)	= ''
	, @IsLive			SMALLINT
	, @Type				SMALLINT		
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0	 OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= '' OUTPUT
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
		- 20250121@Winfred: [NAP CM] Scale Out DBCUST - Apply Inhouse replication for Customer Class[Redmine: #214119]
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

	Param's Explanation:
	* @Sites:   "0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Currencies : 0 : All
	* @Platforms : "0 : All
					1 : Desktop
					2 : Mobile
					3 : APP
					4 : Oddsfeed
					5 : DirectAPI"
	* @LeagueGroupIDs : "-1 : All"
	* @IsLive : "0 : Non Live
				 1 : Live
				 2 : All"
	* @Type : "1: Spead
			   2: Peak Hour Spead"

	Example: NAP_CM_CustomerClassSpreadIns @PolicyID = 0, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305', @SportType = 1,
	@Sites = '1,2,3,4', @Currencies = '13,2,45,6', @Platforms = '2,3,4', @Spread = 2.5, @Enable = 1 ,
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
		, @xml			  XML
		, @ActionID		  INT
	
	SELECT @StartRun	= GETDATE()

	CREATE TABLE #CCSpreadDetail(PolicyID INT, SiteID INT, Currency INT, Platform TINYINT, SportType SMALLINT, ID INT, IsFinished BIT DEFAULT(0))
	CREATE TABLE #CCSpreadDetail_temp(PolicyID INT, SiteID INT, Currency INT, Platform TINYINT, SportType SMALLINT, ID INT)

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassSpread a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 102 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	

	IF ISNULL(@PolicyTitle, '') = '' OR ISNULL(@CustomerClasses ,'') = '' OR ISNULL(@Sites ,'') = '' OR ISNULL(@Currencies ,'') = '' OR ISNULL(@Platforms ,'') = '' OR ISNULL(@SportType, '') = ''
	BEGIN
		SELECT @ErrCode = 103 , @ErrMsg = 'Missing Required field' 
		RETURN
	END	
	
	IF ISNULL(@Spread ,0) < 0 OR ISNULL(@Spread ,0) > 0.5
	BEGIN
		SELECT @ErrCode = 104 , @ErrMsg = 'Please input a value between [0:0.5]' 
		RETURN
	END	

	INSERT INTO CustomerClassSpread(
 		  PolicyTitle 	
		, Spread 		
		, Enable 	
		, IsTest
		, LastModifiedUser
		, LastModifiedTime
		, IsLive
		, Type
		, RepUpdateTime
	)	
	SELECT
		 @PolicyTitle 
		,@Spread 					    
		,@Enable 					
		,@IsTest
		,@UserID
		,GETDATE()
		,@IsLive
		,@Type
		,[dbo].[f_GetDateTime2]()

	SET @PolicyID = SCOPE_IDENTITY()
				
	INSERT INTO CustomerClassSpreadClass(PolicyID, CustomerClass, RepUpdateTime, ID)	
	SELECT @PolicyID AS PolicyID, VALUE AS CustomerClass ,[dbo].[f_GetDateTime2]() 
		  ,ROW_NUMBER() OVER(ORDER BY VALUE) ID
	FROM STRING_SPLIT(@CustomerClasses,',') 
	WHERE VALUE <> '' 

	INSERT INTO #CCSpreadDetail(PolicyID, SiteID, Currency, Platform, SportType, ID)
	SELECT @PolicyID AS PolicyID, s.VALUE AS SiteID , c.Currency, p.Platform,  @SportType AS SportType, ROW_NUMBER() OVER(ORDER BY VALUE) ID
	FROM STRING_SPLIT(@Sites,',') s   
		CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(@Currencies,',') WHERE VALUE <> '' ) c  
		CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(@Platforms,',') WHERE VALUE <> '' ) p
	WHERE s.VALUE <> '' 

	IF @Type = 2
	BEGIN
		INSERT INTO CustomerClassSpreadLeagueGroup(PolicyID, LeagueGroupID, ID, RepUpdateTime)	
		SELECT @PolicyID AS PolicyID, VALUE AS LeagueGroupID, 
			   ROW_NUMBER() OVER(ORDER BY VALUE) ID, [dbo].[f_GetDateTime2]() AS RepUpdateTime
		FROM STRING_SPLIT(@LeagueGroups,',') 
		WHERE VALUE <> '' 
	END
	
	WHILE 0 = 0
	BEGIN
		TRUNCATE TABLE #CCSpreadDetail_temp

		UPDATE TOP(2000) #CCSpreadDetail
		SET	isFinished = 1
		OUTPUT	DELETED.PolicyID, DELETED.SiteID, DELETED.Currency, DELETED.Platform, DELETED.SportType, DELETED.ID
		INTO	#CCSpreadDetail_temp (PolicyID, SiteID, Currency, Platform, SportType, ID)
		WHERE	isFinished = 0

		IF	@@ROWCOUNT = 0
			BREAK

		INSERT INTO CustomerClassSpreadDetail(PolicyID, SiteID, Currency, Platform, SportType, RepUpdateTime, ID)
		SELECT PolicyID, SiteID, Currency, Platform, SportType, [dbo].[f_GetDateTime2](), ID
		FROM #CCSpreadDetail_temp	
	END

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					@PolicyTitle			AS '@PolicyTitle',					
					@CustomerClasses		AS '@CustomerClasses',
					@Sites					AS '@Sites',					
					@Currencies				AS '@Currencies',							
					@Platforms				AS '@Platforms',
					@SportType				AS '@SportType',
					@Spread					AS '@Spread',		
					@LeagueGroups			AS '@LeagueGroups',	
					@IsLive					AS '@IsLive',					
					@Enable					AS '@Enable',						
					@IsTest					AS '@IsTest',					
					@Type					AS '@Type',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	IF @Type = 1 
	BEGIN
		SET @ActionID =  31910 
	END
	ELSE
	BEGIN
		SET @ActionID =  31924 
	END

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = @ActionID,
				@TrackingValue = @LogSPData,
				@duration = @Duration

	DROP TABLE #CCSpreadDetail, #CCSpreadDetail_temp
END
GO
