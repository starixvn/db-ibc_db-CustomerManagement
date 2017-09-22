ALTER PROCEDURE [dbo].[Acc_CustSetting_SyncAPICustomerProfileSelect_UserName] 
 @UserNameList	VARCHAR(4000) 
AS 
/*
	Created: Jamie@20160930
	Task: Search custID by UserNames [RedmineID:#65873 ]
	DB:DBAGE.bodb02 

	Param's Explanation: 
		EXEC [Acc_CustSetting_SyncAPICustomerProfileSelect_UserName] @UserNameList ='338HK, 428RM, 312rmb, 831US, 305RM, 922SD, 302RM, 288RM, 832NSD, 333HK,aaa'

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #tmpSiteCurrency(
		Currency	INT,
		SiteID		INT,
		Site		VARCHAR(10)
	)
	INSERT INTO #tmpSiteCurrency (Currency, SiteID, Site)
	SELECT	c.Currency, c.SiteID, s.Site 
	FROM	ProductStatusSiteCurrency c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON c.SiteID = s.SiteID
	WHERE	c.SportType = 213
			AND c.BetType = 2501

	CREATE TABLE #tmpUserNameList(
		UserName VARCHAR(30)
	)
	INSERT INTO #tmpUserNameList(UserName)
	SELECT RTRIM(LTRIM(Val)) FROM strSplit(@UserNameList,',')

	CREATE TABLE #tmpCustomer(
			CustID		INT PRIMARY KEY,
			Username	NVARCHAR(30),
			Site		VARCHAR(10),
			Currency	INT
	)

	INSERT INTO #tmpCustomer(CustID, Username, Site, Currency)
	SELECT	c.CustID, c.UserName
			,CASE	WHEN c.RoleID = 1 THEN ag.Site
					ELSE c.Site END AS [Site]
			,ci.currency 
	FROM	Customer c WITH (NOLOCK)
			INNER JOIN CustInfo ci WITH (NOLOCK) ON c.CustID = ci.CustID
			LEFT JOIN Customer ag WITH (NOLOCK) ON c.recommend = ag.CustID AND c.RoleID = 1
	WHERE	c.UserName IN (SELECT UserName FROM #tmpUserNameList WITH (NOLOCK))
	

	SELECT	tc.CustID, tc.Username
	FROM	#tmpCustomer tc WITH (NOLOCK) 
			INNER JOIN #tmpSiteCurrency sc WITH (NOLOCK) ON tc.currency = sc.Currency AND tc.Site = sc.Site 

	SELECT	UserName
	FROM	#tmpUserNameList WITH (NOLOCK)
	WHERE	UserName NOT IN (SELECT UserName FROM #tmpCustomer WITH (NOLOCK))
	UNION ALL 
	SELECT	tc.Username 
	FROM	#tmpCustomer tc WITH (NOLOCK) 
			LEFT JOIN #tmpSiteCurrency sc WITH (NOLOCK) ON tc.currency = sc.Currency AND tc.Site = sc.Site 
	WHERE	sc.currency IS NULL OR sc.Site IS NULL 	
	
	DROP TABLE #tmpSiteCurrency	
	DROP TABLE #tmpUserNameList
	DROP TABLE #tmpCustomer
END

GO 
GRANT EXECUTE ON [dbo].[Acc_CustSetting_SyncAPICustomerProfileSelect_UserName] TO [bodbAdminNet]
GO
