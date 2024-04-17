/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Preset_Del
	 @ID INT 
	,@AgentID INT
	,@Sporttype SMALLINT = 0
	,@ErrCode INT = 0 OUT
	,@ErrMsg VARCHAR(500) = '' OUT
AS  
/*  
	Created:	20220523@Eden
	Task:		Remove Personal Preset
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	DECLARE @ErrCode INT = 0 ,@ErrMsg VARCHAR(500) = ''
	EXEC Acc_WLMonitored_Preset_Del 
		 @ID = 1
		,@AgentID = 1176086
		,@Sporttype = 0
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
		RETURN
	END

	DELETE g 
	FROM WLMonitored_PersonalPreset g WITH(ROWLOCK,UPDLOCK) 
	WHERE AgentID = @AgentID 
		AND Sporttype = @Sporttype
		AND ID = @ID

END
GO