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
		- 20230224@Winfred: NAP LM - Enhance Bet Setting function for AM to use [redmine:#178105]
*/

/*<Settings>
  <Setting SportType="1" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="2" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="3" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="5" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="8" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="10" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="11" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="99" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="99" Bettype="9" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="154" Bettype="20" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="161" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="180" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="181" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="182" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="183" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="184" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="185" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="186" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="1" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="3" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="4" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="5" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="7" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="8" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="9" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="11" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
  <Setting SportType="202" Bettype="13" minbet="0" MaxBet="0" MaxPerMatch="0" MaxPerBall="0" />
</Settings>*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()

	DECLARE @Log NVARCHAR(MAX), @OldLog NVARCHAR(MAX), @xml XML, @Currency NVARCHAR(100), @Subsidiary NVARCHAR(100)
	DECLARE @LicenseeID INT
	DECLARE @HarcodeSetting TABLE(SportType INT, BetType INT, MinBet MONEY, MaxBet MONEY, MaxPerMatch MONEY, MaxPerBall MONEY, MaxPayoutPerMatch MONEY)

	SELECT @LicenseeID = [site].SiteID 
	FROM dbo.[Site] ibcsite 
		LEFT JOIN bodb_Licensee.dbo.Lrf_view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1 AND [site].SiteName = @Licensee

	INSERT INTO @HarcodeSetting(SportType, BetType, MinBet, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch)
	SELECT xmlData.Col.value('@sporttype','INT')
			,xmlData.Col.value('@bettype','INT')
			,xmlData.Col.value('@minbet','MONEY')
			,xmlData.Col.value('@maxbet','MONEY')
			,xmlData.Col.value('@maxpermatch','MONEY')
			,xmlData.Col.value('@maxperball','MONEY')
			,xmlData.Col.value('@maxpayoutpermatch','MONEY')
	FROM @Settings.nodes('//settings/setting') xmlData(Col)
		
	SELECT @Subsidiary = CASE WHEN @AgentID IS NOT NULL THEN  (c.username + CASE WHEN NULLIF(s.OperatorID,'') IS NOT NULL THEN ' ('+s.OperatorID+')'
												WHEN ISNULL(s.OperatorID,'') = '' AND s.AgentID IS NOT NULL THEN ' (sub)'
												ELSE '' END)	 ELSE '' END	,
			 @Currency = e.currency + '(' + ci.username + ')'  
	FROM Customer c WITH(NOLOCK) 
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.ExchangeId
			INNER JOIN custInfo ci WITH(NOLOCK) ON ci.custid = c.srecommend
			LEFT JOIN [SiteConfig].[dbo].[Operator] s WITH(NOLOCK) ON c.Custid=s.AgentID
	WHERE c.site = @Licensee AND c.currency = @CurrencyID AND ((@AgentID IS NOT NULL AND c.custid = @AgentID) OR (@AgentID IS NULL AND c.roleid = 4))
	
	SET @xml = (
			SELECT	@UserID								AS '@UserID',				
					@IP									AS '@IP',
					@Licensee							AS '@Licensee',
					@Currency							AS '@Currency',
					@CurrencyID							AS '@CurrencyID',
					@Subsidiary							AS '@Subsidiary',
					'E'									AS '@Language',
					'0'									AS '@Option',
					COALESCE(CAST(@ErrMsg				AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode				AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT  SportType			AS '@SportType',
								Bettype				AS '@Bettype',
								COALESCE(CAST(MinBet AS VARCHAR(50)), SPACE(1))	AS '@MinBet',
								COALESCE(CAST(MaxBet AS VARCHAR(50)), SPACE(1))	AS '@MaxBet',
								COALESCE(CAST(MaxPerMatch AS VARCHAR(50)), SPACE(1)) AS '@MaxPerMatch',
								COALESCE(CAST(MaxPerBall AS VARCHAR(50)), SPACE(1)) AS '@MaxPerBall',
								COALESCE(CAST(MaxPayoutPerMatch AS VARCHAR(50)), SPACE(1)) AS '@MaxPayoutPerMatch'
						FROM	Dep_CustBetLimit_Special cbs  WITH(NOLOCK)
						WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL 
								AND AgentID IS NULL) OR cbs.AgentID = @AgentID )
						ORDER BY SportType, Bettype
						FOR XML PATH('BL'), 
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @OldLog = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

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
		SET cbs.MinBet = hs.MinBet
			,cbs.MaxBet = hs.MaxBet
			,cbs.MaxPerMatch = hs.MaxPerMatch
			,cbs.MaxPerBall = hs.MaxPerBall
			,cbs.MaxPayoutPerMatch = hs.MaxPayoutPerMatch
		FROM Dep_CustBetLimit_Special cbs WITH(ROWLOCK,UPDLOCK)
		INNER JOIN @HarcodeSetting hs ON hs.sporttype = cbs.SportType and hs.Bettype=cbs.BetType
		WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR cbs.AgentID = @AgentID )

		------------Insert Missing sporttype------------------------
		INSERT INTO Dep_CustBetLimit_Special([Site], CurrencyID, SportType, AgentID, MinBet, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype)
		SELECT @Licensee, @CurrencyID, SportType, @AgentID, MinBet, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype 
		FROM @HarcodeSetting
		WHERE sporttype NOT IN (SELECT SportType FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) 
								WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )
								)
	END
	
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	--------------------------------------------Write Log-------------------------------------------------------------
	SET @xml = (
			SELECT	@UserID								AS '@UserID',				
					@IP									AS '@IP',
					@Licensee							AS '@Licensee',
					@Currency							AS '@Currency',
					@CurrencyID							AS '@CurrencyID',
					@Subsidiary							AS '@Subsidiary',
					'E'									AS '@Language',
					'0'									AS '@Option',
					COALESCE(CAST(@ErrMsg				AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode				AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT  SportType			AS '@SportType',
								Bettype				AS '@Bettype',
								COALESCE(CAST(MinBet AS VARCHAR(50)), SPACE(1))	AS '@MinBet',
								COALESCE(CAST(MaxBet AS VARCHAR(50)), SPACE(1))	AS '@MaxBet',
								COALESCE(CAST(MaxPerMatch AS VARCHAR(50)), SPACE(1)) AS '@MaxPerMatch',
								COALESCE(CAST(MaxPerBall AS VARCHAR(50)), SPACE(1)) AS '@MaxPerBall',
								COALESCE(CAST(MaxPayoutPerMatch AS VARCHAR(50)), SPACE(1)) AS '@MaxPayoutPerMatch'
						FROM	@HarcodeSetting
						ORDER BY SportType, Bettype
						FOR XML PATH('BL'), 
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SELECT @Log = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

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
		@ActionId = 16,
		@Duration = @Duration,
		@Data = @Log,
		@OldData = @OldLog

END
GO

