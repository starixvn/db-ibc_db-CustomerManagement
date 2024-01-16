/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassNonSportsIns] 
	  @PolicyID			INT						 OUTPUT
	, @PolicyTitle 		VARCHAR(500)
	, @CustomerClasses 	VARCHAR(MAX)
	, @Sites 			VARCHAR(MAX)
	, @Products			VARCHAR(MAX)
	, @MaxBet			INT
	, @Enable			BIT
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT				= 0	 OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	 OUTPUT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Support for Non-Sports
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231002@Winfred: NAP CM Customer Class - Support for Non-Sports [RedmineID: #186116] 

	Param's Explanation:
	* @Sites:  " 0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Products :  "3   : Number Game
					8   : RNG Keno
					18  : RNG Slot
					28  : Lottery
					40  : Table Game
					63  : Sports Lottery
					256 : All"

	Example: NAP_LM_CustomerClassNonSportsIns @PolicyID = 0, @PolicyTitle = 'Bad Performance', @CustomerClasses = '200,300,305',
		@Sites = 'Inbet,HonorW,Abcasino,Lexibet', @Products = '3,8,28,40', @MaxBet = 10000, @Enable = 1 , @ErrCode =0, @ErrMsg = '' ,  
		@IP = '11.12.11.10', @UserID = 6, @IsTest = 1
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
		, @NewProducts	  BINARY(32) = 0x0
	
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassNonSports a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 102 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	

	IF ISNULL(@CustomerClasses ,'') = '' OR ISNULL(@Sites ,'') = '' OR ISNULL(@Products ,'') = '' 
	BEGIN
		SELECT @ErrCode = 103 , @ErrMsg = 'Missing Required field' 
		RETURN
	END	
	-- Conver Products string to Products binary
	SELECT @NewProducts = (SELECT bitmap FROM dbo.f_SetValueBitmap_multiple(@NewProducts,@Products))
	-- End Cover
	INSERT INTO CustomerClassNonSports (
 		PolicyTitle 					    
	,	MaxBet 	
	,	Products
	,	Enable 	
	,	IsTest
	,  LastModifiedUser
	,  LastModifiedTime)	
	SELECT
		@PolicyTitle 				
		,@MaxBet
		,@NewProducts
		,@Enable 					
		,@IsTest
		,@UserID
		,GETDATE()
		
	SET @PolicyID = SCOPE_IDENTITY()

	INSERT INTO CustomerClassNonSportsDetail(PolicyID, SiteID, CustomerClass)	
	SELECT @PolicyID AS PolicyID, s.VALUE AS SiteID , c.CustomerClass
	FROM STRING_SPLIT(@Sites,',') s   
	  CROSS APPLY ( SELECT VALUE AS CustomerClass FROM STRING_SPLIT(@CustomerClasses,',') WHERE VALUE <> '' ) c  
	WHERE s.VALUE <> '' 

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@PolicyID				AS '@PolicyID',					
					@PolicyTitle			AS '@PolicyTitle',							
					@MaxBet					AS '@MaxBet',				
					@CustomerClasses		AS '@CustomerClasses',					
					@Sites					AS '@Sites',										
					@Products				AS '@Products',						
					@Enable					AS '@Enable',						
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
				@ActionID = 31920,
				@TrackingValue = @LogSPData,
				@duration = @Duration

END
GO
