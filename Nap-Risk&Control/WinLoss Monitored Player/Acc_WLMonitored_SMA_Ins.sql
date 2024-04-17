/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_SMA_Ins
	 @CustID INT
	,@Sporttype SMALLINT = 0
	,@WinningThreshold MONEY
	,@LosingThreshold MONEY
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
	,@UserId INT = 0
	,@SubAccID INT = 0
	,@IP VARCHAR(20) = ''
AS  
/*  
	Created:	20221220@Eden
	Task:		Insert SMA threshold
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20221220@Eden: Alpha - Monitor SMA Win Loss [Redmine:#179067]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_SMA_Ins 
		 @CustID = 1176086
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
	DECLARE @ActionID INT
	DECLARE @TrackingValue1 VARCHAR(MAX) = ''
	DECLARE @TrackingValue2 VARCHAR(MAX) = ''
	DECLARE @CurrentDTS DATETIME = GETDATE()
	DECLARE @RoleID INT 
	
	SELECT @StartRun = GETDATE() 
	
	IF EXISTS( SELECT 1 FROM WLMonitored_SMA WITH(NOLOCK) WHERE custid = @CustID AND Sporttype = @Sporttype)
	BEGIN
		RETURN
	END

	SELECT @RoleID = roleid FROM custInfo WITH(NOLOCK) WHERE custid = @CustID

	IF @RoleID = 4
		SET @ActionID = 31808
	ELSE IF @RoleID = 3
		SET @ActionID = 31809
	ELSE IF @RoleID = 2
		SET @ActionID = 31810
	ELSE
		RETURN

	INSERT INTO WLMonitored_SMA(
		 CustID
		,Sporttype
		,WinningThreshold
		,WinningUpdateTime
		,LosingThreshold
		,LosingUpdateTime
		,InitSettingTime
	)
	SELECT @CustID
		, @Sporttype
		, @WinningThreshold
		, @CurrentDTS
		, @LosingThreshold
		, @CurrentDTS
		, @CurrentDTS

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
						+ 'WinningThreshold="'+ 'Unlimited' + '" '
						+ 'LosingThreshold="'+ 'Unlimited' + '" '
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