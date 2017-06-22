
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Sel    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Sel    Script Date: 10/23/2014 12:48:25 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Sel    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_Sel]
	@Licensee NVARCHAR(100)
	,@CurrencyID INT
	,@AgentID INT = NULL
	,@HasSetting BIT = 0 OUTPUT
	,@AgentName NVARCHAR(30) = '' OUTPUT
	,@CurrencyName NVARCHAR(30) = '' OUTPUT
AS
/*
	Created: Dom
		Date: 2014-09-03
		Task: Get list Product Hardcode setting by licensee and currency
		DB: DBTXN/CustDB
		
		Revisions:
		20150609@Alex: Separate CustDB to DBCUST server (Use temp table for sports, bettype, GameType table)


*/
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
BEGIN
	
	SELECT @AgentName = username FROM CustInfo WITH(NOLOCK) WHERE custid = @AgentID
	SELECT @CurrencyName = Currency FROM Exchange ex WITH(NOLOCK) WHERE exchangeid = @CurrencyID

	DECLARE @SportTable TABLE([site] VARCHAR(100), CurrencyID INT, sporttype INT, bettype INT, maxbet MONEY,maxpermatch MONEY,maxperball MONEY,[group] VARCHAR(5))
	INSERT INTO @SportTable
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=1, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=2, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=3, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=5, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=8, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=10, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=11, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=99, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=99, bettype=9, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=154, bettype=20, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='SB' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=161, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='NG' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=180, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=181, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=182, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=183, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=184, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=185, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=186, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='VS' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=1, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=3, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=4, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=5, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=7, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=8, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=9, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=11, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN' UNION ALL
	SELECT [site]=@licensee,CurrencyID=@CurrencyID,sporttype=202, bettype=13, maxbet=NULL,maxpermatch=NULL,maxperball=NULL,[group]='KN'

	IF(
		NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimit_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR (AgentID = @AgentID)) ) AND
		NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimitGameType_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND @AgentID IS NULL)
	)
	BEGIN
		SET @HasSetting = 0
		SELECT sp.[Site] Licensee
			,sp.CurrencyID
			--,ex.Currency
			,@AgentID AgentID
			--,ci.UserName AgentName
			,sp.SportType
			,sp.[Group]
			,sp.Bettype
			,CASE WHEN sp.SportType=99 AND sp.bettype=9 THEN 'Mix Sports Parlay' WHEN sp.SportType=154 THEN 'HRFO' ELSE s.SportName END SportName
			,sp.MaxBet
			,sp.MaxPerMatch
			,sp.MaxPerBall
		FROM @SportTable sp
		LEFT JOIN @tmp_Sports s ON s.SportType = sp.SportType
		WHERE sp.sporttype <> 202 

		SELECT sp.[Site] Licensee
				,sp.CurrencyID
				--,ex.Currency
				,AgentID = NULL
				,SportType=202
				,sp.[Group]
				,sp.Bettype
				,bt.GameTypeName SportName
				,SportNameA = 'Keno'
				,sp.MaxBet
				,sp.MaxPerMatch
				,MaxPerBall = NULL
			FROM @SportTable sp 
			INNER JOIN @tmp_GameType bt ON sp.bettype = bt.GameTypeID
			where sp.sporttype = 202 AND @AgentID IS NULL
	END
	ELSE
	BEGIN
		SET @HasSetting = 1

		SELECT sp.[Site] Licensee
			,sp.CurrencyID
			--,ex.Currency
			,AgentID
			--,ci.UserName AgentName
			,sp.SportType
			,sp.[Group]
			,sp.Bettype
			,CASE WHEN sp.SportType=99 AND sp.bettype=9 THEN 'Mix Sports Parlay' WHEN sp.SportType=154 THEN 'HRFO' ELSE s.SportName END SportName
			,tmp.MaxBet
			,tmp.MaxPerMatch
			,tmp.MaxPerBall
		FROM @SportTable sp
		LEFT JOIN @tmp_Sports s ON s.SportType = sp.SportType
		LEFT JOIN (
			SELECT cbs.Site,cbs.SportType, cbs.bettype,cbs.AgentID,cbs.CurrencyID,cbs.MaxBet,cbs.MaxPerMatch,cbs.MaxPerBall
			FROM [dbo].[Dep_CustBetLimit_Special] cbs WITH(NOLOCK) 
			WHERE CurrencyID = @CurrencyID
			AND [Site] = @Licensee
			AND ( (@AgentID is null AND AgentID IS NULL) OR AgentID = @AgentID )
			
		) tmp ON tmp.SportType = sp.sporttype and tmp.Bettype = sp.bettype
		
		--INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = sp.CurrencyID
		--LEFT JOIN CustInfo ci WITH(NOLOCK) ON ci.CustID = tmp.AgentID and ci.roleid=2
		where  sp.sporttype <> 202

		---------Result OF Keno
		IF(@AgentID IS NULL)
		BEGIN
			IF(NOT EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimitGameType_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND @AgentID IS NULL))
			BEGIN
				--DECLARE @Currency NVARCHAR(100)
				--SELECT @Currency=ex.currency FROM Exchange ex WITH(NOLOCK) WHERE @CurrencyID=ex.exchangeid

				SELECT @Licensee Licensee
					,@CurrencyID CurrencyID
					--,@Currency Currency
					,AgentID = NULL
					--,AgentName = NULL
					,SportType=202
					,sp.[Group]
					,sp.Bettype
					,bt.GameTypeName SportName
					,SportNameA = 'Keno'
					,sp.MaxBet
					,sp.MaxPerMatch
					,MaxPerBall = NULL
				FROM @SportTable sp 
				INNER JOIN @tmp_GameType bt ON sp.bettype = bt.GameTypeID
				WHERE SportType=202
			END
			ELSE
			BEGIN
			
			SELECT cbs.[Site] Licensee
				,cbs.CurrencyID
				--,ex.Currency
				,AgentID = NULL
				,SportType=202
				,sp.[Group]
				,sp.Bettype
				,bt.GameTypeName SportName
				,SportNameA = 'Keno'
				,cbs.MaxBet
				,cbs.maxpergametype MaxPerMatch
				,MaxPerBall = NULL
			FROM @SportTable sp 
			LEFT JOIN [dbo].[Dep_CustBetLimitGameType_Special] cbs WITH(NOLOCK) ON cbs.gametypeid = sp.bettype AND cbs.[Site]=@Licensee AND cbs.CurrencyID=@CurrencyID
			INNER JOIN @tmp_GameType bt ON sp.bettype = bt.GameTypeID
			--INNER JOIN Exchange ex WITH(NOLOCK) ON ex.exchangeid = sp.CurrencyID
			WHERE sp.CurrencyID = @CurrencyID
				AND sp.[Site] = @Licensee
				AND sp.sporttype=202
			ORDER BY 6,7
			END
		END
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_Sel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_Sel] TO [bodbLicenseeNet]
GO 
