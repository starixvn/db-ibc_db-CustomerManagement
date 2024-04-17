/*<info serverAlias="DBAGE-bodb02" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_WLMonitored_SMA_ReachDetail_Sel
	 @CustID INT
	,@Sporttype SMALLINT = 0
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@SortType  TINYINT = 1
	,@IsDesc	BIT = 1
AS  
/*  
	Created:	20221220@Eden
	Task:		View Reached my threshold history of SMA
	DB:			DBAGE-bodb02
	Original:	
  
	Revisions:  
	    - 20221220@Eden: Alpha - Monitor SMA Win Loss [Redmine:#179067]

	Param's Explanation:  	
	- @SortType : (order by)
			1: DateTime (default)
			2: Winning/Losing Amount
			3: WinningThreshold
			4: LosingThreshold

	EXEC Acc_WLMonitored_SMA_ReachDetail_Sel 
		     @CustID	= 2211693	
			,@Sporttype = 0
			,@FromDate = '2022/05/01'
			,@ToDate = '2022/08/02'
			,@SortType  = 1
			,@IsDesc = 1
	
*/  
BEGIN 
	SELECT ci.CustID
		, @Sporttype  AS Sporttype 
		, w.CreatedDate
		, w.AccumWL AS WinLossAmount
		, w.WinningThreshold
		, w.LosingThreshold
		, w.ReachType -- 1: Winning reach 2: Losing reach
		, RowNumber = ROW_NUMBER() OVER( ORDER BY   CASE WHEN @SortType = 1 AND @IsDesc = 0 THEN w.CreatedDate END ASC,
													CASE WHEN @SortType = 2 AND @IsDesc = 0 THEN w.AccumWL END ASC,
													CASE WHEN @SortType = 3 AND @IsDesc = 0 THEN w.WinningThreshold END ASC,
													CASE WHEN @SortType = 4 AND @IsDesc = 0 THEN w.LosingThreshold END ASC,
													-----------
													CASE WHEN @SortType = 1 AND @IsDesc = 1 THEN w.CreatedDate END DESC,
													CASE WHEN @SortType = 2 AND @IsDesc = 1 THEN w.AccumWL END DESC,
													CASE WHEN @SortType = 3 AND @IsDesc = 1 THEN w.WinningThreshold END DESC,
													CASE WHEN @SortType = 4 AND @IsDesc = 1 THEN w.LosingThreshold END DESC,
													w.CreatedDate DESC
										)
	FROM WLMonitored_Player_History w WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON ci.custid = w.custid
	WHERE w.CustID = @CustID
		AND sporttype = @Sporttype
		AND ci.roleid IN (2,3,4)
		AND w.CreatedDate >= @FromDate
		AND w.CreatedDate < @ToDate + 1
END
GO