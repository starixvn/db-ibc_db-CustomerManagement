/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Player_WatchListSummary_Sel
(
	 @AgentID INT,
	 @ReachedDailyLimitCount INT = 0
)
AS  
/*  
	Created:	20240411@Kelvin
	Task:		Get info Watchlist Summary
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20240411@Kelvin: Alpha - Link WL Detail to My Watchlist [Redmine:#201733]

	Param's Explanation:  		
		@ReachedDailyLimitCount : get data return from DBAGE-bodb02.Acc_WLMonitored_Player_ReachedMembersCount_ByAg
	
	Sample:	
	EXEC Acc_WLMonitored_Player_WatchListSummary_Sel 
		    @AgentID	= 1176086,
			@ReachedDailyLimitCount = 16
*/  
BEGIN 
SET NOCOUNT ON;

	DECLARE @UnlimitedThresholdUsersList	VARCHAR(MAX),
			@UnlimitedThresholdCount		INT
	
	CREATE TABLE #Temp
	(
		CustID				INT,
		UserName			VARCHAR(30),
		Status				TINYINT, 
		IsExistedWatchList	TINYINT,
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
	)
			
	INSERT INTO #Temp
	(
		CustID,
		UserName,
		Status,
		IsExistedWatchList,
		WinningThreshold,
		LosingThreshold
	)
	SELECT  ci.custid,
			ci.username,
			CASE 
				WHEN ci.Enabled = 1 AND cs.Closed = 0 AND cs.Suspended = 0 THEN 1				
				ELSE 0
			END AS [Status],
			ISNULL(wl.IsExistedWatchList,0) AS IsExistedWatchList,
			WinningThreshold,
			LosingThreshold		
	FROM custInfo ci WITH(NOLOCK)
	INNER JOIN customer c WITH(NOLOCK) ON ci.custid = c.custid
	CROSS APPLY	(	SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS Closed
						, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS Suspended							
					FROM dbo.CustProductStatus WITH(NOLOCK)
					WHERE CustID = ci.custid
				 ) AS cs
	OUTER APPLY ( SELECT 1 AS IsExistedWatchList, WinningThreshold, LosingThreshold
				  FROM WLMonitored_Player WITH(NOLOCK) 
				  WHERE CustID = ci.custid
				 ) AS wl
	WHERE ci.recommend = @AgentID
		AND ci.roleid = 1				
		
	SELECT @UnlimitedThresholdUsersList	= CONCAT(@UnlimitedThresholdUsersList, ',', UserName)
	FROM #Temp
	WHERE IsExistedWatchList = 1 AND WinningThreshold IS NULL AND WinningThreshold IS NULL

	SELECT @UnlimitedThresholdCount = @@ROWCOUNT
	
	SELECT 
	  SUM(Status) AS ActiveMembers,
	  SUM(IsExistedWatchList) AS MonitoredMembers,
	  @ReachedDailyLimitCount AS ReachedDailyLimitMembers,
	  @UnlimitedThresholdCount AS UnlimitedThresholdMembers,
	  RIGHT(@UnlimitedThresholdUsersList, LEN(@UnlimitedThresholdUsersList) - 1) AS UnlimitedThresholdUsers
	FROM #Temp
						
	DROP TABLE #Temp
END
GO
