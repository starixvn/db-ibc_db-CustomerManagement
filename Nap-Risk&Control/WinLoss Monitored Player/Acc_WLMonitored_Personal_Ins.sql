/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Personal_Ins
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
	Task:		Insert Personal threshold (Member)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Personal_Ins 
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
	DECLARE @ActionID INT = 31802
	DECLARE @TrackingValue1 VARCHAR(MAX) = ''
	DECLARE @AgentID INT
	DECLARE @CurrentDTS DATETIME = GETDATE()
	DECLARE @InitSettingTime_Global DATETIME
	
	SELECT @StartRun = GETDATE() 

	SELECT @AgentID = recommend FROM custInfo c WITH(NOLOCK) WHERE custid = @CustID AND roleid = 1

	IF @AgentID IS NULL
	BEGIN
		SELECT @ErrCode = 102,
				@ErrMsg = 'are not member'
		RETURN
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable
			@custid = @CustID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	IF EXISTS( SELECT 1 FROM WLMonitored_Player WITH(NOLOCK) WHERE custid = @CustID AND Sporttype = @Sporttype)
	BEGIN
		SELECT @ErrCode = 103,
				@ErrMsg = 'were added into watchlist already'
		RETURN
	END

	SELECT @InitSettingTime_Global = InitSettingTime FROM WLMonitored_Global WITH(NOLOCK) WHERE AgentID = @AgentID AND Sporttype = @Sporttype

	INSERT INTO WLMonitored_Player(
		 CustID
		,Sporttype
		,AgentID
		,WinningThreshold
		,WinningUpdateTime
		,LosingThreshold
		,LosingUpdateTime
		,InitSettingTime
	)
	SELECT @CustID
		, @Sporttype
		, @AgentID
		, @WinningThreshold
		, @CurrentDTS
		, @LosingThreshold
		, @CurrentDTS
		, ISNULL(@InitSettingTime_Global, @CurrentDTS)

	SELECT @EndRun = GETDATE()    
	SELECT @Duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	SELECT  @TrackingValue1 = '<R '
						+ 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(10)),space(1)) + '" '
						+ 'WinningThreshold="'+ coalesce(cast(@WinningThreshold as varchar(50)),'Unlimited') + '" '
						+ 'LosingThreshold="'+ coalesce(cast(@LosingThreshold as varchar(50)),'Unlimited') + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @UserId,
			@CustId				= @CustID,
			@ActionId			= @ActionID,
			@TrackingValue		= @TrackingValue1,
			@Duration			= @Duration
END
GO