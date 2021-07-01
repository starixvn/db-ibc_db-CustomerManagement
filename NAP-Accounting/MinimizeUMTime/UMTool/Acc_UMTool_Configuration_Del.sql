/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_Configuration_Del]
	 @UserId		INT = 0
	,@IP			VARCHAR(15) = ''
	,@ConfigID		INT
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(200) = '' OUTPUT
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Delete UMConfig
	DB: DBCUST.CustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]

	Param's Explanation:   
		
	Examples : 
		DECLARE  @ErrCode	INT = 0 ,@ErrMsg VARCHAR(200) = ''
		EXEC [Acc_UMTool_Configuration_Del] 
			@UserID			= 8,
			@IP				= '0.0.0.0', 
			@ConfigID		= 2, 
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
			,@BeginTime		SMALLDATETIME
			,@EndTime		SMALLDATETIME
			,@ShowTime		SMALLDATETIME
			,@LockAddingNew BIT 

	SELECT @BeginTime = c.BeginTime, 
		   @EndTime = c.EndTime, 
		   @ShowTime = c.ShowTime, 
		   @LockAddingNew = c.LockAddingNew, 
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

	IF @BeginTime IS NULL
	BEGIN
		SELECT @ErrCode = 1
			, @ErrMsg = 'The config does not exist.'

		RETURN
	END

	DELETE c
	FROM UMConfig c WITH(NOLOCK)
	WHERE c.ConfigID = @ConfigID

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData VARCHAR(MAX)
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
						+ ' />'

	--Write log:
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= 0,
				@ActionId			= 210003,
				@TrackingValue		= @LogData,
				@Duration			= @Duration

END