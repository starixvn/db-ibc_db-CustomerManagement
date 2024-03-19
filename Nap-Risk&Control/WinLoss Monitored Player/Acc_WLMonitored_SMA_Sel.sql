/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_SMA_Sel
	 @CustID INT
	,@Sporttype SMALLINT = 0
AS  
/*  
	Created:	20221220@Eden
	Task:		View SMA threshold
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20221220@Eden: Alpha - Monitor SMA Win Loss [Redmine:#179067]

	Param's Explanation:  	

	EXEC Acc_WLMonitored_SMA_Sel 
		 @CustID = 1176086
		,@Sporttype = 0
	
*/  
BEGIN 
	SELECT CustID
		,Sporttype
		,WinningThreshold
		,LosingThreshold
	FROM WLMonitored_SMA WITH(NOLOCK) 
	WHERE CustID = @CustID 
		AND Sporttype = @Sporttype
END
GO