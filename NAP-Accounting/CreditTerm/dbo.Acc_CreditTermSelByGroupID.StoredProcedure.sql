/*<info serverAlias="DBAGE-BODB02" executers="bodbAdminNet"  isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermSelByGroupID]
(
	@GroupID INT = 0
)
AS
/*
Created: 
Task : 
DB: DB053.bodb02
Revisions:
	- 20170420@Helen: Extra Information on Direct Customer - [Redmine: 72339]
	- 20171026@Elodie:  Add MaxLoss of headline - [Redmine:82892]
	- 20190531@Sophia: Add YesterdayTotalBalance [Redmine: #113650]
	- 20190724@Winnie: CN88 Headline Acc [Redmine: #117533]
	- 20210505@Sol: NAP - Alpha - Allow more time for transfer - [Redmine: #149927]
Parameters Explanation:

*/
BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @CustIDList VARCHAR (MAX) = '',@TotalMaxLoss_RM MONEY
	
	CREATE TABLE #Cust_tmp (CustID INT PRIMARY KEY,GroupID INT,username VARCHAR (200),isgroupheadline BIT,Currency VARCHAR(20), MaxLoss MONEY, actualrate FLOAT)
	
	CREATE TABLE #CustBalance_tmp (CustID INT PRIMARY KEY, TotalBalance MONEY, TotalBalance_RM MONEY, YesterdayTotalBalance MONEY, YesterdayTotalBalance_RM MONEY)
	
	INSERT INTO #Cust_tmp (CustID,username,isgroupheadline,groupid,Currency,MaxLoss,actualrate)	
	SELECT ca.custid,c.username,ca.isgroupheadline,ca.groupID
		, CASE WHEN exchangeid = 20 THEN 'UUS' ELSE E.currency END  AS Currency
		, LS.MaxLoss AS MaxLoss
		, E.actualrate
	FROM custaccount ca WITH (NOLOCK)
		INNER JOIN customer c WITH (NOLOCK) ON ca.custid = c.custid
		INNER JOIN Exchange E WITH (NOLOCK) ON E.exchangeid = c.currency
		LEFT JOIN bodb_AGE.dbo.LimitLoss_Setting LS WITH (NOLOCK) ON LS.CustID = c.CustID
	WHERE ca.groupid = @GroupID AND ISNULL(site,'')<>'CN88'
	ORDER BY ca.isgroupheadline desc
	
	SET @CustIDList = STUFF((SELECT ',' + CONVERT(VARCHAR(20),CustID)
						FROM #Cust_tmp
						FOR XML PATH ('') ),1,1,'')
	
	-- get move bet date
	DECLARE @balanceUpDay SMALLDATETIME, @moveBetDay SMALLDATETIME
	DECLARE @tblMoveBetBalanceUp AS TABLE (BalanceUpDay SMALLDATETIME, MoveBetsDay SMALLDATETIME)

	INSERT INTO @tblMoveBetBalanceUp(BalanceUpDay,MoveBetsDay)
	EXEC bodb02.dbo.Age_SelBalanceUpDay

	SELECT @balanceUpDay = BalanceUpDay, @moveBetDay = MoveBetsDay FROM @tblMoveBetBalanceUp

	INSERT INTO #CustBalance_tmp (CustID, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM)							
	EXEC dbo.Acc_CustomerSelBalanceInfo @CustIdList =@CustIDList, @MoveBetDay = @moveBetDay, @BalanceUpDay = @balanceUpDay
	
	SELECT 	c.CustID,c.username,c.isgroupheadline,c.Currency,c.MaxLoss AS MaxLoss, 
			ISNULL(cb.TotalBalance,0) AS TotalBalance,  
			ISNULL(cb.YesterdayTotalBalance,0) AS YesterdayTotalBalance
	FROM #Cust_tmp c
		LEFT JOIN #CustBalance_tmp cb ON c.CustID = cb.CustID
		
	
	SELECT @TotalMaxLoss_RM = MaxLoss FROM bodb_Age.dbo.LimitLoss_HeadlineSetting WITH (NOLOCK) WHERE GroupHeadlineID = @GroupID	

	SELECT SUM (TotalBalance_RM) AS TotalBalance_RM, SUM(YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM, @TotalMaxLoss_RM AS TotalMaxLoss_RM
	FROM #CustBalance_tmp

		
	
	DROP TABLE #CustBalance_tmp
	DROP TABLE #Cust_tmp
END
GO