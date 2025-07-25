/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_CCPeakHourRangerIns] 
	  @RangeID			INT			OUTPUT
	, @WeekDay			TINYINT
	, @StartRange		TIME(1)
	, @EndRange			TIME(1)
	, @UserID			INT
	, @IsTest			TINYINT
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0	 OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	 OUTPUT
AS
/*
	Created: Winfred
	Date: 20240612
	Task : [NAP CM] Customer Class - Add Peak Hour Ranger setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

	Param's Explanation:
		* @WeekDay :" 1 : Sunday
					  2 : Monday
					  3 : Tuesday 
					  4 : Wednesday
					  5 : Thursday
					  6 : Friday
					  7 : Saturday"
		* @StartRange : "01:30:20"
		* @EndRange  : "08:30:20"
	Example: NAP_CM_CCPeakHourRangerIns @RangeID = 0, @WeekDay = 2, @StartRange = '01:30:20', @EndRange = '08:30:20',
	@ErrCode =0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @xml			  XML
		, @ActionID		  INT
		, @LastModifiedTime DATETIME
	
	SELECT @StartRun	= GETDATE() , @LastModifiedTime = GETDATE()

	INSERT INTO CustomerClassPeakHourRanger(
 		  WeekDay 	
		, StartRange 		
		, EndRange 	
		, IsTest
		, LastModifiedUser
		, LastModifiedTime
		, RepUpdateTime
	)	
	SELECT
		@WeekDay 
		,@StartRange 					    
		,@EndRange 					
		,@IsTest
		,@UserID
		,@LastModifiedTime
		,[dbo].[f_GetDateTime2]()

	SET @RangeID = SCOPE_IDENTITY()
		
	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',					
					@RangeID				AS '@RangeID',					
					@WeekDay				AS '@WeekDay',					
					@StartRange				AS '@StartRange',
					@EndRange				AS '@EndRange',								
					@IsTest					AS '@IsTest',		
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
				@ActionID = 31928,
				@TrackingValue = @LogSPData,
				@duration = @Duration

END
GO
