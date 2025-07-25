/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_CCPeakHourRangerDel] 
	  @RangeID			INT			
	, @UserID			INT
	, @IP				VARCHAR(50)		= ''
	, @IsTest			TINYINT	
	, @ErrCode			TINYINT			= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20240612
	Task : [NAP CM] Customer Class - Del Peak Hour Ranger setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

	Param's Explanation:

	Example: NAP_CM_CCPeakHourRangerDel @RangeID = 15, @ErrCode =0, @ErrMsg = '' , @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
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
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	
	SELECT  @WeekDay_Old = WeekDay, 
			@StartRange_Old = StartRange, 
			@EndRange_Old = EndRange ,
			@LastModifiedUser_Old = LastModifiedUser,
			@LastModifiedTime_Old = LastModifiedTime
	FROM CustomerClassPeakHourRanger WITH(NOLOCK) WHERE RangeID = @RangeID

	BEGIN TRY
		DELETE FROM CustomerClassPeakHourRanger WITH(ROWLOCK,UPDLOCK) 
		OUTPUT DELETED.RangeID, DELETED.WeekDay, DELETED.StartRange, DELETED.EndRange, [dbo].[f_GetDateTime2]() 
		INTO CustomerClassPeakHourRanger_Del_InHouse(RangeID, WeekDay, StartRange, EndRange, RepUpdateTime )
		WHERE RangeID = @RangeID
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Log new updated data
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
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31925,
				@TrackingValue = NULL,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration
END
GO
