/*<info serverAlias="DBCUST-CustDB" executers="wsv_lap" viewers="vnteam" isFunction="0"></info>*/ 

ALTER PROCEDURE [dbo].[NAP_SpecialCustSetting_Add]
	@Licensee NVARCHAR(100),
	@CurrencyID INT,
	@AgentID INT = NULL,
	@Settings XML,
	@ErrCode INT = 0  OUTPUT,
	@ErrMsg NVARCHAR(MAX)=''  OUTPUT,
	@IP NVARCHAR(20),
	@UserID INT
AS

/*
	Created: Dom
	Date: 2014-09-03
	Task: Insert harcode setting
	DB: DBCUST/CustDB
		
	Revisions:
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]
		- 202202220@Elodie: Apply DCS for SB [RedmineID: #167898] 
		- 20230224@Winfred: NAP LM - Enhance Bet Setting function for AM to use [redmine:#178105]
*/

/*<Settings>
  <Setting sporttype="1" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="2" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="3" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="5" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="8" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="10" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="11" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="99" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="99" bettype="9" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="154" bettype="20" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="161" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="180" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="181" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="182" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="183" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="184" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="185" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="186" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="1" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="3" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="4" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="5" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="7" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="8" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="9" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="11" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="13" minbet="0" maxbet="0" maxpermatch="0" maxperball="0" />
</Settings>*/

BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	DECLARE @Subsidiary NVARCHAR(100), @xml XML, @Currency NVARCHAR(100) , @logSpData  NVARCHAR(MAX)
	SET @startRun = GETDATE()

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
	
	IF EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID ))
	BEGIN
		SELECT @ErrCode = 101,@ErrMsg = 'This Licensee is existed '
		RETURN;
	END

	IF(EXISTS (SELECT TOP 1 1 FROM @HarcodeSetting))
	BEGIN
		INSERT INTO Dep_CustBetLimit_Special([Site], CurrencyID, SportType, AgentID,MinBet, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype)
		SELECT @Licensee, @CurrencyID, SportType, @AgentID, MinBet, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype FROM @HarcodeSetting
	END
	
	IF(@@Error > 0)
	BEGIN
		SELECT @ErrCode = 102,@ErrMsg = 'Insert Setting Unsucessfully !'
		RETURN
	END
	
	SELECT @Subsidiary = CASE WHEN @AgentID IS NOT NULL THEN  (c.username + CASE WHEN NULLIF(s.OperatorID,'') IS NOT NULL THEN ' ('+s.OperatorID+')'
												WHEN ISNULL(s.OperatorID,'') = '' AND s.AgentID IS NOT NULL THEN ' (sub)'
												ELSE '' END)	 ELSE '' END	,
			 @Currency = e.currency + '(' + ci.username + ')'  
	FROM Customer c WITH(NOLOCK) 
			INNER JOIN exchange e WITH(NOLOCK) ON c.currency = e.ExchangeId
			INNER JOIN custInfo ci WITH(NOLOCK) ON ci.custid = c.srecommend
			LEFT JOIN [SiteConfig].[dbo].[Operator] s WITH(NOLOCK) ON c.Custid=s.AgentID
	WHERE c.site = @Licensee AND c.currency = @CurrencyID AND ((@AgentID IS NOT NULL AND c.custid = @AgentID) OR (@AgentID IS NULL AND c.roleid = 4))

	-- Log new Default data
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
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	--------------------------------------------Write Log-------------------------------------------------------------
	EXEC DBLOG.bodb_customerlog.dbo.NAP_SpecialCustSetting_WriteLog
		@UserId = @UserID,
		@IP = @IP,
		@LicenseeID = @LicenseeID,
		@CurrencyID = @CurrencyID,
		@SPName = 'NAP_SpecialCustSetting_Add',
		@CustId = @AgentId,
		@ActionId = 15,
		@Duration = @Duration,
		@Data = @logSpData,
		@OldData = NULL
END
GO
