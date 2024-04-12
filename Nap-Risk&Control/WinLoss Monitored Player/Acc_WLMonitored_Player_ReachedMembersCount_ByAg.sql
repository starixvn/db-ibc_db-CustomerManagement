/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Player_ReachedMembersCount_ByAg
	 @AgentID					INT
	,@Sporttype					SMALLINT = 0
	,@FromDate					DATETIME
	,@ToDate					DATETIME
	,@LimitType					TINYINT = 0
	,@ReachedDailyLimitCount	INT = 0 OUTPUT
AS  
/*  
	Created:	20240412@Kelvin
	Task:		Count Total Reached Threshold Accounts
	DB:			DBAGE/bodb02
	Original:	
  
	Revisions:  
	    - 20240412@Kelvin: Alpha - Link WL Detail to My Watchlist [Redmine:#201733]

	Param's Explanation:  	
		- @LimitType : 
				= 1: Global
				= 2: Personal
				= 0: All

	Sample:
	DECLARE @ReachedDailyLimitCount	INT
	EXEC Acc_WLMonitored_Player_ReachedMembersCount_ByAg 
		    @AgentID	= 1176086	
			,@FromDate = '2024/04/01'
			,@ToDate = '2024/04/12'
			,@LimitType = 0
			,@ReachedDailyLimitCount = @ReachedDailyLimitCount OUTPUT
	SELECT @ReachedDailyLimitCount
	
*/  
BEGIN 		
	SELECT @ReachedDailyLimitCount = COUNT(*)
	FROM dbo.WLMonitored_Player_History w WITH(NOLOCK)
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON ci.custid = w.custid
	WHERE ci.recommend = @AgentID
		AND ci.roleid = 1
		AND w.sporttype = @Sporttype		
		AND w.CreatedDate >= @FromDate
		AND w.CreatedDate < @ToDate + 1
		AND (w.SettingType = @LimitType OR @LimitType = 0 )		
END
GO
