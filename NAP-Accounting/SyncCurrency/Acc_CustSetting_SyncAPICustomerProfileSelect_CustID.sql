
ALTER PROCEDURE dbo.Acc_CustSetting_SyncAPICustomerProfileSelect_CustID
	@CustIDs	VARCHAR(MAX)	= NULL
AS 
/*
	Created by: Jamie@20161101
	Task: Getting the list of customers' profile [RedmineID:#65873 ]
	DB: DBCUST.bodb02 

	Param's Explanation: 	
		EXEC Acc_CustSetting_SyncAPICustomerProfileSelect_CustID @CustIDs ='7548,7404'

*/
BEGIN
	SET NOCOUNT ON 

	--DECLARE @tmpCurrList TABLE(
	--	Currency		INT PRIMARY KEY
	--	,CurrencyNAME	NVARCHAR(50)
	--	,ActualRate		FLOAT 
	--)

	--INSERT INTO @tmpCurrList(Currency,CurrencyNAME,ActualRate)
	--EXEC Acc_ExchangeSel_Sync_NG2	-- Allowed currencies 

	CREATE TABLE #tmpCustIDs(
		CustID INT
	)
	INSERT INTO #tmpCustIDs(CustID)
	SELECT CAST(RTRIM(LTRIM(Val)) AS INT) FROM strSplit(@CustIDs,',');

	WITH cteCustInfo(CustID, UserName, RoleID, RoleName, UplineID, Currency,isSync)	AS (
		SELECT	ci.CustID
				,ci.Username
				,ci.RoleID 
				,CASE WHEN ci.RoleID = 1 THEN 'Member'
					  WHEN ci.RoleID = 2 THEN 'Agent'
					  WHEN ci.RoleID = 3 THEN 'Master'
					  WHEN ci.RoleID = 4 THEN 'Super'
					  ELSE '' END AS RoleName
				,CASE WHEN ci.RoleID = 1 THEN ci.recommend 
					  WHEN ci.RoleID = 2 THEN ci.mrecommend
					  WHEN ci.RoleID = 3 THEN ci.srecommend
					  WHEN ci.RoleID = 4 THEN ci.srecommend
					  ELSE 0 END AS UplineID
				,ci.Currency 
				,(SELECT value FROM dbo.f_CustSetting_ProductStatusSel(cps.bitmapHasSynced,4)) AS isSync   --@BitmapOrder= 4
		FROM	CustInfo ci WITH (NOLOCK)
				INNER JOIN dbo.CustProductStatus cps  WITH (NOLOCK) ON ci.CustID = cps.CustID 
		WHERE	ci.CustID IN (SELECT CustID FROM #tmpCustIDs WITH (NOLOCK))
	)
	SELECT	cte.CustID
			,cte.UserName
			,cte.RoleID
			,cte.RoleName
			,cte.UplineID
			,cte.Currency
			,cte.isSync
			,e.currency AS CurrencyName
			,u.Username AS UplineUserName 
	FROM	cteCustInfo cte 
			LEFT JOIN CustInfo u WITH (NOLOCK) ON cte.UplineID = u.CustID 
			LEFT JOIN Exchange e WITH (NOLOCK) ON cte.Currency = e.exchangeid;
						
END
GO
GRANT  EXECUTE  ON [dbo].Acc_CustSetting_SyncAPICustomerProfileSelect_CustID  TO [bodbAdminNet]
GO
GRANT  EXECUTE  ON [dbo].Acc_CustSetting_SyncAPICustomerProfileSelect_CustID  TO [vnteam]
GO


