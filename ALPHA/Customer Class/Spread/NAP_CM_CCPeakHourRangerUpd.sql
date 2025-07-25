/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_CCPeakHourRangerUpd] 
	  @RangeID			INT			OUTPUT
	, @WeekDay			TINYINT
	, @StartRange		TIME(1)
	, @EndRange			TIME(1)
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
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
	* @WeekDay :"   1 : Sunday
					2 : Monday
					3 : Tuesday 
					4 : Wednesday
					5 : Thursday
					6 : Friday
					7 : Saturday"
	* @StartRange : "01:30:20"
	* @EndRange  : "08:30:20"

	Example: NAP_CM_CCPeakHourRangerUpd @RangeID = 25, @WeekDay = 2, @StartRange = '01:30:20', @EndRange = '08:30:20', @ErrCode =0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			  XML
		, @WeekDay_Old TINYINT = ''
		, @StartRange_Old		TIME(1)
		, @EndRange_Old			TIME(1)
		, @LastModifiedUser_Old INT
		, @LastModifiedTime_Old DATETIME
		, @LastModifiedTime DATETIME
	
	IF EXISTS(SELECT TOP 1 1 FROM CustomerClassPeakHourRanger a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND RangeID = @RangeID ) 
	BEGIN
		SELECT @ErrCode = 102 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	

	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	
	SELECT  @WeekDay_Old = WeekDay, 
			@StartRange_Old = StartRange, 
			@EndRange_Old = EndRange ,
			@LastModifiedUser_Old = LastModifiedUser,
			@LastModifiedTime_Old = LastModifiedTime
	FROM CustomerClassPeakHourRanger WITH(NOLOCK) WHERE RangeID = @RangeID

	UPDATE a	
	SET a.WeekDay 		= @WeekDay 
		,a.StartRange	= @StartRange
		,a.EndRange		= @EndRange
		,a.IsTest		= @IsTest
		,a.LastModifiedUser = @UserID
		,a.LastModifiedTime = @LastModifiedTime
		,a.RepUpdateTime = [dbo].[f_GetDateTime2]()
	FROM CustomerClassPeakHourRanger a WITH (ROWLOCK, UPDLOCK)
	WHERE a.RangeID = @RangeID
	
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
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	SET @xml = (
			SELECT	@LastModifiedUser_Old	AS '@UserID',				
					@IP						AS '@IP',					
					@RangeID				AS '@RangeID',					
					@WeekDay_Old			AS '@WeekDay',					
					@StartRange_Old			AS '@StartRange',
					@EndRange_Old			AS '@EndRange',	
					@IsTest					AS '@IsTest',	
					CONVERT(VARCHAR(10), @LastModifiedTime_Old, 120) AS '@LastModifiedTime',	
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
				@ActionID = 31927,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

END
GO
