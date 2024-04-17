/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_SMA_Adjust
	 @CustID INT
	,@Sporttype SMALLINT = 0
	,@WinningThreshold MONEY = NULL
	,@LosingThreshold MONEY = NULL
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
	,@UserId INT = 0
	,@SubAccID INT = 0
	,@IP VARCHAR(20) = ''
	,@CustList VARCHAR(MAX) = NULL OUTPUT --Output to sync data to DBAGE.bodb02.do.CustWLMonitored_Setting
AS  
/*  
	Created:	20221220@Eden
	Task:		Insert/Update/Delete SMA threshold
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20221220@Eden: Alpha - Monitor SMA Win Loss [Redmine:#179067]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = '',@CustList VARCHAR(MAX)
	EXEC Acc_WLMonitored_SMA_Adjust 
		 @CustID = 1176086
		,@Sporttype = 0
		,@WinningThreshold = 1000
		,@LosingThreshold = 5000
		,@ErrCode = @ErrCode OUT
		,@ErrMsg = @ErrMsg OUT
		,@UserId = 8
		,@SubAccID = 0
		,@IP = '0.0.0.0'
		,@CustList = @CustList OUT
	SELECT @ErrCode, @ErrMsg, @CustList AS CustList
	
*/  
BEGIN 
	IF NOT EXISTS( SELECT 1 FROM custInfo c WITH(NOLOCK) WHERE custid = @CustID AND roleid IN(2,3,4))
	BEGIN
		SELECT @ErrCode = 102,
				@ErrMsg = 'Invalid account'
		RETURN
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable
			@custid = @CustID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE  @WinningThreshold_Old MONEY
			,@LosingThreshold_Old MONEY

	SELECT @WinningThreshold_Old= WinningThreshold
		,@LosingThreshold_Old = LosingThreshold 
	FROM WLMonitored_SMA WITH(NOLOCK) 
	WHERE custid = @CustID 
		AND Sporttype = @Sporttype

	IF @WinningThreshold_Old IS NULL AND @LosingThreshold_Old IS NULL --SMA is turning off
	BEGIN
		IF @WinningThreshold IS NULL AND @LosingThreshold IS NULL
		BEGIN
			PRINT 'Unchanged'
			RETURN -- Unchanged
		END
		ELSE
		BEGIN --Insert SMA
			EXEC Acc_WLMonitored_SMA_Ins 
				 @CustID = @CustID
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

			SELECT @CustList =
			(
				SELECT CustID = -1,recommend = @CustID,IsDeleted = 0
				FOR XML RAW('R'), ROOT ('ROOT')
			)	
		END
	END
	ELSE
	BEGIN
		IF @WinningThreshold IS NULL AND @LosingThreshold IS NULL -- Turn off SMA
		BEGIN
			EXEC Acc_WLMonitored_SMA_Del 
				 @CustID = @CustID
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

			SELECT @CustList =
			(
				SELECT CustID = -1,recommend = @CustID,IsDeleted = 1
				FOR XML RAW('R'), ROOT ('ROOT')
			)	
		END
		ELSE --Update SMA
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
				EXEC Acc_WLMonitored_SMA_Upd
					 @CustID = @CustID
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