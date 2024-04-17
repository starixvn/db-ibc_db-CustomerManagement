/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassNonSportsDel] 
	  @PolicyID			INT			
	, @UserID			INT
	, @AllProducts		VARCHAR(MAX) = '3,8,18,28,40,63,256'
	, @IP				VARCHAR(50)		= ''
	, @IsTest			TINYINT	
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

	Example: NAP_LM_CustomerClassNonSportsDel @PolicyID = 15, @AllProducts = '3,8,18,28,40,63,256', @ErrCode =0, @ErrMsg = '' , @IP = '11.12.11.10', @UserID = 6,  @AllProducts = '3,8,18,28,40,63,256',@IsTest = 1
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
		, @OldBitmap	  BINARY(32) = 0x0
		
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassNonSports_History(PolicyID INT, PolicyTitle VARCHAR(500), MaxBet INT, Enable BIT,IsTest TINYINT, LastModifiedUser INT, LastModifiedTime DATETIME)

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassNonSports a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	
	-- Conver Products string to Products binary
	SELECT @OldBitmap = Products FROM CustomerClassNonSports a WITH(NOLOCK) WHERE PolicyID = @PolicyID
	SELECT @Products_Old = (SELECT STRING_AGG(CAST(ProductID AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY ProductID)
							FROM( SELECT ProductID, Offer FROM dbo.f_GetValueBitmap_multiple(@OldBitmap, @AllProducts) ) cc
							WHERE Offer = 1) 
	-- End Cover
	
	SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
									WITHIN GROUP (ORDER BY CustomerClass)
								FROM( SELECT DISTINCT CustomerClass
								FROM CustomerClassNonSportsDetail  WITH(NOLOCK)
								WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
								
	SELECT @Sites_Old = (SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY SiteID)
							FROM(	SELECT DISTINCT SiteID
							FROM CustomerClassNonSportsDetail WITH(NOLOCK)
							WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
	UPDATE a	
	SET   a.[isDeleted] = 1
		, a.[RepUpdateTime]=sysdatetime()
	OUTPUT	deleted.PolicyTitle 				
		,	deleted.MaxBet	
		,	deleted.Enable	
		,	deleted.IsTest
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
	INTO #CustomerClassNonSports_History(PolicyTitle  				
			 ,	MaxBet 	
			 ,	Enable	
			 ,	IsTest
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime )
	FROM CustomerClassNonSports a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID AND isDeleted = 0

	UPDATE a	
	SET   a.[isDeleted] = 1
		, a.[RepUpdateTime]=sysdatetime()
	FROM CustomerClassNonSportsDetail a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID AND isDeleted = 0

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

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31917,
				@TrackingValue = NULL,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassNonSports_History
END
GO
