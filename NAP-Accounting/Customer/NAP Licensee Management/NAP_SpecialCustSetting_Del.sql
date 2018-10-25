/*<info serverAlias="DBCUST-CustDB" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/ 

USE CustDB
GO

ALTER PROCEDURE [dbo].[NAP_SpecialCustSetting_Del]
	@Licensee NVARCHAR(100),
	@CurrencyID INT,
	@AgentID INT = NULL,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(MAX) = '' OUTPUT,
	@IP NVARCHAR(20),
	@UserID INT
AS
/*
	Created: Dom
	Date: 2014-09-03
	Task: Delete Product Hardcode setting by licensee and currency
	DB: DBCUST/CustDB
		
	Revisions:
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]

*/
BEGIN
	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()

	DECLARE @OldLog NVARCHAR(MAX)
	DECLARE @LicenseeID INT
	
	SELECT @LicenseeID = [site].SiteID 
	FROM dbo.[Site] ibcsite 
		LEFT JOIN bodb_Licensee.dbo.Lrf_view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1 AND [site].SiteName = @Licensee

	SELECT @OldLog = '<r>'
	SELECT @OldLog = @OldLog+'<st s="'+ISNULL(CAST(SportType AS NVARCHAR(10)),'')+'" b="'+ISNULL(CAST(BetType AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(MaxPerMatch AS NVARCHAR(20)),'')+'" mpb="'+ISNULL(CAST(MaxPerBall AS NVARCHAR(20)),'')+'"/>'
	FROM Dep_CustBetLimit_Special cbs  WITH(NOLOCK)
	WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR cbs.AgentID = @AgentID )

	SELECT @OldLog = @OldLog+'<st s="202" b="'+ISNULL(CAST(gametypeid AS NVARCHAR(10)),'')+'" mb="'+ISNULL(CAST(MaxBet AS NVARCHAR(20)),'')+'" mpm="'+ISNULL(CAST(maxpergametype AS NVARCHAR(20)),'')+'" mpb=""/>'
	FROM Dep_CustBetLimitGameType_Special  cbs WITH(NOLOCK)
	WHERE cbs.[site]=@Licensee AND cbs.CurrencyID = @CurrencyID AND @AgentID IS NULL
	SELECT @OldLog = @OldLog+'</r>'

	IF(NOT EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )))
	BEGIN
		SELECT @ErrCode = 101,@ErrMsg = 'This Licensee is not existed '
		RETURN;
	END
	ELSE
	BEGIN
		DELETE [Dep_CustBetLimit_Special] WITH(ROWLOCK,UPDLOCK) WHERE [Site] = @Licensee AND CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )
		DELETE Dep_CustBetLimitGameType_Special  WITH(ROWLOCK,UPDLOCK) WHERE [Site] = @Licensee AND CurrencyID = @CurrencyID AND @AgentID IS NULL
	END

	IF @@Error >0
	BEGIN
		SELECT @ErrCode = 104,@ErrMsg = 'Delete Setting Unsucessfully !'
		RETURN;
	END

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	EXEC DBLOG.bodb_customerlog.dbo.NAP_SpecialCustSetting_WriteLog
		@UserId = @UserID,
		@IP = @IP,
		@LicenseeID = @LicenseeID,
		@CurrencyID = @CurrencyID,
		@SPName = 'NAP_SpecialCustSetting_Del',
		@CustId = @AgentId,
		@ActionId = 3,
		@Duration = @Duration,
		@Data = NULL,
		@OldData = @OldLog
END
GO

