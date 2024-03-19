/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_Personal_Detail_Sel
	 @CustID INT
	,@Sporttype SMALLINT = 0
AS  
/*  
	Created:	20220523@Eden
	Task:		View Personal threshold (specific member)
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20220523@Eden: Alpha - My Monitor Accounts for Risk & Control [Redmine:#170467]

	Param's Explanation:  	

	EXEC Acc_WLMonitored_Personal_Detail_Sel 
		 @CustID = 1176092
		,@Sporttype = 0
	
*/  
BEGIN 
	SELECT CustID
		,Sporttype
		,WinningThreshold
		,LosingThreshold
	FROM WLMonitored_Player WITH(NOLOCK) 
	WHERE CustID = @CustID 
		AND Sporttype = @Sporttype
END
GO