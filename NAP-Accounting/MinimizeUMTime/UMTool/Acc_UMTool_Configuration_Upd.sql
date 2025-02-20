/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_Configuration_Upd]
	 @UserId		INT = 0
	,@IP			VARCHAR(15) = ''
	,@ConfigID		INT
	,@BeginTime		SMALLDATETIME
	,@EndTime		SMALLDATETIME
	,@ShowTime		SMALLDATETIME = NULL
	,@LockAddingNew BIT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(200) = '' OUTPUT
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Update UMConfig
	DB: DBGLOB/GlobCustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]
		- 20220824@Eddie: Add default for @ShowTime [RedmineID: #174852]
		- 20250226@Johnson: move sp to GlobCustDB [redmine: #216870]
	Param's Explanation:   
		
	Examples : 
		DECLARE  @ErrCode	INT = 0 ,@ErrMsg VARCHAR(200) = ''
		EXEC [Acc_UMTool_Configuration_Upd] 
			@UserID			= 8,
			@ConfigID		= 2, 
			@BeginTime		= '2020/10/03 01:25:00',
			@EndTime		= '2020/10/05 16:27:00',
			@ShowTime		= '2020/10/01 20:25:20',
			@LockAddingNew	= 0 ,
			@ErrCode = @ErrCode OUT,
			@ErrMsg = @ErrMsg OUT
			SELECT @ErrCode, @ErrMsg
*/
SET NOCOUNT ON	
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SET @StartRun = GETDATE()

	DECLARE  @FunctionType	TINYINT
			,@ProductID		TINYINT
			,@SportType		SMALLINT
			,@SettingType	TINYINT
			,@SiteID		INT
			,@Currency		INT
			,@SuperID		INT
			,@Bettype		SMALLINT
			,@IsLive		BIT

	DECLARE  @BeginTime_old		SMALLDATETIME
			,@EndTime_old		SMALLDATETIME
			,@ShowTime_old		SMALLDATETIME
			,@LockAddingNew_old BIT 

	SELECT @BeginTime_old = c.BeginTime, 
		   @EndTime_old = c.EndTime, 
		   @ShowTime_old = c.ShowTime, 
		   @LockAddingNew_old = c.LockAddingNew, 
		   @FunctionType = c.FunctionType, 
		   @ProductID = c.ProductID, 
		   @SportType = c.SportType, 
		   @SettingType = c.SettingType, 
		   @Currency = c.Currency, 
		   @SiteID = c.SiteID, 
		   @SuperID = c.SuperID, 
		   @BetType = c.Bettype, 
		   @IsLive = c.IsLive
	FROM UMConfig c WITH(NOLOCK)
	WHERE c.ConfigID = @ConfigID

	IF @ProductID IS NULL
	BEGIN
		SELECT @ErrCode = 1
			, @ErrMsg = 'The config does not exist.'

		RETURN
	END

	SELECT @ShowTime_old = DATEADD(hh,12,@ShowTime_old)
	SELECT @BeginTime_old = DATEADD(hh,12,@BeginTime_old)
	SELECT @EndTime_old = DATEADD(hh,12,@EndTime_old)

	UPDATE c
	SET     c.ShowTime = DATEADD(hh,-12,@ShowTime),
			c.BeginTime = DATEADD(hh,-12,@BeginTime),
			c.EndTime = DATEADD(hh,-12,@EndTime),
			c.LockAddingNew = @LockAddingNew
	FROM UMConfig c WITH(NOLOCK)
	WHERE c.ConfigID = @ConfigID

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData VARCHAR(MAX),@LogData_old VARCHAR(MAX)
	SELECT  @LogData = '<R '
						+ 'FunctionType="'+ coalesce(cast(@FunctionType as varchar(50)),space(1)) + '" ' 
						+ 'ProductID="'+ coalesce(cast(@ProductID as varchar(50)),space(1)) + '" '
						+ 'SportType="'+ coalesce(cast(@SportType as varchar(50)),space(1)) + '" ' 
						+ 'BetType="'+ coalesce(cast(@BetType as varchar(50)),space(1)) + '" ' 
						+ 'IsLive="'+ coalesce(cast(@IsLive as varchar(50)),space(1)) + '" ' 
						+ 'SettingType="'+ coalesce(cast(@SettingType as varchar(50)),space(1)) + '" '
						+ 'SiteID="'+ coalesce(cast(@SiteID as varchar(50)),space(1)) + '" ' 
						+ 'Currency="'+ coalesce(cast(@Currency as varchar(50)),space(1)) + '" ' 
						+ 'SuperID="'+ coalesce(cast(@SuperID as varchar(50)),space(1)) + '" ' 
						+ 'BeginTime="'+ coalesce(cast(@BeginTime as varchar(50)),space(1)) + '" '
						+ 'EndTime="'+ coalesce(cast(@EndTime as varchar(50)),space(1)) + '" ' 
						+ 'ShowTime="'+ coalesce(cast(@ShowTime as varchar(50)),space(1)) + '" ' 
						+ 'LockAddingNew="'+ coalesce(cast(@LockAddingNew as varchar(50)),space(1)) + '" ' 
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ ' />',
			 @LogData_old = '<R '
						+ 'BeginTime="'+ coalesce(cast(@BeginTime_old as varchar(50)),space(1)) + '" '
						+ 'EndTime="'+ coalesce(cast(@EndTime_old as varchar(50)),space(1)) + '" ' 
						+ 'ShowTime="'+ coalesce(cast(@ShowTime_old as varchar(50)),space(1)) + '" ' 
						+ 'LockAddingNew="'+ coalesce(cast(@LockAddingNew_old as varchar(50)),space(1)) + '" ' 
						+ ' />'

	--Write log:
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= 0,
				@ActionId			= 210002,
				@TrackingValue		= @LogData,
				@TrackingValue2		= @LogData_old,
				@Duration			= @Duration

END