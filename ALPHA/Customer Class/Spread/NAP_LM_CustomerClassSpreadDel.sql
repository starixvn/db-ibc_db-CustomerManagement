/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSpreadDel] 
	  @PolicyID			INT			
	, @UserID			INT
	, @IP				VARCHAR(50)		= ''
	, @IsTest			TINYINT	
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
		- 20230115@Luke: [NAP CM] Customer Class - Spread mng - Set Spread by Sport [Redmine: #195328]

	Param's Explanation:

	Example: NAP_LM_CustomerClassSpreadDel @PolicyID = 15, @ErrCode =0, @ErrMsg = '' , @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
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
		, @SportType_Old	SMALLINT
		, @Sites_Old VARCHAR(MAX)= ''
		, @Currencies_Old VARCHAR(MAX)= ''
		, @Platforms_Old VARCHAR(MAX)= ''
		, @LastModifiedTime DATETIME
		
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassSpread_History(PolicyID INT, PolicyTitle VARCHAR(500), Spread DECIMAL(4,2), Enable BIT,IsTest TINYINT, LastModifiedUser INT, LastModifiedTime DATETIME)

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassSpread a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	
		
	INSERT INTO #CustomerClassSpread_History(PolicyID, PolicyTitle, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime)
	SELECT PolicyID, PolicyTitle, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime 
	FROM CustomerClassSpread WITH(NOLOCK) WHERE PolicyID = @PolicyID
	
	SELECT TOP 1 @SportType_Old = SportType 
	FROM CustomerClassSpreadDetail WITH (NOLOCK)
	WHERE PolicyID = @PolicyID

	SELECT @CustomerClasses_Old = (SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
									WITHIN GROUP (ORDER BY CustomerClass)
								FROM( SELECT DISTINCT CustomerClass
								FROM CustomerClassSpreadClass  WITH(NOLOCK)
								WHERE PolicyID = @PolicyID)cc) 
	
	SELECT @Currencies_Old = (SELECT STRING_AGG(CAST(Currency AS NVARCHAR(MAX)), ',') 
									WITHIN GROUP (ORDER BY Currency)
								FROM(	SELECT DISTINCT Currency
								FROM CustomerClassSpreadDetail WITH(NOLOCK)
								WHERE PolicyID = @PolicyID)cc) 
							
	SELECT @Sites_Old = (SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY SiteID)
							FROM(	SELECT DISTINCT SiteID
							FROM CustomerClassSpreadDetail WITH(NOLOCK)
							WHERE PolicyID = @PolicyID)cc) 
								
	SELECT @Platforms_Old = (SELECT STRING_AGG(CAST(Platform AS NVARCHAR(MAX)), ',') 
								WITHIN GROUP (ORDER BY Platform)
							FROM(	SELECT DISTINCT Platform
							FROM CustomerClassSpreadDetail WITH(NOLOCK)
							WHERE PolicyID = @PolicyID)cc) 
	
	BEGIN TRY
		DELETE FROM CustomerClassSpread WITH(ROWLOCK,UPDLOCK) WHERE PolicyID = @PolicyID
		DELETE FROM CustomerClassSpreadClass WITH(ROWLOCK,UPDLOCK) WHERE PolicyID = @PolicyID
		DELETE FROM CustomerClassSpreadDetail WITH(ROWLOCK,UPDLOCK) WHERE PolicyID = @PolicyID
 	
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

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

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31907,
				@TrackingValue = NULL,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration
END
GO
