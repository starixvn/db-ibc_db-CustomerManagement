/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Personal_Del
	 @CustID INT
	,@Sporttype SMALLINT = 0
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
	,@UserId INT = 0
	,@SubAccID INT = 0
	,@IP VARCHAR(20) = ''
AS  
/*  
	Created:	20220523@Eden
	Task:		Delete Personal threshold (Member)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Personal_Del 
		 @CustID = 1176092
		,@Sporttype = 0
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
	DECLARE @ActionID INT = 31804
	DECLARE @TrackingValue1 VARCHAR(MAX) = ''
	DECLARE @AgentID INT
	
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
		RETURN
	END

	DELETE g
	FROM WLMonitored_Player g WITH(ROWLOCK,UPDLOCK) 
	WHERE CustID = @CustID 
		AND Sporttype = @Sporttype

	SELECT @EndRun = GETDATE()    
	SELECT @Duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	SELECT  @TrackingValue1 = '<R '
						+ 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
						+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(10)),space(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @UserId,
			@CustId				= @CustID,
			@ActionId			= @ActionID,
			@TrackingValue		= @TrackingValue1,
			@Duration			= @Duration
END
GO