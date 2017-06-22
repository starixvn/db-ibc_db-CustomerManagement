
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Upd    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Upd    Script Date: 10/23/2014 12:48:25 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Upd    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_Upd]
	@Licensee NVARCHAR(100),
	@CurrencyID INT,
	@AgentID INT = NULL,
	@Settings XML,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX)='' OUTPUT,
	@IP NVARCHAR(20),
	@UserID INT
AS
/*
Created: Dom
		Date: 2014-09-03
		Task: Update Hardcode setting
		DB: DBTXN/CustDB
		
		Revisions:

*/

/*<Settings>
  <Setting SportType="1" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="2" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="3" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="5" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="8" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="10" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="11" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="99" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="99" Bettype="9" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="154" Bettype="20" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="161" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="180" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="181" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="182" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="183" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="184" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="185" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="186" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="1" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="3" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="4" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="5" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="7" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="8" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="9" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="11" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="13" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
</Settings>*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()
	select @settings
	DECLARE @Log NVARCHAR(MAX), @OldLog NVARCHAR(MAX)
	DECLARE @LicenseeID INT
	DECLARE @HarcodeSetting TABLE(SportType INT, BetType INT, MaxBet MONEY, MaxPerMatch MONEY, MaxPerBall MONEY)
	DECLARE @HarcodeSetting_Keno TABLE(SportType INT, BetType INT, MaxBet MONEY, MaxPerMatch MONEY, MaxPerBall MONEY)

	SELECT @LicenseeID = [site].SiteID 
	FROM DBLIC.bodb02.dbo.[Site] ibcsite 
		LEFT JOIN DBLIC.bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1 AND [site].SiteName = @Licensee

	INSERT INTO @HarcodeSetting(SportType, BetType, MaxBet, MaxPerMatch, MaxPerBall)
	SELECT xmlData.Col.value('@sporttype','INT')
			,xmlData.Col.value('@bettype','INT')
			,xmlData.Col.value('@maxbet','MONEY')
			,xmlData.Col.value('@maxpermatch','MONEY')
			,xmlData.Col.value('@maxperball','MONEY')
	FROM @Settings.nodes('//settings/setting') xmlData(Col)
	WHERE xmlData.Col.value('@sporttype','INT') <> 202
	
	INSERT INTO @HarcodeSetting_Keno(SportType, BetType, MaxBet, MaxPerMatch, MaxPerBall)
	SELECT xmlData.Col.value('@sporttype','INT')
			,xmlData.Col.value('@bettype','INT')
			,xmlData.Col.value('@maxbet','MONEY')
			,xmlData.Col.value('@maxpermatch','MONEY')
			,xmlData.Col.value('@maxperball','MONEY')
	FROM @Settings.nodes('//settings/setting') xmlData(Col)
	WHERE xmlData.Col.value('@sporttype','INT') = 202 
		AND @AgentID IS NULL
		--AND xmlData.Col.value('@maxpermatch','MONEY') IS NOT NULL
		--AND xmlData.Col.value('@maxbet','MONEY') IS NOT NULL

	SELECT @OldLog = '<r>'
	SELECT @OldLog = @OldLog+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'"/>'
	FROM Dep_CustBetLimit_Special cbs  WITH(NOLOCK)
	WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR cbs.AgentID = @AgentID )

	SELECT @OldLog = @OldLog+'<st s="202" b="'+ISNULL(CAST(gametypeid AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(maxpergametype AS NVARCHAR(20)),'')+'" mpb=""/>'
	FROM Dep_CustBetLimitGameType_Special  cbs WITH(NOLOCK)
	WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND @AgentID IS NULL
	SELECT @OldLog = @OldLog+'</r>'
	
	IF(
		NOT EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting WHERE MaxBet IS NOT NULL AND MaxPerMatch IS NOT NULL AND SportType <> 161)
		AND NOT EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting WHERE MaxBet IS NOT NULL AND MaxPerMatch IS NOT NULL AND MaxPerBall IS NOT NULL AND SportType <> 161)
		AND NOT EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting_Keno WHERE MaxBet IS NOT NULL AND MaxPerMatch IS NOT NULL)
	)
	BEGIN
		PRINT 'DELETE SETTING'
								EXEC [NAP_SpecialCustSetting_Del]
				@Licensee = @Licensee,
				@CurrencyID = @CurrencyID,
				@AgentID = @AgentID,
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT,
				@IP = @IP,
				@UserID = @UserID
		RETURN;
	END

	IF(NOT EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) 
					WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )))
	BEGIN
		SELECT @ErrCode = 102,@ErrMsg = 'This Licensee is not existed '
		RETURN;
	END

	IF(EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting))
	BEGIN
		PRINT 'UPDATE SETTING'
		UPDATE cbs
		SET cbs.MaxBet = hs.MaxBet
			,cbs.MaxPerMatch = hs.MaxPerMatch
			,cbs.MaxPerBall = hs.MaxPerBall
		FROM Dep_CustBetLimit_Special cbs WITH(ROWLOCK,UPDLOCK)
		INNER JOIN @HarcodeSetting hs ON hs.sporttype = cbs.SportType and hs.Bettype=cbs.BetType
		WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR cbs.AgentID = @AgentID )

		------------Insert Missing sporttype------------------------
		INSERT INTO Dep_CustBetLimit_Special([Site], CurrencyID, SportType, AgentID, MaxBet, MaxPerMatch, MaxPerBall, Bettype)
		SELECT @Licensee, @CurrencyID, SportType, @AgentID, MaxBet, MaxPerMatch, MaxPerBall, Bettype 
		FROM @HarcodeSetting
		WHERE sporttype NOT IN (SELECT SportType FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) 
								WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )
								)
	END

	IF(EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting_Keno))
	BEGIN
		IF(NOT EXISTS (SELECT TOP 1 1 FROM Dep_CustBetLimitGameType_Special WITH(NOLOCK) WHERE [Site] = @Licensee AND CurrencyID = @CurrencyID))
		BEGIN
			print 'insert keno'
			INSERT INTO Dep_CustBetLimitGameType_Special([Site], CurrencyID, GameTypeID, MaxBet, maxpergametype)
			SELECT @Licensee, @CurrencyID,BetType, MaxBet, MaxPerMatch FROM @HarcodeSetting_Keno
		END
		ELSE
		BEGIN
			
			UPDATE cbs
			SET cbs.MaxBet = hs.MaxBet
				,cbs.maxpergametype = hs.MaxPerMatch
			FROM Dep_CustBetLimitGameType_Special cbs WITH(ROWLOCK,UPDLOCK)
			INNER JOIN @HarcodeSetting_Keno hs ON cbs.gametypeid=hs.BetType
			WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID 
		END
	END

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	--------------------------------------------Write Log-------------------------------------------------------------
	SELECT @Log ='<r>'
	SELECT @Log = @Log+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'"/>'
	FROM @HarcodeSetting

	SELECT @Log = @Log+'<st s="202" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'"/>'
	FROM @HarcodeSetting_Keno
	SELECT @Log = @Log+'</r>'

	IF(@@Error > 0)
	BEGIN
		SELECT @ErrCode = 102,@ErrMsg = 'Update Setting Unsucessfully !'
		RETURN;
	END

				EXEC DBLOG.bodb_customerlog.dbo.NAP_SpecialCustSetting_WriteLog
		@UserId = @UserID,
		@IP = @IP,
		@LicenseeID = @LicenseeID,
		@CurrencyID = @CurrencyID,
		@SPName = 'NAP_SpecialCustSetting_Upd',
		@CustId = @AgentId,
		@ActionId = 2,
		@Duration = @Duration,
		@Data = @Log,
		@OldData = @OldLog

END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_Upd] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_Upd] TO [bodbLicenseeNet]
GO 
