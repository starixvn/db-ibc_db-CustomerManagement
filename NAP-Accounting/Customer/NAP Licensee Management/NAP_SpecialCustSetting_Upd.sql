/*<info serverAlias="DBCUST-CustDB" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/ 

ALTER PROCEDURE [dbo].[NAP_SpecialCustSetting_Upd]
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
	DB: DBCUST/CustDB
		
	Revisions:
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]
		- 202202220@Elodie: Apply DCS for SB [RedmineID: #167898] 
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
	DECLARE @HarcodeSetting TABLE(SportType INT, BetType INT, MaxBet MONEY, MaxPerMatch MONEY, MaxPerBall MONEY, MaxPayoutPerMatch MONEY)

	SELECT @LicenseeID = [site].SiteID 
	FROM dbo.[Site] ibcsite 
		LEFT JOIN bodb_Licensee.dbo.Lrf_view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1 AND [site].SiteName = @Licensee

	INSERT INTO @HarcodeSetting(SportType, BetType, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch)
	SELECT xmlData.Col.value('@sporttype','INT')
			,xmlData.Col.value('@bettype','INT')
			,xmlData.Col.value('@maxbet','MONEY')
			,xmlData.Col.value('@maxpermatch','MONEY')
			,xmlData.Col.value('@maxperball','MONEY')
			,xmlData.Col.value('@maxpayoutpermatch','MONEY')
	FROM @Settings.nodes('//settings/setting') xmlData(Col)
	
	SELECT @OldLog = '<r>'
	SELECT @OldLog = @OldLog+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'" mppm="'+ISNULL(CAST(MaxPayoutPerMatch AS NVARCHAR(20)),'')+'"/>'
	FROM Dep_CustBetLimit_Special cbs  WITH(NOLOCK)
	WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR cbs.AgentID = @AgentID )
	SELECT @OldLog = @OldLog+'</r>'
	
	IF(
		NOT EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting WHERE MaxBet IS NOT NULL AND MaxPerMatch IS NOT NULL AND MaxPayoutPerMatch IS NOT NULL AND SportType <> 161)
		AND NOT EXISTS(SELECT TOP 1 1 FROM @HarcodeSetting WHERE MaxBet IS NOT NULL AND MaxPerMatch IS NOT NULL AND MaxPerBall IS NOT NULL AND SportType = 161)
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
			,cbs.MaxPayoutPerMatch = hs.MaxPayoutPerMatch
		FROM Dep_CustBetLimit_Special cbs WITH(ROWLOCK,UPDLOCK)
		INNER JOIN @HarcodeSetting hs ON hs.sporttype = cbs.SportType and hs.Bettype=cbs.BetType
		WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR cbs.AgentID = @AgentID )

		------------Insert Missing sporttype------------------------
		INSERT INTO Dep_CustBetLimit_Special([Site], CurrencyID, SportType, AgentID, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype)
		SELECT @Licensee, @CurrencyID, SportType, @AgentID, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype 
		FROM @HarcodeSetting
		WHERE sporttype NOT IN (SELECT SportType FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) 
								WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )
								)
	END
	
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	--------------------------------------------Write Log-------------------------------------------------------------
	SELECT @Log ='<r>'
	SELECT @Log = @Log+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'" mppm="'+ISNULL(CAST(MaxPayoutPerMatch AS NVARCHAR(20)),'')+'"/>'
	FROM @HarcodeSetting
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

