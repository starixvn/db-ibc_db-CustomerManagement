/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ManageCansee_Sel] 
	-- Add the parameters for the stored procedure here
	@SportType      TINYINT,
	@BetType        INT = NULL,
	@BettypeName    NVARCHAR(128) = '',
	@pMutilCurrency  NVARCHAR(Max) = '',
	@pMutilSite  NVARCHAR(Max) = ''
AS
BEGIN
	-- exec Acc_ManageProductLaunchSiteCurrency_Cansee_Sel @SportType = 0, @BetType = 0,@BettypeName = 'min',@pMutilCurrency =N'47,48,51,52',@pMutilSite = '0,1,11,12,13'
	/*
		Task : NAP -  Manage ProductLaunchSiteCurrency - CanSee
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [Redmine: #131241]
	*/
	SET NOCOUNT ON;
	CREATE TABLE #Bettype (typeid INT , typenamee NVARCHAR(128))
	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	SELECT 
		 plsc.SportType
		,plsc.BetType
		,bt.typenamee as BetTypeName
		,plsc.Currency
		,cc.currency as CurrencyName
		,plsc.SiteID
		,s.site as [SiteName]
		,plsc.IsLaunched
		,plsc.IsTest
		,plsc.LaunchedLevel
	FROM ProductLaunchedSiteCurrency plsc WITH(NOLOCK)
		INNER JOIN dbo.strSplit(@pMutilSite, ',') AS ms ON plsc.SiteID = ms.val
		INNER JOIN dbo.strSplit(@pMutilCurrency, ',') AS Mcc ON plsc.Currency = Mcc.val
		INNER JOIN Site s WITH(NOLOCK) ON plsc.SiteID = s.siteid
		INNER JOIN exchange cc WITH(NOLOCK) ON cc.exchangeid = plsc.Currency
		INNER JOIN #Bettype bt ON bt.typeid = plsc.BetType
	WHERE bt.typenamee LIKE N'%' + @BettypeName + '%'
	AND (@BetType IS NULL OR plsc.BetType = @BetType )
	AND (plsc.SportType = @SportType)
	order by Plsc.SiteID,plsc.SportType,plsc.BetType
   
   DROP TABLE #Bettype
END
GO
