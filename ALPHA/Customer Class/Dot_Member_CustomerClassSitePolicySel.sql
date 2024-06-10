/*<info serverAlias="DBACC-bodb02,DBCUST-CUSTDB" executers="Dot_Admin,Dot_Member" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CustomerClassSitePolicySel] 
	@CustId INT,
	@Site NVARCHAR(50), 
	@Currency TINYINT,
	@IsTest BIT = 0,
	@CustomerClass SMALLINT,
	@SportType SMALLINT,
	@LeagueGroupID SMALLINT,
	@Platform TINYINT = 0,
	@liveindicator BIT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original: Dot_Member_GetCustomerClassSitePolicy

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20230821@Winfred: Fix Param LeagueGroupID when all value  [RedmineID: #192953] 
		- 20231114@Winfred: [NAP CM] Customer Class mng - Return as 1 if Null  [RedmineID: #196827]
		- 20231101@Winfred: [NAP CM] Customer Class - Auto include new items for rows that is selected option "All" [RedmineID: #186699] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  

	Param's Explanation:
	Example: Dot_Member_CustomerClassSitePolicySel @CustId=1315, @Site = '766666', @Currency = 20 , @IsTest=1, @CustomerClass =901, @SportType=1,
	@LeagueGroupID=6, @Platform =1, @liveindicator= 0	
	* @LeagueGroup : -1 All
	* @liveindicator : 2 All , 1 live, 0 Non Live
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @ModeTest BIT,
		  @ReturnedCustomerClass SMALLINT, 
		  @ReturnedSite NVARCHAR(50),
		  @ReturnedCurrency TINYINT,
		  @ReturnedPlatform TINYINT,
		  @ReturnedSportType SMALLINT, 
		  @ReturnedDiffBalanceRatio DECIMAL(9, 2), 
		  @ReturnedBetDelay DECIMAL(9, 2),
		  @ReturnedNextBetInterval SMALLINT, 
		  @ReturnedSuperBetInterval SMALLINT, 
		  @ReturnedSiteBetInterval SMALLINT,
		  @ReturnedMinBet INT, 
		  @ReturnedMaxBet INT, 
		  @ReturnedMaxPerMatch INT, 
		  @ReturnedRepeatedBets TINYINT, 
		  @ReturnedSeizeBetTicket TINYINT,
		  @ReturnedDisableParlay BIT, 
		  @ReturnedPeakHourSpreadAdjustment SMALLINT, 
		  @ReturnedAgentBetInterval SMALLINT, 
		  @ReturnedLeagueGroupID SMALLINT
	
	CREATE TABLE #CustomerClass( Custid INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT, CustomerClass SMALLINT,SportType SMALLINT, 
			IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2), NextBetInterval SMALLINT, SuperBetInterval SMALLINT, 
			SiteBetInterval SMALLINT, MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT,
			DisableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, LeagueGroupID SMALLINT)
	CREATE CLUSTERED INDEX CIX_CustomerClass ON #CustomerClass(Site, Currency, Platform)
	
	DECLARE @SiteTbl TABLE(Site NVARCHAR(50))
	DECLARE @OfferTbl TABLE(Site NVARCHAR(50), Currency INT, Platform TINYINT)
	INSERT INTO @SiteTbl (Site) SELECT  'All' --All
	INSERT INTO @SiteTbl (Site) SELECT @site

	IF 	EXISTS(SELECT TOP 1 1 FROM Site a WITH(NOLOCK) WHERE site = @site AND IsDeposit = 0 )
	BEGIN
		INSERT INTO @SiteTbl (Site) SELECT  'AllCredit'
	END
	ELSE
	BEGIN
		INSERT INTO @SiteTbl (Site) SELECT  'AllDeposit'
	END

	INSERT INTO @OfferTbl (Site, Currency, Platform) 
	SELECT Site , c.Currency, d.Platform
	FROM @SiteTbl s
		CROSS APPLY (SELECT @Currency AS  Currency UNION SELECT 0 AS  Currency) c
		CROSS APPLY (SELECT @Platform AS  Platform UNION SELECT 0 AS Platform) d

	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClass]()

	 IF @ModeTest = 1 
	 BEGIN
		INSERT INTO #CustomerClass(Custid, Site, Currency, Platform, CustomerClass ,SportType, IsLive, DiffBalanceRatio, BetDelay, NextBetInterval,
			SuperBetInterval, SiteBetInterval, MinBet, MaxBet, MaxPerMatch, RepeatedBets, SeizeBetTicket, DisableParlay, 
			PeakHourSpreadAdjustment, AgentBetInterval, LeagueGroupID)
		SELECT @CustId AS CustId , @site AS site, @Currency AS currency, cm.Platform, cc.CustomerClass, cc.SportType, cc.IsLive, cc.DiffBalanceRatio, cc.BetDelay, cc.NextBetInterval,
			cc.SuperBetInterval, cc.SiteBetInterval, cc.MinBet, cc.MaxBet, cc.MaxPerMatch, cc.RepeatedBets, cc.SeizeBetTicket, cc.DisableParlay,
			cc.PeakHourSpreadAdjustment, cc.AgentBetInterval, clg.LeagueGroupID
		FROM [dbo].[CustomerClassSiteManagement_UAT] cm WITH(NOLOCK)
			INNER JOIN CustomerClassPolicyManagement_UAT cpm WITH(NOLOCK) ON cm.PolicyID = cpm.PolicyID
			INNER JOIN CustomerClassPolicyRule_UAT cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
			INNER JOIN CustomerClassRule_UAT cc WITH(NOLOCK) ON cp.RuleID = cc.RuleID AND cc.CustomerClass = @CustomerClass
			INNER JOIN CustomerClassRuleLeagueGroup_UAT clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
			INNER JOIN @OfferTbl s ON cm.Site = s.Site AND cm.Currency = s.Currency AND cm.Platform = s.Platform
		WHERE cpm.SportType = @SportType 
			AND (clg.LeagueGroupID = @LeagueGroupID OR clg.LeagueGroupID = -1)
			AND cpm.IsTest = @IsTest 
			AND cc.IsLive IN (2, @liveindicator)
	 END
	 ELSE
	 BEGIN
		
		INSERT INTO #CustomerClass(Custid, Site, Currency, Platform, CustomerClass ,SportType, IsLive, DiffBalanceRatio, BetDelay, NextBetInterval,
			SuperBetInterval, SiteBetInterval, MinBet, MaxBet, MaxPerMatch, RepeatedBets, SeizeBetTicket, DisableParlay, PeakHourSpreadAdjustment, AgentBetInterval, LeagueGroupID)
		SELECT @CustId AS CustId , @site AS site, @Currency AS currency, cm.Platform, cc.CustomerClass, cc.SportType, cc.IsLive, cc.DiffBalanceRatio, cc.BetDelay, cc.NextBetInterval,
			cc.SuperBetInterval, cc.SiteBetInterval, cc.MinBet, cc.MaxBet, cc.MaxPerMatch, cc.RepeatedBets, cc.SeizeBetTicket, cc.DisableParlay, cc.PeakHourSpreadAdjustment, cc.AgentBetInterval, clg.LeagueGroupID
		FROM [dbo].[CustomerClassSiteManagement] cm WITH(NOLOCK)
			INNER JOIN CustomerClassPolicyManagement cpm WITH(NOLOCK) ON cm.PolicyID = cpm.PolicyID
			INNER JOIN CustomerClassPolicyRule cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
			INNER JOIN CustomerClassRule cc WITH(NOLOCK) ON cp.RuleID = cc.RuleID AND cc.CustomerClass = @CustomerClass
			INNER JOIN CustomerClassRuleLeagueGroup clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
			INNER JOIN @OfferTbl s ON cm.Site = s.Site AND cm.Currency = s.Currency AND cm.Platform = s.Platform
		WHERE cpm.SportType = @SportType 
			AND (clg.LeagueGroupID = @LeagueGroupID OR clg.LeagueGroupID = -1)
			AND cpm.IsTest = @IsTest 
			AND cc.IsLive IN (2, @liveindicator)
	 END

	 SELECT TOP 1
			@ReturnedSite = Site, 
			@ReturnedCurrency = Currency , 
			@ReturnedCustomerClass = CustomerClass,
			@ReturnedSportType = SportType, 
			@ReturnedDiffBalanceRatio = MAX(DiffBalanceRatio), 
			@ReturnedBetDelay = Max(BetDelay), 
			@ReturnedNextBetInterval = Max(NextBetInterval),
			@ReturnedSuperBetInterval = Max(SuperBetInterval), 
			@ReturnedSiteBetInterval = Max(SiteBetInterval), 
			@ReturnedMinBet = Max(MinBet), 
			@ReturnedMaxBet = Min(MaxBet), 
			@ReturnedMaxPerMatch = Min(MaxPerMatch), 
			@ReturnedRepeatedBets = Min(RepeatedBets), 
			@ReturnedSeizeBetTicket = Max(SeizeBetTicket), 
			@ReturnedDisableParlay = MAX(CASE WHEN DisableParlay  = 0 THEN 0 ELSE 1 END), 
			@ReturnedPeakHourSpreadAdjustment = MAX(PeakHourSpreadAdjustment) ,
			@ReturnedLeagueGroupID = LeagueGroupID,
			@ReturnedPlatform = @Platform
	 FROM #CustomerClass 
	 GROUP BY Custid, Site, Currency , SportType, CustomerClass,LeagueGroupID
	 ORDER BY LeagueGroupID DESC

	SELECT @ReturnedCustomerClass AS ReturnedCustomerClass, 
		  @ReturnedSite AS ReturnedSite, 
		  @ReturnedCurrency AS ReturnedCurrency,
		  @ReturnedPlatform AS ReturnedPlatform,
		  @ReturnedSportType AS ReturnedSportType, 
		  ISNULL(@ReturnedDiffBalanceRatio,1) AS ReturnedDiffBalanceRatio, 
		  ISNULL(@ReturnedBetDelay,1) AS ReturnedBetDelay,
		  @ReturnedNextBetInterval AS ReturnedNextBetInterval, 
		  @ReturnedSuperBetInterval AS ReturnedSuperBetInterval, 
		  @ReturnedSiteBetInterval AS ReturnedSiteBetInterval,
		  @ReturnedRepeatedBets AS ReturnedRepeatedBets,
		  @ReturnedDisableParlay AS ReturnedDisableParlay, 
		  @ReturnedPeakHourSpreadAdjustment AS ReturnedPeakHourSpreadAdjustment, 
		  @ReturnedSeizeBetTicket AS ReturnedSeizeBetTicket,
		  @ReturnedMinBet AS ReturnedMinBet, 
		  @ReturnedMaxBet AS ReturnedMaxBet, 
		  @ReturnedMaxPerMatch AS ReturnedMaxPerMatch,  
		  @ReturnedAgentBetInterval AS ReturnedAgentBetInterval, 
		  @ReturnedLeagueGroupID AS ReturnedLeagueGroupID
	 	

END