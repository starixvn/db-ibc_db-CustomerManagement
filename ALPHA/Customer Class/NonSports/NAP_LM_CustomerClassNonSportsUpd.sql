/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassNonSportsUpd] 
	  @PolicyID			INT						 
	, @PolicyTitle 		VARCHAR(500)
	, @CustomerClasses 	VARCHAR(MAX)
	, @Sites 			VARCHAR(MAX)
	, @Products			VARCHAR(MAX)
	, @AllProducts		VARCHAR(MAX) = '3,8,18,28,40,63,256'
	, @MaxBet			INT
	, @Enable			BIT
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Support for Non-Sports
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231002@Winfred: [NAP CM] Customer Class - Support for Non-Sports [RedmineID: #186116] 

	Param's Explanation: 
	* @Sites:  " 0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Products : "3  : Number Game
					8  : RNG Keno
					18 : RNG Slot
					28 : Lottery
					40 : Table Game
					63 : Sports Lottery
					256  : All"

	Example: NAP_LM_CustomerClassNonSportsUpd @PolicyID = 10, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305' @AllProducts = '3,8,18,28,40,63,256', 
	@Sites = 'Inbet,HonorW,Abcasino,Lexibet', @Products = '3,8,28,40', @MaxBet = 15000, @Enable = 1 ,
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
		, @Products_Old VARCHAR(MAX)= ''
		, @LastModifiedTime DATETIME
		, @OldBitmap	BINARY(32) = 0x0
		, @NewBitmap	BINARY(32) = 0x0
	
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassNonSports_History(PolicyID INT, PolicyTitle VARCHAR(500), MaxBet INT, Products VARCHAR(MAX), Enable BIT,IsTest TINYINT, LastModifiedUser INT, LastModifiedTime DATETIME)
	CREATE TABLE #CustomerClassNonSportsDetail_New(PolicyID INT, SiteID INT, CustomerClass SMALLINT)
	CREATE CLUSTERED INDEX CIX_CustomerClassNonSports ON #CustomerClassNonSportsDetail_New(PolicyID, SiteID, CustomerClass)

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassNonSports a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	
	-- Conver Products string to Products binary
	SELECT @OldBitmap = Products FROM CustomerClassNonSports a WITH(NOLOCK) WHERE PolicyID = @PolicyID
	SELECT @Products_Old = (SELECT STRING_AGG(CAST(ProductID AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY ProductID)
							FROM( SELECT ProductID, Offer FROM dbo.f_GetValueBitmap_multiple(@OldBitmap, @AllProducts) ) cc
							WHERE Offer = 1) 
	
	SELECT @NewBitmap = (SELECT bitmap FROM dbo.f_SetValueBitmap_multiple(@NewBitmap,@Products))
	-- End Cover
	UPDATE a	
	SET a.PolicyTitle = @PolicyTitle 
		,a.MaxBet = @MaxBet
		,a.Products = @NewBitmap
		,a.Enable = @Enable
		,a.IsTest = @IsTest
		,a.LastModifiedUser = @UserID
		,a.LastModifiedTime = @LastModifiedTime
		,a.[RepUpdateTime]=sysdatetime()
	OUTPUT	deleted.PolicyTitle 				
		,	deleted.MaxBet		
		,	@Products
		,	deleted.Enable	
		,	deleted.IsTest
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
	INTO #CustomerClassNonSports_History(PolicyTitle  				
			 ,	MaxBet 	
			 , Products
			 ,	Enable	
			 ,	IsTest
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime )
	FROM CustomerClassNonSports a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID
	
	IF ISNULL(@CustomerClasses,'') <> '' AND  ISNULL(@Sites,'') <> ''   
	BEGIN
		INSERT INTO #CustomerClassNonSportsDetail_New(PolicyID, SiteID, CustomerClass)	
		SELECT @PolicyID AS PolicyID, s.VALUE AS SiteID , c.CustomerClass
		FROM STRING_SPLIT(@Sites,',') s   
		  CROSS APPLY ( SELECT VALUE AS CustomerClass FROM STRING_SPLIT(@CustomerClasses,',') WHERE VALUE <> '' ) c  
		WHERE s.VALUE <> '' 

		SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY CustomerClass)
								FROM(	SELECT DISTINCT CustomerClass
										FROM CustomerClassNonSportsDetail  WITH(NOLOCK)
										WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
								
		SELECT @Sites_Old = (SELECT STRING_AGG(CAST(SiteID AS VARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY SiteID)
								FROM(	SELECT DISTINCT SiteID
										FROM CustomerClassNonSportsDetail  WITH(NOLOCK)
										WHERE PolicyID = @PolicyID AND isDeleted = 0
										)cc) 
		-- Delete data new Update
		UPDATE a	
		SET   a.[isDeleted] =  CASE WHEN b.PolicyID IS NULL THEN 1 ELSE 0 END
			, a.[RepUpdateTime]=sysdatetime()
		FROM CustomerClassNonSportsDetail a WITH (ROWLOCK, UPDLOCK)
			OUTER APPLY (SELECT TOP 1 PolicyID FROM #CustomerClassNonSportsDetail_New WITH(NOLOCK) WHERE PolicyID = a.PolicyID AND SiteID = a.SiteID AND CustomerClass = a.CustomerClass) b
		WHERE a.PolicyID = @PolicyID 
		
		INSERT INTO CustomerClassNonSportsDetail(PolicyID, SiteID, CustomerClass)	
		SELECT @PolicyID, a.SiteID , a.CustomerClass
		FROM #CustomerClassNonSportsDetail_New a   
		 WHERE NOT EXISTS(SELECT TOP 1 1 FROM CustomerClassNonSportsDetail WITH(NOLOCK) WHERE PolicyID = a.PolicyID AND SiteID = a.SiteID AND CustomerClass = a.CustomerClass ) 
	END

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					PolicyTitle				AS '@PolicyTitle',					
					@CustomerClasses_Old	AS '@CustomerClasses',					
					@Sites_Old				AS '@Sites',					
					@Products_Old			AS '@Products',							
					MaxBet					AS '@MaxBet',						
					Enable					AS '@Enable',						
					IsTest					AS '@IsTest',	
					CONVERT(VARCHAR(10), LastModifiedTime, 120) AS '@LastModifiedTime',	
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FROM #CustomerClassNonSports_History
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					@PolicyTitle			AS '@PolicyTitle',					
					@CustomerClasses			AS '@CustomerClasses',					
					@Sites					AS '@Sites',					
					@Products				AS '@Products',						
					@MaxBet					AS '@MaxBet',	
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
				@ActionID = 31919,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassNonSports_History
	DROP TABLE #CustomerClassNonSportsDetail_New
END
GO
