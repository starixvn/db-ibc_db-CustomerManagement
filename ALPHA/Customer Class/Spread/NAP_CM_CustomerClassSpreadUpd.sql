/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_CustomerClassSpreadUpd] 
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
	, @LeagueGroups		VARCHAR(MAX)	= ''
	, @IsLive			SMALLINT
	, @Type				SMALLINT =	 1
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
		- 20250121@Winfred: [NAP CM] Scale Out DBCUST - Apply Inhouse replication for Customer Class[Redmine: #214119]
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

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
	* @LeagueGroupIDs : "-1 : All"
	* @IsLive : "0 : Non Live
				1 : Live
				2 : All"
	* @Type : "1: Spead
			  2: Peak Hour Spead"

	Example: NAP_CM_CustomerClassSpreadUpd @PolicyID = 0, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305', @SportType = 1,
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
		, @Batch		  SMALLINT = 2000
		, @LeagueGroups_Old VARCHAR(MAX)= ''
		, @ActionID		  INT
	
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassSpread_History(PolicyID INT, PolicyTitle VARCHAR(500), Spread DECIMAL(4,2), Enable BIT,IsTest TINYINT, IsLive SMALLINT, LastModifiedUser INT, LastModifiedTime DATETIME)
	CREATE TABLE #CustomerClassSpreadClass_History(PolicyID INT, CustomerClass SMALLINT)
	CREATE TABLE #CustomerClassSpreadDetail_History(PolicyID INT, SiteID INT, Currency INT, Platform TINYINT, SportType SMALLINT, IsFinished BIT DEFAULT(0))
	CREATE TABLE #CCSpreadDetail(PolicyID INT, SiteID INT, Currency INT, Platform TINYINT, SportType SMALLINT, ID INT, IsFinished BIT DEFAULT(0))
	CREATE TABLE #CCSpreadDetail_temp(PolicyID INT, SiteID INT, Currency INT, Platform TINYINT, SportType SMALLINT, ID INT)
	CREATE TABLE #CustomerClassSpreadLeague_History(PolicyID INT, LeagueGroupID SMALLINT)
	
	IF EXISTS(SELECT TOP 1 1 FROM CustomerClassSpread a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
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
		,a.IsLive = @IsLive
		,a.LastModifiedUser = @UserID
		,a.LastModifiedTime = @LastModifiedTime
		,a.RepUpdateTime = [dbo].[f_GetDateTime2]()
	OUTPUT	deleted.PolicyTitle 	
		,	deleted.Spread		
		,	deleted.Enable	
		,	deleted.IsTest
		,	deleted.IsLive
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
	INTO #CustomerClassSpread_History(PolicyTitle  	
			 ,	Spread 	
			 ,	Enable	
			 ,	IsTest
			 ,	IsLive
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime )
	FROM CustomerClassSpread a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID
	
	IF ISNULL(@CustomerClasses,'') <> ''
	BEGIN
		INSERT INTO #CustomerClassSpreadClass_History(PolicyID, CustomerClass)
		SELECT PolicyID, CustomerClass
		FROM CustomerClassSpreadClass WITH (NOLOCK)
		WHERE PolicyID = @PolicyID

		DELETE FROM CustomerClassSpreadClass WITH (ROWLOCK)
		OUTPUT	DELETED.PolicyID, DELETED.CustomerClass , [dbo].[f_GetDateTime2]()
		INTO CustomerClassSpreadClass_Del_InHouse(PolicyID, CustomerClass, RepUpdateTime )
		WHERE PolicyID = @PolicyID
	
		INSERT INTO CustomerClassSpreadClass(PolicyID, CustomerClass, RepUpdateTime, ID)	
		SELECT  @PolicyID AS PolicyID, VALUE AS CustomerClass, [dbo].[f_GetDateTime2]()
				, ROW_NUMBER() OVER(ORDER BY VALUE) ID
		FROM STRING_SPLIT(@CustomerClasses,',') WHERE VALUE <> ''

		SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
										WITHIN GROUP (ORDER BY CustomerClass)
									FROM( SELECT DISTINCT CustomerClass
									FROM #CustomerClassSpreadClass_History  WITH(NOLOCK))cc) 
	END
	
	
	IF @Type = 2 AND ISNULL(@LeagueGroups,'') <> ''
	BEGIN
		INSERT INTO #CustomerClassSpreadLeague_History(PolicyID, LeagueGroupID)
		SELECT PolicyID, LeagueGroupID
		FROM CustomerClassSpreadLeagueGroup WITH (NOLOCK)
		WHERE PolicyID = @PolicyID

		DELETE FROM CustomerClassSpreadLeagueGroup WITH (ROWLOCK)
		OUTPUT DELETED.PolicyID, DELETED.LeagueGroupID, [dbo].[f_GetDateTime2]() 
		INTO CustomerClassSpreadLeagueGroup_Del_InHouse(PolicyID, LeagueGroupID, RepUpdateTime)
		WHERE PolicyID = @PolicyID

		INSERT INTO CustomerClassSpreadLeagueGroup(PolicyID, LeagueGroupID, ID, RepUpdateTime)	
		SELECT @PolicyID AS PolicyID, VALUE AS LeagueGroupID, ROW_NUMBER() OVER(ORDER BY VALUE) ID, [dbo].[f_GetDateTime2]() AS RepUpdateTime 
		FROM STRING_SPLIT(@LeagueGroups,',') WHERE VALUE <> ''

		SELECT @LeagueGroups_Old = (SELECT STRING_AGG(CAST(LeagueGroupID AS VARCHAR(MAX)), ',') 
										WITHIN GROUP (ORDER BY LeagueGroupID)
									FROM( SELECT DISTINCT LeagueGroupID
									FROM #CustomerClassSpreadLeague_History  WITH(NOLOCK))cc) 
	END

	IF ISNULL(@Currencies,'') <> '' AND  ISNULL(@Sites,'') <> '' AND  ISNULL(@Platforms,'') <> ''  
	BEGIN

		INSERT INTO #CustomerClassSpreadDetail_History(PolicyID, SiteID, Currency, Platform, SportType)
		SELECT PolicyID, SiteID, Currency, Platform, SportType
		FROM CustomerClassSpreadDetail WITH (NOLOCK)
		WHERE PolicyID = @PolicyID

		WHILE 0 = 0
		BEGIN
			TRUNCATE TABLE #CCSpreadDetail_temp

			UPDATE TOP(@Batch) #CustomerClassSpreadDetail_History
			SET	isFinished = 1
			OUTPUT	DELETED.PolicyID, DELETED.SiteID, DELETED.Currency, DELETED.Platform, DELETED.SportType
			INTO	#CCSpreadDetail_temp (PolicyID, SiteID, Currency, Platform, SportType)
			WHERE	isFinished = 0

			IF	@@ROWCOUNT = 0
				BREAK
			
			DELETE cg
			OUTPUT	DELETED.PolicyID, DELETED.SiteID, DELETED.Currency, DELETED.Platform, DELETED.SportType , [dbo].[f_GetDateTime2]()
			INTO CustomerClassSpreadDetail_Del_InHouse(PolicyID, SiteID, Currency, Platform, SportType, RepUpdateTime)
			FROM CustomerClassSpreadDetail cg WITH (ROWLOCK)
				INNER JOIN #CCSpreadDetail_temp t ON cg.PolicyID = t.PolicyID AND cg.SiteID = t.SiteID 
												 AND cg.Currency = t.Currency AND cg.Platform = t.Platform AND cg.SportType = t.SportType
		END

		INSERT INTO #CCSpreadDetail(PolicyID, SiteID, Currency, Platform, SportType, ID)
		SELECT @PolicyID AS PolicyID, s.VALUE AS SiteID , c.Currency, p.Platform,  @SportType, ROW_NUMBER() OVER(ORDER BY VALUE) ID
		FROM STRING_SPLIT(@Sites,',') s   
		  CROSS APPLY ( SELECT VALUE AS Currency FROM STRING_SPLIT(@Currencies,',') WHERE VALUE <> '' ) c  
		  CROSS APPLY ( SELECT VALUE AS Platform FROM STRING_SPLIT(@Platforms,',') WHERE VALUE <> '' ) p
		WHERE s.VALUE <> '' 

		WHILE 0 = 0
		BEGIN
			TRUNCATE TABLE #CCSpreadDetail_temp

			UPDATE TOP(@Batch) #CCSpreadDetail
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

		SELECT TOP 1 @SportType_Old = SportType FROM #CustomerClassSpreadDetail_History WITH (NOLOCK)

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
					@LeagueGroups_Old		AS '@LeagueGroups',	
					IsLive					AS '@IsLive',
					Enable					AS '@Enable',						
					IsTest					AS '@IsTest',						
					@Type					AS '@Type',	
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
					@Sites					AS '@Sites',					
					@Currencies				AS '@Currencies',
					@Platforms				AS '@Platforms',		
					@SportType				AS '@SportType',					
					@Spread					AS '@Spread',	
					@LeagueGroups			AS '@LeagueGroups',	
					@IsLive					AS '@IsLive',
					CASE WHEN @Enable = 1 
						THEN 0 ELSE 1 END		AS '@Enable',
					@IsTest						AS '@IsTest',					
					@Type					AS '@Type',		
					CONVERT(VARCHAR(10), @LastModifiedTime, 120) AS '@LastModifiedTime',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	IF @Type = 1 
	BEGIN
		SET @ActionID =  31909 
	END
	ELSE
	BEGIN
		SET @ActionID =  31923 
	END

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = @ActionID,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassSpread_History,
				#CustomerClassSpreadClass_History,
				#CustomerClassSpreadDetail_History,
				#CCSpreadDetail_temp,
				#CCSpreadDetail
END
GO
