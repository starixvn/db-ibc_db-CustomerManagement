/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Global_Adjust
	 @AgentID INT
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
	Task:		Insert/Update/Delete Global threshold (Agent)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Global_Adjust 
		 @AgentID = 7373
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
	IF NOT EXISTS( SELECT 1 FROM custInfo c WITH(NOLOCK) WHERE custid = @AgentID AND roleid = 2)
	BEGIN
		SELECT @ErrCode = 102,
				@ErrMsg = 'Invalid agent'
		RETURN
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable
			@custid = @AgentID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE  @WinningThreshold_Old MONEY
			,@LosingThreshold_Old MONEY

	SELECT @WinningThreshold_Old= WinningThreshold
		,@LosingThreshold_Old = LosingThreshold 
	FROM WLMonitored_Global WITH(NOLOCK) 
	WHERE AgentID = @AgentID 
		AND Sporttype = @Sporttype

	IF @WinningThreshold_Old IS NULL AND @LosingThreshold_Old IS NULL --Global is turning off
	BEGIN
		IF @WinningThreshold IS NULL AND @LosingThreshold IS NULL
		BEGIN
			PRINT 'Unchanged'
			RETURN -- Unchanged
		END
		ELSE
		BEGIN --Insert Global
			EXEC Acc_WLMonitored_Global_Ins 
				 @AgentID = @AgentID
				,@Sporttype = @Sporttype
				,@WinningThreshold = @WinningThreshold
				,@LosingThreshold = @LosingThreshold
				,@ErrCode = @ErrCode OUT
				,@ErrMsg = @ErrMsg OUT
				,@UserId = @UserId
				,@SubAccID = @SubAccID
				,@IP = @IP

			IF @ErrCode <> 0
				RETURN
		END
	END
	ELSE
	BEGIN
		IF @WinningThreshold IS NULL AND @LosingThreshold IS NULL -- Turn off Global
		BEGIN
			EXEC Acc_WLMonitored_Global_Del 
				 @AgentID = @AgentID
				,@Sporttype = @Sporttype
				,@WinningThreshold_Old = @WinningThreshold_Old
				,@LosingThreshold_Old = @LosingThreshold_Old
				,@ErrCode = @ErrCode OUT
				,@ErrMsg = @ErrMsg OUT
				,@UserId = @UserId
				,@SubAccID = @SubAccID
				,@IP = @IP

			IF @ErrCode <> 0
				RETURN
		END
		ELSE --Update Global
		BEGIN
			IF (@WinningThreshold IS NULL AND @WinningThreshold_Old IS NULL AND @LosingThreshold = @LosingThreshold_Old)
				OR (@WinningThreshold = @WinningThreshold_Old AND @LosingThreshold IS NULL AND @LosingThreshold_Old IS NULL)
				OR (@WinningThreshold = @WinningThreshold_Old AND @LosingThreshold = @LosingThreshold_Old)
			BEGIN
				PRINT 'Unchanged'
				RETURN -- Unchanged
			END
			ELSE
			BEGIN
				EXEC Acc_WLMonitored_Global_Upd
					 @AgentID = @AgentID
					,@Sporttype = @Sporttype
					,@WinningThreshold = @WinningThreshold
					,@LosingThreshold = @LosingThreshold
					,@WinningThreshold_Old = @WinningThreshold_Old
					,@LosingThreshold_Old = @LosingThreshold_Old
					,@ErrCode = @ErrCode OUT
					,@ErrMsg = @ErrMsg OUT
					,@UserId = @UserId
					,@SubAccID = @SubAccID
					,@IP = @IP

				IF @ErrCode <> 0
					RETURN
			END
		END
	END

END
GO