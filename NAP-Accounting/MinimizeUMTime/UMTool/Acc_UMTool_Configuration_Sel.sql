/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_Configuration_Sel]
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Get UMConfig to grid
	DB: DBCUST.CustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]

	Param's Explanation:   
		
	Examples : 
		EXEC [Acc_UMTool_Configuration_Sel] 
		
*/
SET NOCOUNT ON	
	SELECT c.configID,
		c.FunctionType,
		c.ProductID,
		c.SportType,
		c.BetType,
		c.IsLive,
		c.SettingType,
		c.SiteID,
		c.currency,
		SuperID,
		FunctionTypeName = CASE WHEN FunctionType = 1 THEN 'Edit Setting'
								WHEN FunctionType = 2 THEN 'Add New Customer'
								WHEN FunctionType = 101 THEN 'Transfer'
							END,
		ISNULL(p.ProductName,'All') AS ProductName,
		ISNULL(sp.SportName,'All') AS SportName,
		ISNULL(st.SettingName,'All') AS SettingName,
		ISNULL(s.Site,'All') AS Site,
		ISNULL(e.currency,'All') AS CurrencyName,
		CASE WHEN c.SuperID = 0 THEN 'All'
			  WHEN ci.CustID IS NOT NULL THEN ci.username
			  ELSE 'N/A' END AS UserName,
		CONVERT(VARCHAR,DATEADD(hh,12,c.ShowTime),20) AS ShowTime,
		CONVERT(VARCHAR,DATEADD(hh,12,c.BeginTime),20) AS BeginTime,
		CONVERT(VARCHAR,DATEADD(hh,12,c.EndTime),20) AS EndTime,
		ISNULL(c.LockAddingNew,0) AS LockAddingNew
	FROM UMConfig c WITH(NOLOCK) 
		LEFT JOIN ProductSettingType st WITH(NOLOCK) ON c.SettingType = st.SettingType
		LEFT JOIN DBPRO.bodb02.dbo.Products p WITH(NOLOCK) ON c.ProductID = p.ProductID
		LEFT JOIN DBPRO.bodb02.dbo.Sports sp WITH(NOLOCK) ON c.sporttype = sp.sporttype
		LEFT JOIN Site s WITH(NOLOCK) ON c.SiteID = s.siteid
		LEFT JOIN exchange e WITH(NOLOCK) ON c.Currency = e.ExchangeId
		LEFT JOIN customer ci WITH(NOLOCK) ON c.SuperID = ci.custid AND ci.roleid = 4
	ORDER BY FunctionType,ProductName,SportName,SettingName
END
GO