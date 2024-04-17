/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
GO
ALTER PROCEDURE [dbo].[Acc_Rpt_BigCreditIncrement]
	@FromDate	DATETIME,  
	@ToDate		DATETIME,
	@IsTest		BIT = 0
AS
/*  Created: 20201020@Tina  
    Task : 143578 - Letstalk Notification for big credit increment
    DB: DBLOG/bodb_CustomerLog
   
    Revisions: 
		- 20201020@Tina: add new
		- 20230103@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]

	Param's Explanation:

	Execute String: 

		EXEC [dbo].[Acc_Rpt_BigCreditIncrement] @FromDate= '2020-10-20 05:00:00.000', @ToDate ='2020-10-20 05:59:59.999', @IsTest = 1

*/
BEGIN 
	SET NOCOUNT ON 
	
	CREATE TABLE #CreditIncrement (CustId INT, Amount MONEY, BeginLogID BIGINT, EndLogID BIGINT)

	CREATE TABLE #BigCreditIncrement(CustId INT, UserName VARCHAR(128), CreateDate Date, Amount MONEY, BeginLogID BIGINT, EndLogID BIGINT, 
									MemberSiteName VARCHAR(30), Currency NVARCHAR(128), ActualRate FLOAT)

	CREATE TABLE #site (SiteID INT, SiteName VARCHAR(30), Amount INT)

	INSERT INTO #site(SiteName, Amount)
	SELECT site SiteName, 331910 Amount
	FROM DBCUST.CustDB.dbo.Site s WITH (NOLOCK)
	WHERE SiteLabel = '789y'

	--get movement data in date range
	INSERT INTO #CreditIncrement (CustId, Amount, BeginLogID, EndLogID)
	SELECT	L.CustId,
			SUM (ISNULL(L.NewValue,0) - ISNULL(L.OldValue,0)) AS Amount, 
			MIN(logid) BeginLogID,
			MAX(logid) EndLogID
	FROM	bodb_CustomerLog.dbo.UserLog_Credit L WITH (NOLOCK)		
	WHERE	L.LogDate BETWEEN @FromDate AND @ToDate		 
	GROUP BY L.CustId

	--filter base on site and amount in temp table #site
	INSERT INTO #BigCreditIncrement(CustId, UserName, CreateDate, Amount, BeginLogID, EndLogID, MemberSiteName, Currency, ActualRate)
	SELECT CI.CustId, C.username, C.creatdate, CI.Amount Amount,CI.BeginLogID BeginLogID, CI.EndLogID EndLogID, S.Sitename, E.currency, (CASE WHEN E.currency = 'UUS' THEN 1 ELSE E.ActualRate END) ActualRate
	FROM #CreditIncrement CI
		INNER JOIN bodb02.dbo.Customer C WITH (NOLOCK) ON C.CustID = CI.CustID AND C.roleid = 1 --member
		INNER JOIN bodb02.dbo.Customer ASite WITH (NOLOCK) ON C.recommend = ASite.CustId -- get site from Agent
		INNER JOIN #site S ON ASite.[site] = S.SiteName 
		INNER JOIN bodb02.dbo.Exchange E WITH (NOLOCK) ON C.currency = E.ExchangeId
	WHERE CI.Amount * (CASE WHEN E.currency = 'UUS' THEN 1 ELSE E.ActualRate END) >= S.Amount

	--result
	SELECT BCI.UserName, 
		BCI.CreateDate Creation,
		BCI.Currency, 
		ISNULL(BegTran.OldValue, 0) OldCredit, 
		EndTran.NewValue NewCredit, 
		ISNULL(BegTran.OldValue, 0)* BCI.ActualRate OldRMCredit, 
		EndTran.NewValue*BCI.ActualRate NewRMCredit,
		BCI.MemberSiteName
	FROM #BigCreditIncrement BCI 
		INNER JOIN UserLog_Credit BegTran WITH (NOLOCK) ON BegTran.logid = BCI.BeginLogID 
				   AND BegTran.logdate BETWEEN @FromDate AND @ToDate -- using index on logdate column
		INNER JOIN UserLog_Credit EndTran WITH (NOLOCK) ON EndTran.logid = BCI.EndLogID 
				   AND EndTran.logdate BETWEEN @FromDate AND @ToDate -- using index on logdate column
	WHERE (@IsTest = 1 OR (@IsTest = 0 AND BCI.Currency <> 'UUS'))
	ORDER BY BCI.MemberSiteName, BCI.UserName ASC

	DROP TABLE #site
	DROP TABLE #CreditIncrement
	DROP TABLE #BigCreditIncrement
END