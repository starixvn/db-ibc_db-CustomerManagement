/*<info serverAlias="DBAGE-BODB02" executers="wsv_nap"  isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermSelByGroupID]
(
	@GroupID INT = 0,
	@DeniedList	NVARCHAR(MAX)=NULL
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
	- 20230227@Evan: Balance-Up support transfer 247 [Redmine: #173554]
	- 20230608@Lewis: Add 3rd Party Pending transfer column - [Redmine: #188648]
	- 20240521@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
	- 20240725@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
Parameters Explanation:
	* @DeniedList: output from [Acc_DeniedSiteCurrency_Sel]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	DECLARE @CustIDList VARCHAR (MAX) = '',@TotalMaxLoss_RM MONEY
	
	CREATE TABLE #Cust_tmp (CustID INT PRIMARY KEY,GroupID INT,username VARCHAR (200),isgroupheadline BIT,Currency VARCHAR(20), MaxLoss MONEY, actualrate FLOAT)
	
	CREATE TABLE #CustBalance_tmp (CustID INT PRIMARY KEY, TotalBalance MONEY, TotalBalance_RM MONEY, YesterdayTotalBalance MONEY, YesterdayTotalBalance_RM MONEY, PendingTransfer3rd MONEY,PendingTransfer3rd_RM MONEY)
	
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
		AND c.Site NOT IN (SELECT Site FROM @tmp)
		AND c.currency NOT IN (SELECT exchangeID FROM @tmpExchange)
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

	INSERT INTO #CustBalance_tmp (CustID, TotalBalance, TotalBalance_RM, YesterdayTotalBalance, YesterdayTotalBalance_RM, PendingTransfer3rd,PendingTransfer3rd_RM)	
	EXEC dbo.Acc_CustomerSelBalanceInfo @CustIdList =@CustIDList, @MoveBetDay = @moveBetDay, @BalanceUpDay = @balanceUpDay
	
	SELECT 	c.CustID,c.username,c.isgroupheadline,c.Currency,c.MaxLoss AS MaxLoss, 
			ISNULL(cb.TotalBalance,0) AS TotalBalance,  
			ISNULL(cb.YesterdayTotalBalance,0) AS YesterdayTotalBalance,
			ISNULL(cb.PendingTransfer3rd,0) AS PendingTransfer3rd
	FROM #Cust_tmp c
		LEFT JOIN #CustBalance_tmp cb ON c.CustID = cb.CustID
		
	
	SELECT @TotalMaxLoss_RM = MaxLoss FROM bodb_Age.dbo.LimitLoss_HeadlineSetting WITH (NOLOCK) WHERE GroupHeadlineID = @GroupID	

	SELECT SUM (TotalBalance_RM) AS TotalBalance_RM, SUM(YesterdayTotalBalance_RM) AS YesterdayTotalBalance_RM,SUM(PendingTransfer3rd_RM) AS PendingTransfer3rd_RM, @TotalMaxLoss_RM AS TotalMaxLoss_RM
	FROM #CustBalance_tmp

		
	
	DROP TABLE #CustBalance_tmp
	DROP TABLE #Cust_tmp
END
GO