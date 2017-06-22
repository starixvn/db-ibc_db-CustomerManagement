
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_List    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_List    Script Date: 10/23/2014 12:48:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_List    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_List]
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
		DB: DBTXN/CustDB
		
		Revisions:
		20150609@Alex: Separate CustDB to DBCUST server (Use temp table for sports, bettype, GameType table)

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @tmp_Sports TABLE(SportType TINYINT,SportName NVARCHAR(50))
	DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)

	BEGIN TRY
		INSERT INTO @tmp_Sports(SportType, SportName)
		SELECT SportType, SportName FROM DBAGE.bodb02.dbo.Sports WITH (NOLOCK)
	END TRY
	BEGIN CATCH
		INSERT INTO @tmp_Sports(SportType, SportName)
		SELECT SportType, SportName FROM DBTXN.bodb02.dbo.Sports WITH (NOLOCK) 
	END CATCH
	
	BEGIN TRY		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK)
	END TRY
	BEGIN CATCH		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
	END CATCH
	
	DECLARE @Sport TABLE(SportID INT)
	
	IF(@ShowSportBook=1)
		INSERT INTO @Sport 
		SELECT 1 UNION ALL 
		SELECT 2 UNION ALL 
		SELECT 3 UNION ALL 
		SELECT 5 UNION ALL 
		SELECT 8 UNION ALL 
		SELECT 10 UNION ALL 
		SELECT 11 UNION ALL 
		SELECT 99 UNION ALL 
		SELECT 154

	IF(@ShowNumberGame=1)
		INSERT INTO @Sport 
		SELECT 161

	IF(@ShowVirtualSport=1)
		INSERT INTO @Sport 
		SELECT 180 UNION ALL 
		SELECT 181 UNION ALL 
		SELECT 182 UNION ALL 
		SELECT 183 UNION ALL 
		SELECT 184 UNION ALL 
		SELECT 185 UNION ALL 
		SELECT 186
	
	CREATE TABLE #Data(	Licensee NVARCHAR(100),CurrencyID INT, Currency NVARCHAR(50), AgentID INT, SportType INT, Bettype INT, AgentName NVARCHAR(50), SportName NVARCHAR(200), SportGameType NVARCHAR(200), MaxBet MONEY, MaxPerMatch MONEY, MaxPerBall MONEY)

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
					MaxPerBall)
	SELECT [Site] Licensee
		,CurrencyID
		,ex.Currency
		,AgentID
		,cbs.SportType
		,cbs.Bettype
		,ci.UserName AgentName
		,s.SportName SportName
		,CASE WHEN cbs.SportType=99 AND cbs.bettype=9 THEN 'Mix Sports Parlay' WHEN cbs.SportType=154 THEN 'HRFO' ELSE s.SportName END SportGameType
		,cbs.MaxBet
		,cbs.MaxPerMatch
		,cbs.MaxPerBall
	FROM [dbo].[Dep_CustBetLimit_Special] cbs WITH(NOLOCK)
	INNER JOIN @tmp_Sports s ON s.SportType = cbs.SportType
	INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = cbs.CurrencyID
	LEFT JOIN CustInfo ci WITH(NOLOCK) ON ci.CustID = cbs.AgentID and ci.roleid=2
	WHERE cbs.SportType IN(SELECT SportID FROM @Sport)
		AND CurrencyID IN (SELECT val FROM dbo.strSplit(@Currency,','))
		AND [Site] = @Licensee
	UNION ALL
	SELECT [Site] Licensee
		,CurrencyID
		,ex.Currency
		,AgentID = NULL
		,202
		,cbs.gametypeid
		,AgentName = NULL
		,SportName = 'Keno'
		,bt.GameTypeName SportGameType
		,maxbet
		,maxpergametype MaxPerMatch
		,MaxPerBall = NULL
	FROM [dbo].[Dep_CustBetLimitGameType_Special] cbs WITH(NOLOCK)
	INNER JOIN @tmp_GameType bt ON bt.GameTypeID = cbs.gametypeid
	INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = cbs.CurrencyID
	WHERE @ShowKeno=1
		AND CurrencyID IN (SELECT val FROM dbo.strSplit(@Currency,','))
		AND [Site] = @Licensee
	ORDER BY 1,2,3,4

	DELETE #DATA WHERE MaxBet IS NULL AND 
					MaxPerMatch IS NULL AND
					MaxPerBall IS NULL 

	SELECT * FROM #DATA ORDER BY Licensee,CurrencyID, Currency , AgentID,SportType,Bettype
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_List] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_List] TO [bodbLicenseeNet]
GO 
