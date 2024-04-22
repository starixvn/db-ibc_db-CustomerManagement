/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Player_WatchList_Sel
	 @AgentID INT
	,@Username VARCHAR(30)= ''
	,@Sporttype SMALLINT = 0
	,@SortType       TINYINT = 1
	,@IsDesc	     BIT = 1
	,@ExportAll		 BIT = 0
	,@PageSize       INT     = 50
	,@PageIndex      INT     = 1
	,@TotalItems     INT     = 0 OUTPUT
	,@AddedFromDate  DATETIME
	,@AddedToDate	 DATETIME
	,@Status		 VARCHAR(30) = ''
	,@ProblemAccount TINYINT = 2
AS  
/*  
	Created:	20220523@Eden
	Task:		View Watchlist Accounts
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]
		- 20230327@Tacy: Alpha - Enhance to show First/Last name in reports [RedmineID: #185313]
		- 20230420@Tacy: Alpha - Enhance My Watchlist & Problem Accounts to allow SMA control risk effectively [RedmineID: 185312]
		- 20230626@Tacy: Alpha - Bet List - Enhance Last bet function [Redmine:#186142]
		- 20240411@Kelvin: Alpha - Link WL Detail to My Watchlist [Redmine:#201733]

	Param's Explanation:  	
		- @SortType : ( order by)
			1: Username (default)
			2: LastLogin 
			3: Status
			4: WinningThreshold
			5: LosingThreshold
			6: firstname/lastname
			7: Problem Account
			8: Added Date

		- @ExportAll : 1 ~ no paging, get all
					   0 ~ paging data

		- @Status : 
				Disabled
				Closed
				Suspended
				Locked
				Open

		- @ProblemAccount : 
				= 0: No
				= 1: Yes
				= 2: All
	
	Example:
		DECLARE @TotalItems INT
		EXEC Acc_WLMonitored_Player_WatchList_Sel 
				@AgentID	= 1176086	
				--,@Username	= 'member01'	
				,@SortType = 9
				,@IsDesc = 0
				,@PageSize            = 50
				,@PageIndex           = 1
				,@TotalItems          = @TotalItems OUTPUT
				,@AddedFromDate	= '2022/04/01'
				,@AddedToDate	= '2024/04/12'
				,@Status = ''
				,@ProblemAccount = 2
		SELECT @TotalItems
*/  
BEGIN 
SET NOCOUNT ON;

	DECLARE @RowStart int, @RowEnd int
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #Temp(
		CustID				INT,
		username			VARCHAR(30),
		username2			VARCHAR(50),		
		firstlastname		NVARCHAR(110),
		lastlogged			DATETIME,		
		Status				VARCHAR(10),
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
		recommend			INT,
		Locked				TINYINT,
		ClosedReason		TINYINT,
		IsPA				BIT,
		AddedDate			DATETIME,
		RowNumber			INT IDENTITY(1,1)
	)

	CREATE TABLE #Temp2(
		CustID				INT,
		username			VARCHAR(30),	
		username2			VARCHAR(50),		
		firstlastname		NVARCHAR(110),
		lastlogged			DATETIME,		
		Status				VARCHAR(10),
		WinningThreshold	MONEY,
		LosingThreshold		MONEY,
		recommend			INT,
		Locked				TINYINT,
		ClosedReason		TINYINT,
		IsPA				BIT,
		AddedDate			DATETIME,
		RowNumber			INT IDENTITY(1,1)
	)

	INSERT INTO #Temp(
		 CustID			
		,username
		,username2	
		,firstlastname
		,lastlogged		
		,Status			
		,WinningThreshold
		,LosingThreshold	
		,recommend	
		,Locked
		,ClosedReason
		,IsPA
		,AddedDate
	)
	SELECT  
		ci.custid,
		ci.username, c.username2,
		CASE WHEN c.firstname IS NOT NULL AND c.firstname NOT IN ('NULL','') AND c.lastname IS NOT NULL AND c.lastname NOT IN ('NULL','')	THEN firstname + '/ ' + lastname
			 WHEN c.firstname IS NOT NULL AND c.firstname NOT IN ('NULL','') AND (c.lastname IS NULL	OR c.lastname IN ('NULL',''))		THEN firstname
			 WHEN (c.firstname IS NULL	  OR c.firstname IN ('NULL',''))	 AND c.lastname IS NOT NULL AND c.lastname NOT IN ('NULL','')	THEN lastname
			 ELSE ''
		END firstlastname,
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
		ISNULL(lg.ClosedReason,0),
		ISNULL(pa.IsPA,0),
		per.CreatedDate
	FROM WLMonitored_Player per WITH(NOLOCK) 
		INNER JOIN custInfo ci WITH(NOLOCK) ON per.custid = ci.custid AND ci.roleid = 1
		INNER JOIN customer c WITH(NOLOCK) ON ci.custid = c.custid
		OUTER APPLY (SELECT TOP 1 cc.CustomerClass 
					FROM CategoryConfig cc WITH (NOLOCK) 
					WHERE cc.CustomerClass=ci.CustomerClass AND HiddenSite NOT IN (1,3)
					) cc
		OUTER APPLY (SELECT CASE WHEN p.custid IS NOT NULL AND cc.CustomerClass IS NOT NULL THEN 1 ELSE 0 END IsPA
					 FROM ProblemAccountClassification p WITH(NOLOCK) 
					 WHERE per.custid = p.custid
					 ) pa	--Problem Account		
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
		AND per.CreatedDate >= @AddedFromDate
		AND per.CreatedDate < @AddedToDate + 1
		AND (	CASE WHEN ci.Enabled = 0 THEN 'Disabled'
					WHEN cs.closed = 1 THEN 'Closed'
					WHEN cs.reject = 1 THEN 'Suspended'
					WHEN cs.Locked > 0 THEN 'Locked'
					ELSE 'Open'
				END = @Status
				OR ISNULL(@Status,'') = ''	
			)
		AND (ISNULL(pa.IsPA,0) = @ProblemAccount OR @ProblemAccount = 2)

	INSERT INTO #Temp2(
		 CustID				
		,recommend			
		,username	
		,username2
		,firstlastname			
		,lastlogged		
		,Status				
		,WinningThreshold	
		,LosingThreshold
		,Locked
		,ClosedReason
		,IsPA
		,AddedDate
	)
	SELECT t.CustID				
		,t.recommend			
		,t.username
		,t.username2
		,firstlastname
		,lastlogged		
		,Status				
		,WinningThreshold	
		,LosingThreshold	
		,Locked
		,ClosedReason
		,IsPA
		,AddedDate
	FROM #Temp t
	ORDER BY	CASE WHEN @SortType = 1 AND @IsDesc = 0 THEN t.username END ASC,
				CASE WHEN @SortType = 2 AND @IsDesc = 0 THEN lastlogged END ASC,
				CASE WHEN @SortType = 3 AND @IsDesc = 0 THEN Status END ASC,
				CASE WHEN @SortType = 4 AND @IsDesc = 0 THEN WinningThreshold END ASC,
				CASE WHEN @SortType = 5 AND @IsDesc = 0 THEN LosingThreshold END ASC,
				CASE WHEN @SortType = 6 AND @IsDesc = 0 THEN firstlastname END ASC,
				CASE WHEN @SortType = 7 AND @IsDesc = 0 THEN IsPA END ASC,
				CASE WHEN @SortType = 8 AND @IsDesc = 0 THEN AddedDate END ASC,
				-----------
				CASE WHEN @SortType = 1 AND @IsDesc = 1 THEN t.username END DESC,
				CASE WHEN @SortType = 2 AND @IsDesc = 1 THEN lastlogged END DESC,
				CASE WHEN @SortType = 3 AND @IsDesc = 1 THEN Status END DESC,
				CASE WHEN @SortType = 4 AND @IsDesc = 1 THEN WinningThreshold END DESC,
				CASE WHEN @SortType = 5 AND @IsDesc = 1 THEN LosingThreshold END DESC,
				CASE WHEN @SortType = 6 AND @IsDesc = 1 THEN firstlastname END DESC,
				CASE WHEN @SortType = 7 AND @IsDesc = 1 THEN IsPA END DESC,
				CASE WHEN @SortType = 8 AND @IsDesc = 1 THEN AddedDate END DESC,
				t.Username ASC

	SELECT @TotalItems = COUNT(1) 
	FROM #Temp2

	IF @ExportAll=1
	BEGIN
		SELECT CustID, username, username2
		FROM  #Temp2 t
		ORDER BY username
	END
	ELSE
	BEGIN
		SELECT t.CustID				
			,recommend			
			,username		
			,firstlastname
			,lastlogged			
			,Status						
			,WinningThreshold	
			,LosingThreshold
			,Locked
			,ClosedReason
			,IsPA
			,AddedDate
			,RowNumber
		FROM  #Temp2 t
		WHERE RowNumber BETWEEN @rowstart AND @rowend
		ORDER BY RowNumber
	END

	DROP TABLE #Temp
	DROP TABLE #Temp2
END
GO