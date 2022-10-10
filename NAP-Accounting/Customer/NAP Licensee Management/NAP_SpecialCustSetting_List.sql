/*<info serverAlias="DBCUST-CUSTDB" executers="bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_SpecialCustSetting_List]
	@Licensee NVARCHAR(100)
	,@Currency NVARCHAR(1000) = ''
	,@ShowSportBook BIT = 1
	,@ShowNumberGame BIT = 1
	,@ShowVirtualSport BIT =1
	,@ShowKeno BIT = 1
AS
/*
Created: Dom
		Date: 2014-09-03
		Task: Get list Product Hardcode setting by licensee and currency
		DB: DBCUST/CustDB
		
		Revisions:
			- 20150609@Alex: Separate CustDB to DBCUST server (Use temp table for sports, bettype, GameType table)
			- 20170809@Winnie: Change Data Type of Sporttype [RedmineID: #73545]
			- 20191218@Eden: NAP LM - Remove Inactive products [RedmineID: #119443]
			- 20200616@Johnson: add soccer parlay [redmine:#135261]
			- 20220613@Elodie: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]  
			- 202202220@Elodie: Apply DCS for SB [RedmineID: #167898] 
			- 20221010@Johnson: Add Saba cricket [redmine: #175659]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @tmp_Sports TABLE(SportType SMALLINT,SportName NVARCHAR(50))
	DECLARE @ProductID TINYINT
	CREATE TABLE #SportBettypeFilter (ProductID TINYINT, SportType SMALLINT,Bettype SMALLINT,IsLive BIT, SettingType TINYINT)

	BEGIN TRY
		INSERT INTO @tmp_Sports(SportType, SportName)
		SELECT SportType, SportName FROM DBAGE.bodb02.dbo.Sports WITH (NOLOCK)
	END TRY
	BEGIN CATCH
		INSERT INTO @tmp_Sports(SportType, SportName)
		SELECT SportType, SportName FROM DBTXN.bodb02.dbo.Sports WITH (NOLOCK) 
	END CATCH
	INSERT INTO @tmp_Sports(SportType, SportName)
	SELECT 9901, 'Saba Soccer' 
	UNION ALL
	SELECT 9902, 'Saba BasketBall' 
	UNION ALL
	SELECT 9907, 'Saba Cricket' 

	DECLARE @Sport TABLE(SportID INT)
	
	IF(@ShowSportBook=1)
	BEGIN 
		SELECT @ProductID = 1
		INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
		SELECT @ProductID AS ProductID,SportType,Bettype,IsLive, SettingType 
		FROM dbo.f_Dep_CustSetting_SportBetTypeSettingSelect (@ProductID,NULL)
	END
	IF(@ShowNumberGame=1)
	BEGIN 
		SELECT @ProductID = 3
		INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
		SELECT @ProductID AS ProductID,SportType,Bettype,IsLive, SettingType 
		FROM dbo.f_Dep_CustSetting_SportBetTypeSettingSelect (@ProductID,NULL)
	END
	IF(@ShowVirtualSport=1)
	BEGIN 
		SELECT @ProductID = 5
		INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
		SELECT @ProductID AS ProductID,SportType,Bettype,IsLive, SettingType 
		FROM dbo.f_Dep_CustSetting_SportBetTypeSettingSelect (@ProductID,NULL)
	END
	IF(@ShowKeno=1)
	BEGIN 
		SELECT @ProductID = 8
		INSERT INTO #SportBettypeFilter (ProductID,SportType,Bettype,IsLive, SettingType)
		SELECT @ProductID AS ProductID,SportType,Bettype,IsLive, SettingType 
		FROM dbo.f_Dep_CustSetting_SportBetTypeSettingSelect (@ProductID,NULL)
	END

	CREATE TABLE #Data(	Licensee NVARCHAR(100),CurrencyID INT, Currency NVARCHAR(50), AgentID INT, SportType INT, Bettype INT, AgentName NVARCHAR(50), SportName NVARCHAR(200), SportGameType NVARCHAR(200), MaxBet MONEY, MaxPerMatch MONEY, MaxPerBall MONEY, MaxPayoutPerMatch MONEY)

	INSERT INTO #Data(Licensee,
					CurrencyID, 
					Currency,
					AgentID,
					SportType,
					Bettype,
					AgentName,
					SportName,
					SportGameType, 
					MaxBet, 
					MaxPerMatch,
					MaxPerBall,
					MaxPayoutPerMatch)
	SELECT [Site] Licensee
		,CurrencyID
		,ex.Currency
		,AgentID
		,cbs.SportType
		,cbs.Bettype
		,ci.UserName AgentName
		,s.SportName SportName
		,CASE	WHEN cbs.SportType=99 AND cbs.bettype=9 THEN 'Mix Sports Parlay'
				WHEN cbs.SportType=1 AND cbs.bettype=9 THEN 'Soccer Parlay' ELSE s.SportName END SportGameType
		,cbs.MaxBet
		,cbs.MaxPerMatch
		,cbs.MaxPerBall
		,cbs.MaxPayoutPerMatch
	FROM [dbo].[Dep_CustBetLimit_Special] cbs WITH(NOLOCK)
	INNER JOIN @tmp_Sports s ON s.SportType = cbs.SportType
	INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = cbs.CurrencyID
	LEFT JOIN CustInfo ci WITH(NOLOCK) ON ci.CustID = cbs.AgentID and ci.roleid=2
	WHERE cbs.SportType IN(SELECT SportType FROM #SportBettypeFilter WHERE SettingType IN (10, 12, 2))
		AND CurrencyID IN (SELECT value FROM string_split(@Currency,','))
		AND [Site] = @Licensee	
	ORDER BY 1,2,3,4

	DELETE #DATA WHERE MaxBet IS NULL AND 
					MaxPerMatch IS NULL AND
					MaxPerBall IS NULL 

	SELECT * FROM #DATA ORDER BY Licensee,CurrencyID, Currency , AgentID,SportType,Bettype
END

GO

