/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPTDaily_Sel] 
	-- Add the parameters for the stored procedure here
	  @ProductID			NVARCHAR(Max) = '',
	  @CustName				VARCHAR(50) = '',
	  @MutilCurrency		NVARCHAR(Max) = '',
	  @MutilSite			NVARCHAR(Max) = '',
	  @Type					TINYINT,
	  @IsLimitUpdPT			TINYINT,		--0: No, 1: Yes, 2: All
	  @SettingStatus		TINYINT = 0,
	  @PageSize    INT = 100,  
	  @PageIndex    INT = 1,  
	  @TotalItems    INT = 0 OUTPUT  
AS
/*
		Task : NAP CM -  Limit Daily PT Update
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20211027@Winfred: NAP CM -  Limit Daily PT Update [Redmine: #162476]
			- 20220613@Elodie: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
			- 20220616@Johnson: define temp table to avoid dump db [redmine:#174035]
			- 20230620@Luke: Limitation to update PT for new member [Redmine: #188950]
	*/
BEGIN
	SET NOCOUNT ON;
	DECLARE @RowCount INT, @RowStart INT, @RowEnd INT  
	DECLARE @CustID INT
	CREATE TABLE #Site (siteid INT PRIMARY KEY)
	CREATE TABLE #Exchange (exchangeid INT PRIMARY KEY)
	CREATE TABLE #Product (ProductID TINYINT PRIMARY KEY ,ProductName	VARCHAR(50) )
	
	CREATE TABLE #Result(ProductID TINYINT, ProductName VARCHAR(50), CustID INT, username VARCHAR(30), Currency INT, SiteID INT,
						MaxCount TINYINT, Type TINYINT, LimitNewAccUpdPT BIT, SettingStatus TINYINT, [site] NVARCHAR(100), CurrencyName NVARCHAR(100), RowNumber INT)
	
	-- Select ProductName
	INSERT INTO #Site  (siteid)	
	SELECT S.value
	FROM string_split(@MutilSite, ',') S WHERE value <> ''
	
	INSERT INTO #Exchange  (exchangeid)	
	SELECT C.value exchangeid
	FROM string_split(@MutilCurrency, ',') C WHERE value <> ''
	
	INSERT INTO #Product  (ProductID)	
	SELECT S.value
	FROM string_split(@ProductID, ',') S WHERE value <> ''
	
	SELECT @CustID = CustID FROM  dbo.Custinfo ci WITH (NOLOCK) WHERE username = @CustName
	
	INSERT INTO #Result(ProductID,ProductName,CustID,username,Currency,SiteID,MaxCount,Type,LimitNewAccUpdPT,SettingStatus,[site],CurrencyName,RowNumber)
	SELECT ProductID,ProductName,CustID,username,Currency,SiteID,MaxCount,Type,LimitNewAccUpdPT,SettingStatus,[site],CurrencyName,
	ROW_NUMBER() OVER (ORDER BY Type,username ,site ,CurrencyName ) AS RowNumber 
	FROM (
		SELECT 
			l.ProductID
			,CAST( '' AS VARCHAR(50)) AS ProductName
			,l.CustID
			,c.username
			,l.Currency
			,l.SiteID
			,l.MaxCount
			,l.Type
			,CASE WHEN ISNULL(l.LimitNewAccUpdPT,0) = 0 THEN 0 ELSE 1 END AS LimitNewAccUpdPT
			,l.SettingStatus
			,Si.[site] 
			,e.currency as CurrencyName
		FROM LimitPTDailySetting l WITH(NOLOCK)
		INNER JOIN Customer c WITH (NOLOCK) ON l.CustID = c.CustID
		LEFT JOIN Site Si WITH (NOLOCK) ON Si.site = c.Site
		LEFT JOIN exchange e WITH (NOLOCK) ON e.ExchangeId = c.Currency
		WHERE (l.CustID = @CustID OR  @CustName = '')
		AND l.Type = 1 
		AND @Type IN ( 0,1)
		AND ISNULL(l.LimitNewAccUpdPT,0) = CASE @IsLimitUpdPT	WHEN 1 THEN 1
																WHEN 0 THEN 0
																ELSE ISNULL(l.LimitNewAccUpdPT,0) END
		AND (Si.SiteID IN (SELECT siteid from #Site) OR  EXISTS (SELECT TOP 1 1 FROM #Site WHERE siteid = 0))
		AND (e.exchangeid IN (SELECT exchangeid from #Exchange) OR  EXISTS (SELECT TOP 1 1 FROM #Exchange WHERE exchangeid = 0))
		AND (l.ProductID IN (SELECT ProductID from #Product) OR  EXISTS (SELECT TOP 1 1 FROM #Product WHERE ProductID = 0))
		AND l.SettingStatus <= CASE WHEN @SettingStatus = 1 THEN 1 ELSE 0 END 
		UNION ALL
		SELECT 
			l.ProductID
			,CAST( '' AS VARCHAR(50)) AS ProductName
			,l.CustID
			,'' AS username
			,l.Currency
			,l.SiteID
			,l.MaxCount
			,l.Type
			,CASE WHEN ISNULL(l.LimitNewAccUpdPT,0) = 0 THEN 0 ELSE 1 END AS LimitNewAccUpdPT
			,l.SettingStatus
			,Si.[site] 
			,e.currency as CurrencyName
		FROM LimitPTDailySetting l WITH(NOLOCK)
		LEFT JOIN Site Si WITH (NOLOCK) ON Si.SiteID = l.SiteID
		LEFT JOIN exchange e WITH (NOLOCK) ON e.ExchangeId = l.Currency
		WHERE (Si.SiteID IN (SELECT siteid from #Site) OR  EXISTS (SELECT TOP 1 1 FROM #Site WHERE siteid = 0))
		AND (e.exchangeid IN (SELECT exchangeid from #Exchange) OR  EXISTS (SELECT TOP 1 1 FROM #Exchange WHERE exchangeid = 0))
		AND (l.ProductID IN (SELECT ProductID from #Product) OR  EXISTS (SELECT TOP 1 1 FROM #Product WHERE ProductID = 0))
		AND (l.Type = @Type OR @Type = 0)
		AND l.Type <> 1 AND @CustName = ''
		AND ISNULL(l.LimitNewAccUpdPT,0) = CASE @IsLimitUpdPT	WHEN 1 THEN 1
																WHEN 0 THEN 0
																ELSE ISNULL(l.LimitNewAccUpdPT,0) END
		AND l.SettingStatus <= CASE WHEN @SettingStatus = 1 THEN 1 ELSE 0 END  
	) KQ
	
	UPDATE tc
	SET tc.ProductName = p.ProductName
	FROM #Result tc
		INNER JOIN DBACC.bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = tc.ProductID 
	
	 SELECT @TotalItems = COUNT(1) FROM #Result  
	 SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	  
	 SELECT *  
	 FROM #Result  
	 WHERE RowNumber BETWEEN @RowStart AND @RowEnd    
	 ORDER BY RowNumber  
	
	DROP TABLE #Result,#Site,#Exchange
END
GO
