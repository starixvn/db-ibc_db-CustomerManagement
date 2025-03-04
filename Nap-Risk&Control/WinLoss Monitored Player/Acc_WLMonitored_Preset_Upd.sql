/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Preset_Upd
	 @ID INT 
	,@AgentID INT
	,@Sporttype SMALLINT = 0
	,@PresetTitle VARCHAR(50)
	,@WinningThreshold MONEY = NULL
	,@LosingThreshold MONEY = NULL
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
AS  
/*  
	Created:	20220523@Eden
	Task:		Update Personal Preset
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]
		- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]


	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Preset_Upd 
		 @ID = 1
		,@AgentID = 1176086
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

	IF NOT EXISTS(	SELECT 1 
					FROM WLMonitored_PersonalPreset WITH(NOLOCK) 
					WHERE AgentID = @AgentID 
						AND Sporttype = @Sporttype
						AND ID = @ID
				)
	BEGIN
		SELECT @ErrCode = 103,
				@ErrMsg = 'This preset is not available'
		RETURN
	END

	IF EXISTS(	SELECT 1 
				FROM WLMonitored_PersonalPreset WITH(NOLOCK) 
				WHERE AgentID = @AgentID 
					AND Sporttype = @Sporttype
					AND PresetTitle = @PresetTitle
					AND ID <> @ID
				)
	BEGIN
		SELECT @ErrCode = 104,
				@ErrMsg = 'Preset name is duplicated'
		RETURN
	END

	UPDATE g 
	SET g.WinningThreshold = @WinningThreshold,
		g.LosingThreshold = @LosingThreshold,
		g.PresetTitle = @PresetTitle,
		g.RepUpdateTime = dbo.f_GetDateTime2()
	FROM WLMonitored_PersonalPreset g WITH(ROWLOCK,UPDLOCK) 
	WHERE AgentID = @AgentID 
		AND Sporttype = @Sporttype
		AND ID = @ID

END
GO