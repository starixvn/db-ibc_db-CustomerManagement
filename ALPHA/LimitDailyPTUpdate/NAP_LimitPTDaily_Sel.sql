/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPTDaily_Sel] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT,
	  @CustName				VARCHAR(50) = '',
	  @MutilCurrency		NVARCHAR(Max) = '',
	  @MutilSite			NVARCHAR(Max) = '',
	  @Type					TINYINT,
	  @SettingStatus		TINYINT = 0
AS
/*
		Task : NAP CM -  Limit Daily PT Update
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20211027@Winfred: NAP CM -  Limit Daily PT Update [Redmine: #162476]
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @ProductName	VARCHAR(50) ,@CustID INT
	CREATE TABLE #Site (siteid INT PRIMARY KEY)
	CREATE TABLE #Exchange (exchangeid INT PRIMARY KEY)

	-- Select ProductName
	SELECT @ProductName = p.ProductName
	FROM DBACC.bodb02.dbo.Products AS p WITH(NOLOCK)
	WHERE p.ProductID = @ProductID
	
	INSERT INTO #Site  (siteid)	
	SELECT S.val
	FROM dbo.strSplit(@MutilSite, ',') S
	
	INSERT INTO #Exchange  (exchangeid)	
	SELECT C.val exchangeid
	FROM dbo.strSplit(@MutilCurrency, ',') C
	
	SELECT @CustID = CustID FROM  dbo.Custinfo ci WITH (NOLOCK) WHERE username = @CustName
	
	SELECT ProductID,ProductName,CustID,username,Currency,SiteID,MaxCount,Type,SettingStatus,[site],CurrencyName
	FROM (
		SELECT 
			l.ProductID
			,@ProductName AS ProductName
			,l.CustID
			,c.username
			,l.Currency
			,l.SiteID
			,l.MaxCount
			,l.Type
			,l.SettingStatus
			,Si.[site] 
			,e.currency as CurrencyName
		FROM LimitPTDailySetting l WITH(NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON l.CustID = c.CustID
		LEFT JOIN Site Si WITH (NOLOCK) ON Si.site = c.Site
		LEFT JOIN exchange e WITH (NOLOCK) ON e.ExchangeId = c.Currency
		WHERE l.ProductID = @ProductID 
		AND (l.CustID = @CustID OR  @CustName = '')
		AND l.Type = 1 
		AND @Type IN ( 0,1)
		AND (Si.SiteID IN (SELECT siteid from #Site) OR  EXISTS (SELECT TOP 1 1 FROM #Site WHERE siteid = 0))
		AND (e.exchangeid IN (SELECT exchangeid from #Exchange) OR  EXISTS (SELECT TOP 1 1 FROM #Exchange WHERE exchangeid = 0))
		AND l.SettingStatus <= CASE WHEN @SettingStatus = 1 THEN 1 ELSE 0 END 
		UNION ALL
		SELECT 
			l.ProductID
			,@ProductName AS ProductName
			,l.CustID
			,'' AS username
			,l.Currency
			,l.SiteID
			,l.MaxCount
			,l.Type
			,l.SettingStatus
			,Si.[site] 
			,e.currency as CurrencyName
		FROM LimitPTDailySetting l WITH(NOLOCK)
		LEFT JOIN Site Si WITH (NOLOCK) ON Si.site = l.SiteID
		LEFT JOIN exchange e WITH (NOLOCK) ON e.ExchangeId = l.Currency
		WHERE l.ProductID = @ProductID 
		AND (Si.SiteID IN (SELECT siteid from #Site) OR  EXISTS (SELECT TOP 1 1 FROM #Site WHERE siteid = 0))
		AND (e.exchangeid IN (SELECT exchangeid from #Exchange) OR  EXISTS (SELECT TOP 1 1 FROM #Exchange WHERE exchangeid = 0))
		AND (l.Type = @Type OR @Type = 0) 
		AND l.SettingStatus <= CASE WHEN @SettingStatus = 1 THEN 1 ELSE 0 END  
	) KQ
	ORDER BY Type,username ,site ,CurrencyName 
END
GO
