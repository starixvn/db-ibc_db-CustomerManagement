/*<info serverAlias="DBCUST-CustDB" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/ 

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

*/

/*<Settings>
  <Setting sporttype="1" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="2" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="3" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="5" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="8" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="10" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="11" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="99" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="99" bettype="9" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="154" bettype="20" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="161" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="180" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="181" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="182" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="183" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="184" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="185" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="186" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="1" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="3" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="4" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="5" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="7" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="8" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="9" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="11" maxbet="0" maxpermatch="0" maxperball="0" />
  <Setting sporttype="202" bettype="13" maxbet="0" maxpermatch="0" maxperball="0" />
</Settings>*/

BEGIN
	SET NOCOUNT ON

	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()

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
	
	IF EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID ))
	BEGIN
		SELECT @ErrCode = 101,@ErrMsg = 'This Licensee is existed '
		RETURN;
	END

	IF(EXISTS (SELECT TOP 1 1 FROM @HarcodeSetting))
	BEGIN
		INSERT INTO Dep_CustBetLimit_Special([Site], CurrencyID, SportType, AgentID, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype)
		SELECT @Licensee, @CurrencyID, SportType, @AgentID, MaxBet, MaxPerMatch, MaxPerBall, MaxPayoutPerMatch, Bettype FROM @HarcodeSetting
	END
	
	IF(@@Error > 0)
	BEGIN
		SELECT @ErrCode = 102,@ErrMsg = 'Insert Setting Unsucessfully !'
		RETURN
	END

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	--------------------------------------------Write Log-------------------------------------------------------------
	DECLARE @Log NVARCHAR(MAX)='<r>'
	SELECT @Log = @Log+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'" mppm="'+ISNULL(CAST(MaxPayoutPerMatch AS NVARCHAR(20)),'')+'"/>'
	FROM @HarcodeSetting
	SELECT @Log = @Log+'</r>'	

	EXEC DBLOG.bodb_customerlog.dbo.NAP_SpecialCustSetting_WriteLog
		@UserId = @UserID,
		@IP = @IP,
		@LicenseeID = @LicenseeID,
		@CurrencyID = @CurrencyID,
		@SPName = 'NAP_SpecialCustSetting_Add',
		@CustId = @AgentId,
		@ActionId = 1,
		@Duration = @Duration,
		@Data = @Log,
		@OldData = NULL
END
GO
