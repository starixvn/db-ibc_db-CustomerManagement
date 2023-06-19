/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,Dot_Member" viewers="" isFunction="0"></info>*/
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
		- 20230613@Luke: Option to apply Seize Bet if reach risk balance [Redmine: #187771]

	Param's Explanation:
	Example: Dot_Member_CustomerClassSitePolicySel @CustId=1315, @Site = '766666', @Currency = 20 , @IsTest=1, @CustomerClass =901, @SportType=1,
	@LeagueGroupID=6, @Platform =1, @liveindicator= 0	
	* @LeagueGroup : 0 All
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
		  @ReturnedSeizeBetAccumulatebal BIT,
		  @ReturnedEnableParlay BIT, 
		  @ReturnedPeakHourSpreadAdjustment SMALLINT, 
		  @ReturnedAgentBetInterval SMALLINT, 
		  @ReturnedLeagueGroupID SMALLINT
	
	CREATE TABLE #CustomerClass( Custid INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT, CustomerClass SMALLINT,SportType SMALLINT, 
			IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2), NextBetInterval SMALLINT, SuperBetInterval SMALLINT, 
			SiteBetInterval SMALLINT, MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT, SeizeBetAccumulateBal BIT,
			EnableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, LeagueGroupID SMALLINT)
	CREATE CLUSTERED INDEX CIX_CustomerClass ON #CustomerClass(Site, Currency, Platform)
	
	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClass]()

	 IF @ModeTest = 1 
	 BEGIN
		INSERT INTO #CustomerClass(Custid, Site, Currency, Platform, CustomerClass ,SportType, IsLive, DiffBalanceRatio, BetDelay, NextBetInterval,
			SuperBetInterval, SiteBetInterval, MinBet, MaxBet, MaxPerMatch, RepeatedBets, SeizeBetTicket, SeizeBetAccumulateBal, EnableParlay, 
			PeakHourSpreadAdjustment, AgentBetInterval, LeagueGroupID)
		SELECT @CustId AS CustId , @site AS site, @Currency AS currency, cm.Platform, cc.CustomerClass, cc.SportType, cc.IsLive, cc.DiffBalanceRatio, cc.BetDelay, cc.NextBetInterval,
			cc.SuperBetInterval, cc.SiteBetInterval, cc.MinBet, cc.MaxBet, cc.MaxPerMatch, cc.RepeatedBets, cc.SeizeBetTicket, cc.SeizeBetAccumulateBal, cc.EnableParlay,
			cc.PeakHourSpreadAdjustment, cc.AgentBetInterval, clg.LeagueGroupID
		FROM [dbo].[CustomerClassSiteManagement_UAT] cm WITH(NOLOCK)
			INNER JOIN CustomerClassPolicyManagement_UAT cpm WITH(NOLOCK) ON cm.PolicyID = cpm.PolicyID
			INNER JOIN CustomerClassPolicyRule_UAT cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
			INNER JOIN CustomerClassRule_UAT cc WITH(NOLOCK) ON cp.RuleID = cc.RuleID AND cc.CustomerClass = @CustomerClass
			INNER JOIN CustomerClassRuleLeagueGroup_UAT clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
		WHERE cm.Site = @site AND cm.Currency = @Currency 
			AND cpm.SportType = @SportType 
			AND (clg.LeagueGroupID = @LeagueGroupID OR @LeagueGroupID = 0)
			AND cpm.IsTest = @IsTest 
			AND cm.Platform IN (0,@Platform) 
			AND cc.IsLive IN (2, @liveindicator)
	 END
	 ELSE
	 BEGIN
		
		INSERT INTO #CustomerClass(Custid, Site, Currency, Platform, CustomerClass ,SportType, IsLive, DiffBalanceRatio, BetDelay, NextBetInterval,
			SuperBetInterval, SiteBetInterval, MinBet, MaxBet, MaxPerMatch, RepeatedBets, SeizeBetTicket, EnableParlay, PeakHourSpreadAdjustment, AgentBetInterval, LeagueGroupID)
		SELECT @CustId AS CustId , @site AS site, @Currency AS currency, cm.Platform, cc.CustomerClass, cc.SportType, cc.IsLive, cc.DiffBalanceRatio, cc.BetDelay, cc.NextBetInterval,
			cc.SuperBetInterval, cc.SiteBetInterval, cc.MinBet, cc.MaxBet, cc.MaxPerMatch, cc.RepeatedBets, cc.SeizeBetTicket, cc.SeizeBetAccumulateBal, cc.EnableParlay, cc.PeakHourSpreadAdjustment, cc.AgentBetInterval, clg.LeagueGroupID
		FROM [dbo].[CustomerClassSiteManagement] cm WITH(NOLOCK)
			INNER JOIN CustomerClassPolicyManagement cpm WITH(NOLOCK) ON cm.PolicyID = cpm.PolicyID
			INNER JOIN CustomerClassPolicyRule cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
			INNER JOIN CustomerClassRule cc WITH(NOLOCK) ON cp.RuleID = cc.RuleID AND cc.CustomerClass = @CustomerClass
			INNER JOIN CustomerClassRuleLeagueGroup clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
		WHERE cm.Site = @site AND cm.Currency = @Currency 
			AND cpm.SportType = @SportType 
			AND (clg.LeagueGroupID = @LeagueGroupID OR @LeagueGroupID = 0)
			AND cpm.IsTest = @IsTest 
			AND cm.Platform IN (0,@Platform) 
			AND cc.IsLive IN (2, @liveindicator)
	 END

	 SELECT 
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
			@ReturnedSeizeBetAccumulatebal = MIN(CASE WHEN ISNULL(SeizeBetAccumulateBal,0) = 0 THEN 0 ELSE 1 END),
			@ReturnedEnableParlay = MIN( CASE WHEN EnableParlay  = 0 THEN 0 ELSE 1 END), 
			@ReturnedPeakHourSpreadAdjustment = MAX(PeakHourSpreadAdjustment) ,
			@ReturnedLeagueGroupID = LeagueGroupID,
			@ReturnedPlatform = @Platform
	 FROM #CustomerClass 
	 GROUP BY Custid, Site, Currency , SportType, CustomerClass,LeagueGroupID

	SELECT @ReturnedCustomerClass AS ReturnedCustomerClass, 
		  @ReturnedSite AS ReturnedSite, 
		  @ReturnedCurrency AS ReturnedCurrency,
		  @ReturnedPlatform AS ReturnedPlatform,
		  @ReturnedSportType AS ReturnedSportType, 
		  @ReturnedDiffBalanceRatio AS ReturnedDiffBalanceRatio, 
		  @ReturnedBetDelay AS ReturnedBetDelay,
		  @ReturnedNextBetInterval AS ReturnedNextBetInterval, 
		  @ReturnedSuperBetInterval AS ReturnedSuperBetInterval, 
		  @ReturnedSiteBetInterval AS ReturnedSiteBetInterval,
		  @ReturnedRepeatedBets AS ReturnedRepeatedBets,
		  @ReturnedEnableParlay AS ReturnedEnableParlay, 
		  @ReturnedPeakHourSpreadAdjustment AS ReturnedPeakHourSpreadAdjustment, 
		  @ReturnedSeizeBetTicket AS ReturnedSeizeBetTicket,
		  @ReturnedSeizeBetAccumulateBal AS ReturnedSeizeBetAccumulateBal,
		  @ReturnedMinBet AS ReturnedMinBet, 
		  @ReturnedMaxBet AS ReturnedMaxBet, 
		  @ReturnedMaxPerMatch AS ReturnedMaxPerMatch,  
		  @ReturnedAgentBetInterval AS ReturnedAgentBetInterval, 
		  @ReturnedLeagueGroupID AS ReturnedLeagueGroupID
	 	

END