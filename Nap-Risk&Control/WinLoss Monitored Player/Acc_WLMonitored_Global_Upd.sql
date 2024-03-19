/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Global_Upd
	 @AgentID INT
	,@Sporttype SMALLINT = 0
	,@WinningThreshold MONEY
	,@LosingThreshold MONEY
	,@WinningThreshold_old MONEY
	,@LosingThreshold_old MONEY
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
	,@UserId INT = 0
	,@SubAccID INT = 0
	,@IP VARCHAR(20) = ''
AS  
/*  
	Created:	20220523@Eden
	Task:		Update Global threshold (Agent)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Global_Upd 
		 @AgentID = 7373
		,@Sporttype = 0
		,@WinningThreshold = 1000
		,@LosingThreshold = 5000
		,@WinningThreshold_old = 200
		,@LosingThreshold_old = 400
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
	DECLARE @ActionID INT = 31801
	DECLARE @TrackingValue1 VARCHAR(MAX) = ''
	DECLARE @TrackingValue2 VARCHAR(MAX) = ''
	DECLARE @CurrentDTS DATETIME = GETDATE()
	
	SELECT @StartRun = GETDATE() 
	
	IF NOT EXISTS( SELECT 1 FROM WLMonitored_Global WITH(NOLOCK) WHERE AgentID = @AgentID AND Sporttype = @Sporttype)
	BEGIN
		RETURN
	END

	UPDATE g 
	SET g.WinningThreshold = @WinningThreshold,
		g.WinningUpdateTime = CASE WHEN ISNULL(@WinningThreshold,-1) <> ISNULL(@WinningThreshold_old,-1) THEN @CurrentDTS ELSE g.WinningUpdateTime END,
		g.LosingThreshold = @LosingThreshold,
		g.LosingUpdateTime = CASE WHEN ISNULL(@LosingThreshold,-1) <> ISNULL(@LosingThreshold_old,-1) THEN @CurrentDTS ELSE g.LosingUpdateTime END
	FROM WLMonitored_Global g WITH(ROWLOCK,UPDLOCK) 
	WHERE AgentID = @AgentID 
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
			@CustId				= @AgentID,
			@ActionId			= @ActionID,
			@TrackingValue		= @TrackingValue1,
			@TrackingValue2		= @TrackingValue2,
			@Duration			= @Duration
END
GO