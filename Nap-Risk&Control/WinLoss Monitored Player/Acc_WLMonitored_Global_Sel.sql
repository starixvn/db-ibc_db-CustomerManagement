/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Global_Sel
	 @AgentID INT
	,@Sporttype SMALLINT = 0
AS  
/*  
	Created:	20220523@Eden
	Task:		View Global threshold (Agent)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	EXEC Acc_WLMonitored_Global_Sel 
		 @AgentID = 7373
		,@Sporttype = 0
	
*/  
BEGIN 
	SELECT AgentID
		,Sporttype
		,WinningThreshold
		,LosingThreshold
	FROM WLMonitored_Global WITH(NOLOCK) 
	WHERE AgentID = @AgentID 
		AND Sporttype = @Sporttype
END
GO