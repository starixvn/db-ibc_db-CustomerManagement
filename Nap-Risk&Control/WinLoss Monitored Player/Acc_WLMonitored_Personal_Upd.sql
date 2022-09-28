/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Personal_Upd
	 @CustID INT
	,@Sporttype SMALLINT = 0
	,@WinningThreshold MONEY = NULL
	,@LosingThreshold MONEY = NULL
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
	,@UserId INT = 0
	,@SubAccID INT = 0
	,@IP VARCHAR(20) = ''
AS  
/*  
	Created:	20220523@Eden
	Task:		Update Personal threshold (Member)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Personal_Upd 
		 @CustID = 7373
		,@Sporttype = 0
		,@WinningThreshold = 1000
		,@LosingThreshold = 5000
		,@ErrCode = @ErrCode OUT
		,@ErrMsg = @ErrMsg OUT
		,@UserId = 8
		,@SubAccID = 0
		,@IP = '0.0.0.0'
	SELECT @ErrCode, @ErrMsg
	
*/  
BEGIN 
	SELECT @ErrCode = 0, @ErrMsg = ''
	DECLARE @StartRun DATETIME  
	DECLARE @EndRun DATETIME  
	DECLARE @Duration INT 
	DECLARE @ActionID INT = 31803
	DECLARE @TrackingValue1 VARCHAR(MAX) = '', @TrackingValue2 VARCHAR(MAX) = ''
	DECLARE @AgentID INT
	DECLARE @CurrentDTS DATETIME = GETDATE()
	
	SELECT @StartRun = GETDATE() 

	SELECT @AgentID = recommend FROM custInfo c WITH(NOLOCK) WHERE custid = @CustID AND roleid = 1

	IF @AgentID IS NULL
	BEGIN
		SELECT @ErrCode = 102,
				@ErrMsg = 'Invalid Account'
		RETURN
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable
			@custid = @CustID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	IF NOT EXISTS( SELECT 1 FROM WLMonitored_Player WITH(NOLOCK) WHERE custid = @CustID AND Sporttype = @Sporttype)
	BEGIN
		SELECT @ErrCode = 103,
				@ErrMsg = 'this member is not in watchlist account any longer'
		RETURN
	END

	DECLARE  @WinningThreshold_Old MONEY
			,@LosingThreshold_Old MONEY

	SELECT @WinningThreshold_Old = WinningThreshold
		,@LosingThreshold_Old = LosingThreshold 
	FROM WLMonitored_Player WITH(NOLOCK) 
	WHERE CustID = @CustID 
		AND Sporttype = @Sporttype

	IF (@WinningThreshold IS NULL AND @WinningThreshold_Old IS NULL AND @LosingThreshold = @LosingThreshold_Old)
		OR (@WinningThreshold = @WinningThreshold_Old AND @LosingThreshold IS NULL AND @LosingThreshold_Old IS NULL)
		OR (@WinningThreshold = @WinningThreshold_Old AND @LosingThreshold = @LosingThreshold_Old)
		OR (@WinningThreshold IS NULL AND @WinningThreshold_Old IS NULL AND @LosingThreshold IS NULL AND @LosingThreshold_Old IS NULL)
	BEGIN
		PRINT 'Unchanged'
		RETURN -- Unchanged
	END

	UPDATE g 
	SET g.WinningThreshold = @WinningThreshold,
		g.WinningUpdateTime = CASE WHEN ISNULL(@WinningThreshold,-1) <> ISNULL(@WinningThreshold_old,-1) THEN @CurrentDTS ELSE g.WinningUpdateTime END,
		g.LosingThreshold = @LosingThreshold,
		g.LosingUpdateTime = CASE WHEN ISNULL(@LosingThreshold,-1) <> ISNULL(@LosingThreshold_old,-1) THEN @CurrentDTS ELSE g.LosingUpdateTime END
		--g.InitSettingTime = CASE WHEN @LosingThreshold_old IS NULL AND @WinningThreshold_Old IS NULL THEN @CurrentDTS ELSE g.InitSettingTime END
	FROM WLMonitored_Player g WITH(ROWLOCK,UPDLOCK) 
	WHERE CustID = @CustID 
		AND Sporttype = @Sporttype

	SELECT @EndRun = GETDATE()    
	SELECT @Duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	SELECT  @TrackingValue1 = '<R '
						+ 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(10)),space(1)) + '" '
						+ 'WinningThreshold="'+ coalesce(cast(@WinningThreshold as varchar(50)),'Unlimited') + '" '
						+ 'LosingThreshold="'+ coalesce(cast(@LosingThreshold as varchar(50)),'Unlimited') + '" '
						+ ' />'

	SELECT  @TrackingValue2 = '<R '
						+ 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(10)),space(1)) + '" '
						+ 'WinningThreshold="'+ coalesce(cast(@WinningThreshold_old as varchar(50)),'Unlimited') + '" '
						+ 'LosingThreshold="'+ coalesce(cast(@LosingThreshold_old as varchar(50)),'Unlimited') + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @UserId,
			@CustId				= @CustID,
			@ActionId			= @ActionID,
			@TrackingValue		= @TrackingValue1,
			@TrackingValue2		= @TrackingValue2,
			@Duration			= @Duration
END
GO