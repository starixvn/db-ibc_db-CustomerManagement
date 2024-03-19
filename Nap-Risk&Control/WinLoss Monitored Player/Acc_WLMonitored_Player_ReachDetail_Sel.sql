/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_WLMonitored_Player_ReachDetail_Sel
	 @CustID INT
	,@Sporttype SMALLINT = 0
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@LimitType TINYINT = 0
	,@SortType  TINYINT = 1
	,@IsDesc	BIT = 1
AS  
/*  
	Created:	20220523@Eden
	Task:		View Reached threshold history of specific member
	DB:			DBAGE-bodb02
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	
	- @SortType : (order by)
			1: DateTime (default)
			2: ThresholdType 
			3: Winning/Losing Amount
			4: WinningThreshold
			5: LosingThreshold

	EXEC Acc_WLMonitored_Player_ReachDetail_Sel 
		     @CustID	= 2211693	
			,@Sporttype = 0
			,@FromDate = '2022/05/01'
			,@ToDate = '2022/08/02'
			,@LimitType = 0
			,@SortType  = 5
			,@IsDesc = 1
	
*/  
BEGIN 
	SELECT ci.CustID
		, @Sporttype  AS Sporttype 
		, w.CreatedDate
		, CASE WHEN w.SettingType = 2 THEN 'Personal' ELSE 'Global' END AS LimitTypeReach
		, w.AccumWL AS WinLossAmount
		, w.WinningThreshold
		, w.LosingThreshold
		, w.ReachType -- 1: Winning reach 2: Losing reach
		, RowNumber = ROW_NUMBER() OVER( ORDER BY   CASE WHEN @SortType = 1 AND @IsDesc = 0 THEN w.CreatedDate END ASC,
													CASE WHEN @SortType = 2 AND @IsDesc = 0 THEN w.SettingType END ASC,
													CASE WHEN @SortType = 3 AND @IsDesc = 0 THEN w.AccumWL END ASC,
													CASE WHEN @SortType = 4 AND @IsDesc = 0 THEN w.WinningThreshold END ASC,
													CASE WHEN @SortType = 5 AND @IsDesc = 0 THEN w.LosingThreshold END ASC,
													-----------
													CASE WHEN @SortType = 1 AND @IsDesc = 1 THEN w.CreatedDate END DESC,
													CASE WHEN @SortType = 2 AND @IsDesc = 1 THEN w.SettingType END DESC,
													CASE WHEN @SortType = 3 AND @IsDesc = 1 THEN w.AccumWL END DESC,
													CASE WHEN @SortType = 4 AND @IsDesc = 1 THEN w.WinningThreshold END DESC,
													CASE WHEN @SortType = 5 AND @IsDesc = 1 THEN w.LosingThreshold END DESC,
													w.CreatedDate DESC
										)
	FROM WLMonitored_Player_History w WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON ci.custid = w.custid
	WHERE w.CustID = @CustID
		AND sporttype = @Sporttype
		AND ci.roleid = 1
		AND w.CreatedDate >= @FromDate
		AND w.CreatedDate < @ToDate + 1
		AND (w.SettingType = @LimitType OR @LimitType = 0)
END
GO