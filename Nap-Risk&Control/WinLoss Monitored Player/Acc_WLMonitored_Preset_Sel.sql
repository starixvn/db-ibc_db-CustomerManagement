/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Preset_Sel
	 @AgentID INT
	,@Sporttype SMALLINT = 0
AS  
/*  
	Created:	20220523@Eden
	Task:		Select Personal Preset
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	EXEC Acc_WLMonitored_Preset_Sel 
		 @AgentID = 1176086
		,@Sporttype = 0
	
*/  
BEGIN 
	SELECT ID
		,AgentID
		,Sporttype
		,PresetTitle
		,WinningThreshold
		,LosingThreshold
	FROM WLMonitored_PersonalPreset WITH(NOLOCK) 
	WHERE AgentID = @AgentID 
		AND Sporttype = @Sporttype
END
GO