/*<info serverAlias="DBCUST-CustDB" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/ 

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
		- 202202220@Elodie: Apply DCS for SB [RedmineID: #167898] 
		- 20230224@Winfred: NAP LM - Enhance Bet Setting function for AM to use [redmine:#178105]

*/
BEGIN
	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = GETDATE()

	DECLARE @OldLog NVARCHAR(MAX), @Currency NVARCHAR(100), @Subsidiary NVARCHAR(100), @xml XML
	DECLARE @LicenseeID INT
	
	SELECT @LicenseeID = [site].SiteID 
	FROM dbo.[Site] ibcsite 
		LEFT JOIN bodb_Licensee.dbo.Lrf_view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1 AND [site].SiteName = @Licensee

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

	IF(NOT EXISTS(SELECT TOP 1 1 FROM Dep_CustBetLimit_Special cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID = @CurrencyID AND( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )))
	BEGIN
		SELECT @ErrCode = 101,@ErrMsg = 'This Licensee is not existed '
		RETURN;
	END
	ELSE
	BEGIN
		DELETE [Dep_CustBetLimit_Special] WITH(ROWLOCK,UPDLOCK) WHERE [Site] = @Licensee AND CurrencyID = @CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR AgentID = @AgentID )
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
		@ActionId = 17,
		@Duration = @Duration,
		@Data = NULL,
		@OldData = @OldLog
END
GO

