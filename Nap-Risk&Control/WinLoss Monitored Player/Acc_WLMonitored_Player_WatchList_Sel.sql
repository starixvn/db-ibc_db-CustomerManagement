/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Player_WatchList_Sel
	 @AgentID INT
	,@Username VARCHAR(30)= ''
	,@Sporttype SMALLINT = 0
	,@SortType       TINYINT = 1
	,@IsDesc	     BIT = 1
	,@PageSize       INT     = 50
	,@PageIndex      INT     = 1
	,@TotalItems     INT     = 0 OUTPUT
AS  
/*  
	Created:	20220523@Eden
	Task:		View Watchlist Accounts
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	
		- @SortType : ( order by)
			1: Username (default)
			2: LastLogin 
			3: Status
			4: WinningThreshold
			5: LosingThreshold

	DECLARE @TotalItems INT
	EXEC Acc_WLMonitored_Player_WatchList_Sel 
		    @AgentID	= 1176086	
			--,@Username	= 'member01'	
			,@SortType = 9
			,@IsDesc = 0
			,@PageSize            = 50
			,@PageIndex           = 1
			,@TotalItems          = @TotalItems OUTPUT
	SELECT @TotalItems
	
*/  
BEGIN 
	DECLARE @RowStart int, @RowEnd int
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Temp(
		CustID				INT,
		username			VARCHAR(30),
		lastlogged			DATETIME,
		Status				VARCHAR(10),
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
		recommend			INT,
		Locked				TINYINT,
		ClosedReason		TINYINT,
		RowNumber			INT IDENTITY(1,1)
	)

	CREATE TABLE #Temp2(
		CustID				INT,
		username			VARCHAR(30),
		lastlogged			DATETIME,
		Status				VARCHAR(10),
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
		recommend			INT,
		Locked				TINYINT,
		ClosedReason		TINYINT,
		RowNumber			INT IDENTITY(1,1)
	)

	INSERT INTO #Temp(
		 CustID			
		,username		
		,lastlogged		
		,Status			
		,WinningThreshold
		,LosingThreshold	
		,recommend	
		,Locked
		,ClosedReason
	)
	SELECT ci.custid,
		ci.username,
		c.lastlogged,
		CASE WHEN ci.Enabled = 0 THEN 'Disabled'
			 WHEN cs.closed = 1 THEN 'Closed'
			 WHEN cs.reject = 1 THEN 'Suspended'
			 WHEN cs.Locked > 0 THEN 'Locked'
			 ELSE 'Open'
			END AS Status,
		per.WinningThreshold,
		per.LosingThreshold,
		ci.recommend,
		ISNULL(cs.Locked,0),
		ISNULL(lg.ClosedReason,0)
	FROM WLMonitored_Player per WITH(NOLOCK) 
		INNER JOIN custInfo ci WITH(NOLOCK) ON per.custid = ci.custid AND ci.roleid = 1
		INNER JOIN customer c WITH(NOLOCK) ON ci.custid = c.custid
		LEFT JOIN CustLoginInfo_Member lg WITH(NOLOCK) ON lg.CustID = ci.custid
		CROSS APPLY  (	SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
							, Locked
						FROM dbo.CustProductStatus WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS cs	
	WHERE per.agentID = @AgentID
		AND per.Sporttype = @Sporttype
		AND ci.username LIKE  '%' + ISNULL(@Username,'') + '%'

	INSERT INTO #Temp2(
		 CustID				
		,recommend			
		,username			
		,lastlogged			
		,Status				
		,WinningThreshold	
		,LosingThreshold
		,Locked
		,ClosedReason
	)
	SELECT CustID				
		,recommend			
		,username			
		,lastlogged			
		,Status				
		,WinningThreshold	
		,LosingThreshold	
		,Locked
		,ClosedReason
	FROM #Temp
	ORDER BY	CASE WHEN @SortType = 1 AND @IsDesc = 0 THEN username END ASC,
				CASE WHEN @SortType = 2 AND @IsDesc = 0 THEN lastlogged END ASC,
				CASE WHEN @SortType = 3 AND @IsDesc = 0 THEN Status END ASC,
				CASE WHEN @SortType = 4 AND @IsDesc = 0 THEN WinningThreshold END ASC,
				CASE WHEN @SortType = 5 AND @IsDesc = 0 THEN LosingThreshold END ASC,
				-----------
				CASE WHEN @SortType = 1 AND @IsDesc = 1 THEN username END DESC,
				CASE WHEN @SortType = 2 AND @IsDesc = 1 THEN lastlogged END DESC,
				CASE WHEN @SortType = 3 AND @IsDesc = 1 THEN Status END DESC,
				CASE WHEN @SortType = 4 AND @IsDesc = 1 THEN WinningThreshold END DESC,
				CASE WHEN @SortType = 5 AND @IsDesc = 1 THEN LosingThreshold END DESC,
				Username ASC

	SELECT @TotalItems = COUNT(1) 
	FROM #Temp2

	SELECT CustID				
		,recommend			
		,username			
		,lastlogged			
		,Status						
		,WinningThreshold	
		,LosingThreshold
		,Locked
		,ClosedReason
		,RowNumber
	FROM  #Temp2
	WHERE RowNumber BETWEEN @rowstart AND @rowend
	ORDER BY RowNumber

	DROP TABLE #Temp
	DROP TABLE #Temp2
END
GO