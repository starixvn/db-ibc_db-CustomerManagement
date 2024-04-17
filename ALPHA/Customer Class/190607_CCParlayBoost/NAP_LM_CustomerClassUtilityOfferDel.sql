/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassUtilityOfferDel] 
	  @PolicyID			INT			
	, @UserID			INT
	, @IP				VARCHAR(50)		= ''
	, @IsTest			TINYINT	
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

	Example: NAP_LM_CustomerClassUtilityOfferDel @PolicyID = 15, @ErrCode =0, @ErrMsg = '' , @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			  XML
		, @CustomerClasses_Old VARCHAR(MAX) = ''
		, @Sites_Old VARCHAR(MAX)= ''
		, @Currency_Old VARCHAR(MAX)= ''
		, @UtilityOffering_Old	VARCHAR(500)
		, @LastModifiedTime DATETIME
		
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassUtilityOffer_History(PolicyID INT, PolicyTitle VARCHAR(500), IsTest TINYINT, LastModifiedUser INT, LastModifiedTime DATETIME)

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassUtilityOffer a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	
	-- Conver Products smallint to Products string
	SET @UtilityOffering_Old = ( SELECT s.UtilityOffering
								FROM CustomerClassUtilityOffer a WITH(NOLOCK)
									CROSS APPLY	(SELECT VALUE AS UtilityOffering
												FROM dbo.f_SmallIntToOfferValue(a.UtilityOffering)) s
								WHERE a.PolicyID = @PolicyID )
	-- End Cover
	
	SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
									WITHIN GROUP (ORDER BY CustomerClass)
								FROM( SELECT DISTINCT CustomerClass
								FROM CustomerClassUtilityOfferDetail  WITH(NOLOCK)
								WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
								
	SELECT @Sites_Old = (SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY SiteID)
							FROM(	SELECT DISTINCT SiteID
							FROM CustomerClassUtilityOfferDetail WITH(NOLOCK)
							WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
								
	SELECT @Currency_Old = (SELECT STRING_AGG(CAST(Currency AS NVARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY Currency)
							FROM(	SELECT DISTINCT Currency
							FROM CustomerClassUtilityOfferDetail WITH(NOLOCK)
							WHERE PolicyID = @PolicyID AND isDeleted = 0)cc) 
	UPDATE a	
	SET   a.[isDeleted] = 1
		, a.[RepUpdateTime]=sysdatetime()
	OUTPUT	deleted.PolicyTitle 
		,	deleted.IsTest
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
	INTO #CustomerClassUtilityOffer_History(PolicyTitle  		
			 ,	IsTest
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime )
	FROM CustomerClassUtilityOffer a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID AND isDeleted = 0

	UPDATE a	
	SET   a.[isDeleted] = 1
		, a.[RepUpdateTime]=sysdatetime()
	FROM CustomerClassUtilityOfferDetail a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID AND isDeleted = 0

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

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31914,
				@TrackingValue = NULL,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassUtilityOffer_History
END
GO
