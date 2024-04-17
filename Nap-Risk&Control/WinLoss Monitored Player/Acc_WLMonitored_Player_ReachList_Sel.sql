/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Player_ReachList_Sel
	 @AgentID		 INT
	,@Username		 VARCHAR(30)= ''
	,@Sporttype		 SMALLINT = 0
	,@Status		 VARCHAR(MAX) = ''
	,@SortType       TINYINT = 1
	,@IsDesc	     BIT = 1
	,@PageSize       INT = 50
	,@PageIndex      INT = 1
	,@TotalItems     INT = 0 OUTPUT
	,@XMLReachList	 VARCHAR(MAX)
AS  
/*  
	Created:	20220523@Eden
	Task:		View Reached threshold accounts
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]
		- 20230327@Tacy: Alpha - Enhance to show First/Last name in reports [RedmineID: #185313]
		- 20230420@Tacy: Alpha - Enhance My Watchlist & Problem Accounts to allow SMA control risk effectively [RedmineID: 185312]

	Param's Explanation:  	
		- @LimitType : 
				= 1: Global
				= 2: Personal
				= 0: All
		- @Status: 
				Disabled
				Closed
				Suspended
				Open
		- @SortType : ( order by)
			1: Username (default)
			2: LastLogin 
			3: Status
			4: LastReach
			5: LastLimitTypeReach
			6: Winning/Losing Amount
			7: LastReachWinningThreshold
			8: LastReachLosingThreshold
			9: NoOfReach
			10:first/lastname
			11: Problem Account

	DECLARE @TotalItems INT
	EXEC Acc_WLMonitored_Player_ReachList_Sel 
		    @AgentID	= 1176086	
			--,@Username	= 'member01'	
			,@Status = ''
			,@SortType = 9
			,@IsDesc = 1
			,@PageSize            = 50
			,@PageIndex           = 1
			,@TotalItems          = @TotalItems OUTPUT
			,@XMLReachList	= '<ROOT>
								  <R CustID="1176092" Cnt="1" AccumWL="66650.0000" WinningThreshold="100.0000" LosingThreshold="0.0000" LastLimitTypeReach="2" CreatedDate="2022-07-20T00:00:00" WCnt="1" LCnt="0" />
								  <R CustID="1584729" Cnt="1" AccumWL="66650.0000" WinningThreshold="1000.0000" LosingThreshold="5000.0000" LastLimitTypeReach="2" CreatedDate="2022-07-20T00:00:00" WCnt="1" LCnt="0" />
								  <R CustID="1676188" Cnt="1" AccumWL="66650.0000" WinningThreshold="100.0000" LosingThreshold="200.0000" LastLimitTypeReach="2" CreatedDate="2022-07-20T00:00:00" WCnt="1" LCnt="0" />
								  <R CustID="1711031" Cnt="1" AccumWL="66650.0000" WinningThreshold="1111.0000" LosingThreshold="2222.0000" LastLimitTypeReach="2" CreatedDate="2022-07-20T00:00:00" WCnt="1" LCnt="0" />
								  <R CustID="1773789" Cnt="1" AccumWL="66650.0000" WinningThreshold="1000.0000" LosingThreshold="1235.0000" LastLimitTypeReach="2" CreatedDate="2022-07-20T00:00:00" WCnt="1" LCnt="0" />
								  <R CustID="2211693" Cnt="4" AccumWL="-146270.0000" WinningThreshold="1000.0000" LosingThreshold="2000.0000" LastLimitTypeReach="2" CreatedDate="2022-07-27T02:39:04.903" WCnt="1" LCnt="3" />
								</ROOT>'
		SELECT @TotalItems
	
*/  
BEGIN 
	DECLARE @RowStart int, @RowEnd int
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #TempHistory(
		[CustID] [int],
		[ReachedCnt] [int],
		[AccumWL] [money],
		[WinningThreshold] [money],
		[LosingThreshold] [money],
		[LastLimitTypeReach] [tinyint],
		[CreatedDate] [datetime],
		[WinningReachedCnt] [int],
		[LosingReachedCnt] [int]
	)

	CREATE TABLE #Temp(
		CustID				INT,
		recommend			INT,
		username			VARCHAR(30),
		firstlastname		NVARCHAR(110),
		lastlogged			DATETIME,
		Status				VARCHAR(10),
		LastReachedDate		DATETIME,
		LastLimitTypeReach	VARCHAR(10),
		WinLossAmount		MONEY,
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
		Locked				TINYINT,
		ClosedReason		TINYINT,
		ReachedCnt			INT,
		[WinningReachedCnt] [int],
		[LosingReachedCnt]  [int],
		IsPA				BIT
	)
	CREATE TABLE #Temp2(
		CustID				INT,
		recommend			INT,
		username			VARCHAR(30),
		firstlastname		NVARCHAR(110),
		lastlogged			DATETIME,
		Status				VARCHAR(10),
		LastReachedDate		DATETIME,
		LastLimitTypeReach	VARCHAR(10),
		WinLossAmount		MONEY,
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
		Locked				TINYINT,
		ClosedReason		TINYINT,
		ReachedCnt			INT,
		RowNumber			INT IDENTITY(1,1),
		[WinningReachedCnt] [int],
		[LosingReachedCnt]  [int],
		IsPA				BIT
	)

	DECLARE @DocHandler INT	

	IF ISNULL(@XMLReachList,'') <> ''
	BEGIN
		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @XMLReachList

		INSERT INTO #TempHistory(CustID,ReachedCnt,AccumWL,WinningThreshold,LosingThreshold,LastLimitTypeReach,CreatedDate,WinningReachedCnt,LosingReachedCnt)
		SELECT CustID,Cnt,AccumWL,WinningThreshold,LosingThreshold,LastLimitTypeReach,CreatedDate,WCnt,LCnt
		FROM OPENXML (@DocHandler, '/ROOT/R',1) 
		WITH (
			[CustID] [int],
			[Cnt] [int],
			[AccumWL] [money],
			[WinningThreshold] [money],
			[LosingThreshold] [money],
			[LastLimitTypeReach] [tinyint],
			[CreatedDate] [datetime],
			[WCnt] [int],
			[LCnt] [int]
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
	END		

	INSERT INTO #Temp(
		 CustID				
		,recommend			
		,username	
		,firstlastname
		,lastlogged			
		,Status				
		,LastReachedDate		
		,LastLimitTypeReach	
		,WinLossAmount		
		,WinningThreshold	
		,LosingThreshold		
		,ReachedCnt	
		,Locked		
		,ClosedReason
		,WinningReachedCnt
		,LosingReachedCnt
		,IsPA
	)
	SELECT ci.custid,
		ci.recommend,
		ci.username,
		CASE WHEN c.firstname IS NOT NULL AND c.firstname NOT IN ('NULL','') AND c.lastname IS NOT NULL AND c.lastname NOT IN ('NULL','')	THEN firstname + '/ ' + lastname
			 WHEN c.firstname IS NOT NULL AND c.firstname NOT IN ('NULL','') AND (c.lastname IS NULL	OR c.lastname IN ('NULL',''))		THEN firstname
			 WHEN (c.firstname IS NULL	  OR c.firstname IN ('NULL',''))	 AND c.lastname IS NOT NULL AND c.lastname NOT IN ('NULL','')	THEN lastname
			 ELSE ''
		END firstlastname,
		c.lastlogged,
		CASE WHEN ci.Enabled = 0 THEN 'Disabled'
			 WHEN cs.closed = 1 THEN 'Closed'
			 WHEN cs.reject = 1 THEN 'Suspended'
			 ELSE 'Open'
			END AS Status,
		his.CreatedDate AS LastReachedDate,
		CASE WHEN his.LastLimitTypeReach = 2 THEN 'Personal' ELSE 'Global' END AS LastLimitTypeReach,
		his.AccumWL AS WinLossAmount,
		his.WinningThreshold,
		his.LosingThreshold,
		his.ReachedCnt,
		ISNULL(cs.Locked,0),		
		ISNULL(lg.ClosedReason,0),
		his.WinningReachedCnt,
		his.LosingReachedCnt,
		CASE WHEN p.custid IS NOT NULL AND cc.CustomerClass IS NOT NULL
			 THEN 1 ELSE 0
		END IsPA
	FROM custInfo ci WITH(NOLOCK)
		INNER JOIN customer c WITH(NOLOCK) ON ci.custid = c.custid
		LEFT JOIN CustLoginInfo_Member lg WITH(NOLOCK) ON lg.CustID = ci.custid
		LEFT JOIN ProblemAccountClassification p WITH(NOLOCK) ON ci.custid = p.custid	--Problem Account
		OUTER APPLY (SELECT TOP 1 cc.CustomerClass FROM CategoryConfig cc WITH (NOLOCK) WHERE cc.CustomerClass=ci.CustomerClass AND HiddenSite NOT IN (1,3)) cc
		CROSS APPLY  (	SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
							, Locked
						FROM dbo.CustProductStatus  WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS cs	
		INNER JOIN #TempHistory his WITH(NOLOCK) 
			ON his.custid = ci.custid
	WHERE ci.recommend = @AgentID
		AND ci.roleid = 1
		AND ci.Enabled = 1
		AND ci.username LIKE  '%' + ISNULL(@Username,'') + '%'
		AND (	CASE WHEN ci.Enabled = 0 THEN 'Disabled'
					 WHEN cs.closed = 1 THEN 'Closed'
					 WHEN cs.reject = 1 THEN 'Suspended'
					 ELSE 'Open'
					 END = @Status
				OR ISNULL(@Status,'') = ''	
			)
	
	INSERT INTO #Temp2(
		 CustID				
		,recommend			
		,username	
		,firstlastname
		,lastlogged			
		,Status				
		,LastReachedDate		
		,LastLimitTypeReach	
		,WinLossAmount		
		,WinningThreshold	
		,LosingThreshold		
		,ReachedCnt		
		,Locked		
		,ClosedReason
		,WinningReachedCnt
		,LosingReachedCnt
		,IsPA
	)
	SELECT t.CustID				
		,t.recommend			
		,t.username	
		, firstlastname
		,lastlogged			
		,Status				
		,LastReachedDate		
		,LastLimitTypeReach	
		,WinLossAmount		
		,WinningThreshold	
		,LosingThreshold		
		,ReachedCnt	
		,Locked		
		,ClosedReason
		,WinningReachedCnt
		,LosingReachedCnt
		,IsPA 
	FROM #Temp t
	ORDER BY	CASE WHEN @SortType = 1 AND @IsDesc = 0 THEN t.username END ASC,
				CASE WHEN @SortType = 2 AND @IsDesc = 0 THEN lastlogged END ASC,
				CASE WHEN @SortType = 3 AND @IsDesc = 0 THEN Status END ASC,
				CASE WHEN @SortType = 4 AND @IsDesc = 0 THEN LastReachedDate END ASC,
				CASE WHEN @SortType = 5 AND @IsDesc = 0 THEN LastLimitTypeReach END ASC,
				CASE WHEN @SortType = 6 AND @IsDesc = 0 THEN WinLossAmount END ASC,
				CASE WHEN @SortType = 7 AND @IsDesc = 0 THEN WinningThreshold END ASC,
				CASE WHEN @SortType = 8 AND @IsDesc = 0 THEN LosingThreshold END ASC,
				CASE WHEN @SortType = 9 AND @IsDesc = 0 THEN ReachedCnt END ASC,
				CASE WHEN @SortType = 10 AND @IsDesc = 0 THEN firstlastname END ASC,
				CASE WHEN @SortType = 11 AND @IsDesc = 0 THEN IsPA END ASC,

				-----------
				CASE WHEN @SortType = 1 AND @IsDesc = 1 THEN t.username END DESC,
				CASE WHEN @SortType = 2 AND @IsDesc = 1 THEN lastlogged END DESC,
				CASE WHEN @SortType = 3 AND @IsDesc = 1 THEN Status END DESC,
				CASE WHEN @SortType = 4 AND @IsDesc = 1 THEN LastReachedDate END DESC,
				CASE WHEN @SortType = 5 AND @IsDesc = 1 THEN LastLimitTypeReach END DESC,
				CASE WHEN @SortType = 6 AND @IsDesc = 1 THEN WinLossAmount END DESC,
				CASE WHEN @SortType = 7 AND @IsDesc = 1 THEN WinningThreshold END DESC,
				CASE WHEN @SortType = 8 AND @IsDesc = 1 THEN LosingThreshold END DESC,
				CASE WHEN @SortType = 9 AND @IsDesc = 1 THEN ReachedCnt END DESC,
				CASE WHEN @SortType = 10 AND @IsDesc = 1 THEN firstlastname END DESC,
				CASE WHEN @SortType = 11 AND @IsDesc = 1 THEN IsPA END DESC,
				t.Username ASC, LastReachedDate DESC

	SELECT @TotalItems = COUNT(1) 
	FROM #Temp2

	SELECT CustID				
		,recommend			
		,username
		,firstlastname
		,lastlogged			
		,Status				
		,LastReachedDate		
		,LastLimitTypeReach	
		,WinLossAmount		
		,WinningThreshold	
		,LosingThreshold		
		,ReachedCnt	
		,Locked		
		,ClosedReason
		,RowNumber
		,WinningReachedCnt
		,LosingReachedCnt
		,IsPA
	FROM  #Temp2
	WHERE RowNumber BETWEEN @rowstart AND @rowend
	ORDER BY RowNumber
	
	DROP TABLE #Temp
	DROP TABLE #Temp2
	DROP TABLE #TempHistory
END
GO
