/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
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
	-- exec Acc_ManageCansee_Sel @SportType = 0, @BetType = 0,@BettypeName = '',@pMutilCurrency =N'0',@SiteID = 0
	/*
		Task : NAP -  Manage ProductLaunchSiteCurrency - CanSee
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [Redmine: #131241]
			- 20201118@Tina: Add 1 more value is 0 which use to get all sports [Redmine: #131241]
			- 20201207@Tina: multiple selection for @SportType, @SiteID
	*/
	SET NOCOUNT ON;
	CREATE TABLE #Bettype (typeid INT , typenamee NVARCHAR(128))
	CREATE TABLE #Site (siteid INT , [SiteName] NVARCHAR(50))
	CREATE TABLE #Exchange (exchangeid INT , currency NVARCHAR(50))

	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	INSERT INTO #Site  (siteid, [SiteName])	
	SELECT S.val, CASE WHEN S.val = 0 THEN 'All Sites' ELSE Si.[site] END SiteName
	FROM dbo.strSplit(@pMutilSite, ',') S
		LEFT JOIN [Site] Si WITH (NOLOCK) ON Si.siteid = S.val
	
	INSERT INTO #Exchange  (exchangeid,currency)	
	SELECT E.exchangeid, CASE WHEN C.val = 0 THEN 'All Currencies' ELSE E.currency END currency
	FROM dbo.strSplit(@pMutilCurrency, ',') C
		LEFT JOIN exchange E WITH(NOLOCK) ON C.val = E.ExchangeId
		
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
		INNER JOIN dbo.strSplit(@pMutilSportType, ',') SP ON SP.val = plsc.SportType
	WHERE bt.typenamee LIKE N'%' + @BettypeName + '%'
		AND (@BetType IS NULL OR plsc.BetType = @BetType )
	ORDER BY Plsc.SiteID,plsc.SportType,plsc.BetType
   
   DROP TABLE #Bettype,#Exchange,#Site
END
GO
