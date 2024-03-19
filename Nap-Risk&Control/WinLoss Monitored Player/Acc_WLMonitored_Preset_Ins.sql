/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Preset_Ins
	 @AgentID INT
	,@Sporttype SMALLINT = 0
	,@PresetTitle VARCHAR(50)
	,@WinningThreshold MONEY = NULL
	,@LosingThreshold MONEY = NULL
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
AS  
/*  
	Created:	20220523@Eden
	Task:		Insert Personal Preset
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Preset_Ins 
		 @AgentID = 1176086
		,@Sporttype = 0
		,@PresetTitle = 'Preset 1'
		,@WinningThreshold = 1000
		,@LosingThreshold = 5000
		,@ErrCode = @ErrCode OUT
		,@ErrMsg = @ErrMsg OUT
	SELECT @ErrCode, @ErrMsg
	
*/  
BEGIN 
	SELECT @ErrCode = 0, @ErrMsg = ''

	IF NOT EXISTS (SELECT 1 FROM custInfo c WITH(NOLOCK) WHERE custid = @AgentID AND roleid = 2)
	BEGIN
		SELECT @ErrCode = 102,
				@ErrMsg = 'Invalid Account'
		RETURN
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable
			@custid = @AgentID,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	IF EXISTS(	SELECT 1 
				FROM WLMonitored_PersonalPreset WITH(NOLOCK) 
				WHERE AgentID = @AgentID 
					AND Sporttype = @Sporttype
					AND PresetTitle = @PresetTitle
				)
	BEGIN
		SELECT @ErrCode = 103,
				@ErrMsg = 'Preset name is duplicated'
		RETURN
	END

	INSERT INTO WLMonitored_PersonalPreset(
		 AgentID
		,Sporttype
		,PresetTitle
		,WinningThreshold
		,LosingThreshold
	)
	SELECT @AgentID
		, @Sporttype
		, @PresetTitle
		, @WinningThreshold
		, @LosingThreshold
END
GO