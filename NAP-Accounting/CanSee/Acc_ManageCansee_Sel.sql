/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
GO
ALTER PROCEDURE [dbo].[Acc_ManageCansee_Sel] 
	-- Add the parameters for the stored procedure here
	@pMutilSportType	NVARCHAR(Max) = '',
	@BetType			INT = NULL,
	@BettypeName		NVARCHAR(128) = '',
	@pMutilCurrency		NVARCHAR(Max) = '',
	@pMutilSite			NVARCHAR(Max) = ''
AS
BEGIN
	-- EXEC Acc_ManageCansee_Sel_UAT2 @pMutilSportType = '44,180', @BetType = NULL,@BettypeName = '',@pMutilCurrency =N'0',@pMutilSite = '0,1,2,3'
	/*
		Task : NAP -  Manage ProductLaunchSiteCurrency - CanSee
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [Redmine: #131241]
			- 20201118@Tina: Add 1 more value is 0 which use to get all sports [Redmine: #131241]
			- 20201207@Tina: multiple selection for @SportType, @SiteID
			- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
			- 20230113@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
	*/
	SET NOCOUNT ON;
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))
	CREATE TABLE #Site (siteid INT PRIMARY KEY, [SiteName] NVARCHAR(50), isActive BIT)
	CREATE TABLE #Exchange (exchangeid INT PRIMARY KEY, currency NVARCHAR(50))

	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	INSERT INTO #Site  (siteid, [SiteName], isActive)	
	SELECT	S.value, 
			CASE WHEN S.value = 0 THEN 'All Sites' ELSE Si.[site] END SiteName,
			CASE WHEN S.value = 0 THEN 1 ELSE Si.isActive END isActive
	FROM STRING_SPLIT(@pMutilSite, ',') S
		LEFT JOIN [Site] Si WITH (NOLOCK) ON Si.siteid = S.value
	
	INSERT INTO #Exchange  (exchangeid,currency)	
	SELECT C.value exchangeid, CASE WHEN C.value = 0 THEN 'All Currencies' ELSE E.currency END currency
	FROM STRING_SPLIT(@pMutilCurrency, ',') C
		LEFT JOIN exchange E WITH(NOLOCK) ON C.value = E.ExchangeId
		
	SELECT 
		 plsc.SportType
		,plsc.BetType
		,bt.typenamee as BetTypeName
		,plsc.Currency
		,cc.currency as CurrencyName
		,plsc.SiteID
		,s.[SiteName] as [SiteName]
		,plsc.IsLaunched
		,plsc.IsTest
		,plsc.LaunchedLevel
	FROM ProductLaunchedSiteCurrency plsc WITH(NOLOCK)
		INNER JOIN #Site s WITH(NOLOCK) ON plsc.SiteID = s.siteid
		INNER JOIN #Exchange cc WITH(NOLOCK) ON cc.exchangeid = plsc.Currency
		INNER JOIN #Bettype bt ON bt.typeid = plsc.BetType
		INNER JOIN STRING_SPLIT(@pMutilSportType, ',') SP ON SP.value = plsc.SportType
	WHERE bt.typenamee LIKE N'%' + @BettypeName + '%'
		AND (@BetType IS NULL OR plsc.BetType = @BetType )
		AND s.isActive=1
	ORDER BY Plsc.SiteID,plsc.SportType,plsc.BetType
   
   DROP TABLE #Bettype,#Exchange,#Site
END
GO
