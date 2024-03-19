/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_WLMonitored_CheckExistSettingByCust
	 @CustList	VARCHAR(MAX)
AS  
/*  
	Created:	20230424@Tacy
	Task:		Alpha - Enhance My Watchlist & Problem Accounts to allow SMA control risk effectively
	DB:			DBCUST-CUSTDB
	Original:	
  
	Revisions:  
	    - 20230424@Tacy: Check exist threshold setting by customer  [Redmine:#185312]

	Param's Explanation:  	
*/  
BEGIN 
	SET NOCOUNT ON;

	CREATE TABLE #Cust_Tbl(CustID INT)

	INSERT INTO #Cust_Tbl(CustID)
	SELECT TRIM(value)
	FROM string_split(@CustList,',') 
	WHERE TRIM(value) <> ''

	-- List: exist threshold setting
	SELECT wl.CustID, c.username, 1 as isExistedThreshold
	FROM #Cust_Tbl t
	INNER JOIN WLMonitored_Player wl WITH(NOLOCK) ON t.CustID=wl.CustID
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=t.CustID

	SELECT wl.CustID, c.username, 0 as isExistedThreshold
	FROM #Cust_Tbl t
	LEFT JOIN WLMonitored_Player wl WITH(NOLOCK) ON t.CustID=wl.CustID
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=t.CustID
	WHERE wl.CustID IS NULL

	DROP TABLE #Cust_Tbl
END
GO