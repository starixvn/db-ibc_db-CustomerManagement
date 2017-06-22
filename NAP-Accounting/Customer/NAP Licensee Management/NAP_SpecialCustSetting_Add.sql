
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Add    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Add    Script Date: 10/23/2014 12:48:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Add    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_Add]
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
		DB: DBTXN/CustDB
		
		Revisions:

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
	
	IF(EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID ))
		OR EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimitGameType_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND @AgentID IS NULL)
	)
	BEGIN
		SELECT @ErrCode = 101,@ErrMsg = 'This Licensee is existed '
		RETURN;
	END

	IF(EXISTS (SELECT TOP 1 1 FROM @HarcodeSetting))
	BEGIN
		INSERT INTO Dep_CustBetLimit_Special([Site], CurrencyID, SportType, AgentID, MaxBet, MaxPerMatch, MaxPerBall, Bettype)
		SELECT @Licensee, @CurrencyID, SportType, @AgentID, MaxBet, MaxPerMatch, MaxPerBall, Bettype FROM @HarcodeSetting
	END

	INSERT INTO @HarcodeSetting_Keno(SportType, BetType, MaxBet, MaxPerMatch, MaxPerBall)
	SELECT xmlData.Col.value('@sporttype','INT')
			,xmlData.Col.value('@bettype','INT')
			,xmlData.Col.value('@maxbet','MONEY')
			,xmlData.Col.value('@maxpermatch','MONEY')
			,xmlData.Col.value('@maxperball','MONEY')
	FROM @Settings.nodes('//settings/setting') xmlData(Col)
	WHERE xmlData.Col.value('@sporttype','INT') = 202 AND @AgentID IS NULL

	IF(EXISTS (SELECT TOP 1 1 FROM @HarcodeSetting_Keno)  AND @AgentID IS NULL)
	BEGIN
		INSERT INTO Dep_CustBetLimitGameType_Special([Site], CurrencyID, GameTypeID, MaxBet, maxpergametype)
		SELECT @Licensee, @CurrencyID,BetType, MaxBet, MaxPerMatch FROM @HarcodeSetting_Keno
	END 
	
	IF(@@Error > 0)
	BEGIN
		DELETE Dep_CustBetLimit_Special WITH(ROWLOCK,UPDLOCK) WHERE [Site] = @Licensee AND CurrencyID = @CurrencyID AND (@AgentID IS NULL OR AgentID = @AgentID)
		SELECT @ErrCode = 102,@ErrMsg = 'Insert Setting Unsucessfully !'
		RETURN;
	END

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	--------------------------------------------Write Log-------------------------------------------------------------
	DECLARE @Log NVARCHAR(MAX)='<r>'
	SELECT @Log = @Log+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'"/>'
	FROM @HarcodeSetting

	SELECT @Log = @Log+'<st s="202" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'"/>'
	FROM @HarcodeSetting_Keno

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

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_Add] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_Add] TO [bodbLicenseeNet]
GO 
