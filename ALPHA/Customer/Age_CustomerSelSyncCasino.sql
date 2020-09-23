/*<info serverAlias="DBAGE-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelSyncCasino]
	  @Custs VARCHAR(MAX)
AS
/*
	Created: 20200911@Winfred
	DB: DBAGE/bodb02
	Task: Mobile - Search list customer - Info

	Revisions:
		- 20200911@Winfred : Get Sync Casino from list Customer [Redmine: #137130]    
		
	Param's Explanation:
		• @ListCust: list username of customer that need to be viewed.
	Example: exec Age_CustomerSelSyncCasino @Custs='41075587 ,888999111 ,41075557 ,41075791,43666258'	
*/

BEGIN
    SET NOCOUNT ON

	--Check if XML is null or empty
	IF @Custs IS NULL OR @Custs = ''
		RETURN
	
	CREATE TABLE #ListCust_Temp( CustID	INT )

	INSERT INTO #ListCust_Temp(CustID)
	SELECT CAST(ss.val AS INT) as CustID	
	FROM dbo.strSplit(ISNULL(@Custs, ''), ',') AS ss

	-------------------------------------------------------------------------
    SELECT	a.CustID,b.SyncCasino			
    FROM #ListCust_Temp a 
	    LEFT JOIN custinfo b WITH (NOLOCK) ON a.CustID = b.custid
    
END	
GO