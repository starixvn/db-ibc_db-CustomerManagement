/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_Configuration_Sel]
	@FunctionType	TINYINT = 0
	,@BeginTime		SMALLDATETIME = NULL
	,@EndTime		SMALLDATETIME = NULL
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Get UMConfig to grid
	DB: DBCUST.CustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]
		- 20220728@Eddie:  config UM for Reports/ Bet List [RedmineID: #174852]
		- 20220817@Eddie:  change code by function 'f_CustReport_UM_ProductsSel' [RedmineID: #174852]
		- 20230208@Eddie:  Remove SP: "Acc_UMTool_MarketSel" and Add parameters to using for filter conditions [RedmineID: #182841]

	Param's Explanation:   
		
	Examples : 
		EXEC [Acc_UMTool_Configuration_Sel] 
		
*/
	SET NOCOUNT ON

	SELECT @FunctionType = ISNULL(@FunctionType, 0)
	
	IF @BeginTime IS NOT NULL
	BEGIN
		SELECT @BeginTime = DATEADD(hh,-12,@BeginTime)
	END
	
	IF @EndTime IS NOT NULL
	BEGIN
		SELECT @EndTime = DATEADD(hh,-12,@EndTime)
	END
	
	SELECT c.configID
		,c.FunctionType
		,c.ProductID
		,c.SportType
		,c.BetType
		,c.IsLive
		,c.SettingType
		,c.SiteID
		,c.currency
		,SuperID
		,FunctionTypeName = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(FunctionType))
		,ISNULL(p.ProductName,'All') 	AS ProductName
		,ISNULL(sp.SportName,'All') 	AS SportName
		,ISNULL(st.SettingName,'All') 	AS SettingName
		,ISNULL(s.Site,'All') 			AS Site
		,ISNULL(e.currency,'All') 		AS CurrencyName
		,CASE WHEN c.SuperID = 0 THEN 'All'
			  WHEN ci.CustID IS NOT NULL THEN ci.username
			  ELSE 'N/A' END AS UserName
		,CONVERT(VARCHAR,DATEADD(hh,12,c.ShowTime),20) 	AS ShowTime
		,CONVERT(VARCHAR,DATEADD(hh,12,c.BeginTime),20) AS BeginTime
		,CONVERT(VARCHAR,DATEADD(hh,12,c.EndTime),20) 	AS EndTime
		,ISNULL(c.LockAddingNew,0) AS LockAddingNew
	FROM UMConfig c WITH(NOLOCK) 
		LEFT JOIN ProductSettingType st WITH(NOLOCK) ON c.SettingType = st.SettingType
		LEFT JOIN DBPRO.bodb02.dbo.Products p WITH(NOLOCK) ON c.ProductID = p.ProductID
		LEFT JOIN DBPRO.bodb02.dbo.Sports sp WITH(NOLOCK) ON c.sporttype = sp.sporttype
		LEFT JOIN Site s WITH(NOLOCK) ON c.SiteID = s.siteid
		LEFT JOIN exchange e WITH(NOLOCK) ON c.Currency = e.ExchangeId
		LEFT JOIN customer ci WITH(NOLOCK) ON c.SuperID = ci.custid AND ci.roleid = 4
	WHERE (c.FunctionType = @FunctionType OR @FunctionType = 0)
		AND (c.BeginTime >= @BeginTime OR @BeginTime IS NULL)
		AND (c.EndTime <= @EndTime OR @EndTime IS NULL)
	ORDER BY FunctionType,ProductName,SportName,SettingName
END
GO