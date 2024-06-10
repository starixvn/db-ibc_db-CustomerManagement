/*<info serverAlias="DBACC-bodb02,DBCUST-CUSTDB" executers="Dot_Admin,svc_tig" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CustomerClassSettingSel] 
	@Site NVARCHAR(50), 
	@Currency INT,
	@IsTest BIT = 0,
	@CustomerClass SMALLINT,
	@SportType SMALLINT,
	@LeagueGroupID SMALLINT,
	@Platform TINYINT = 0,
	@liveindicator BIT,
	@IsDeposit BIT
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
		- 20240302@Elodie: Remove @CustId param [RedmineID: #201770] 
		- 20240306@Winfred: [NAP CM] Customer Class - Tune the CM SP Integration [RedmineID: #201956] 
		- 20240610@Winfred: NAPCM - CCS - EC24 Preparation [RedmineID: #206297]  

	Param's Explanation:
	Example: Dot_Member_CustomerClassSettingSel @Site = '766666', @Currency = 20 , @IsTest=1, @CustomerClass =901, @SportType=1,
	@LeagueGroupID=6, @Platform =1, @liveindicator= 0	
	* @LeagueGroup : -1 All
	* @liveindicator : 2 All , 1 live, 0 Non Live
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ModeTest BIT, @SiteNew nvarchar(50), @n INT = 2000000
	
	SELECT  @SiteNew = CASE WHEN @IsDeposit = 0 THEN 'AllCredit' ELSE 'AllDeposit' END
		
	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClass]()

	 IF @ModeTest = 1 
	 BEGIN
		SELECT
			CASE WHEN MAX(LeagueGroupID) IS NOT NULL THEN @CustomerClass ELSE NULL END AS ReturnedCustomerClass,
			@site AS ReturnedSite, 
			@Currency AS ReturnedCurrency, 
			@Platform AS ReturnedPlatform, 
			@SportType AS ReturnedSportType, 
			ISNULL(MAX(cc.DiffBalanceRatio),1) AS ReturnedDiffBalanceRatio, 
			ISNULL(Max(cc.BetDelay),1) AS ReturnedBetDelay,
			Max(cc.NextBetInterval) AS ReturnedNextBetInterval, 
			Max(cc.SuperBetInterval) AS ReturnedSuperBetInterval, 
			Max(cc.SiteBetInterval) AS ReturnedSiteBetInterval,
			Min(cc.RepeatedBets) AS ReturnedRepeatedBets,
			MAX(CASE WHEN cc.DisableParlay  = 0 THEN 0 ELSE 1 END) AS ReturnedDisableParlay, 
			MAX(cc.PeakHourSpreadAdjustment) AS ReturnedPeakHourSpreadAdjustment, 
			Max(cc.SeizeBetTicket) AS ReturnedSeizeBetTicket,
			Max(cc.MinBet) AS ReturnedMinBet, 
			Min(cc.MaxBet) AS ReturnedMaxBet, 
			Min(cc.MaxPerMatch) AS ReturnedMaxPerMatch,  
			Max(cc.AgentBetInterval) AS ReturnedAgentBetInterval, 
			MAX(LeagueGroupID) AS ReturnedLeagueGroupID
		FROM 
			[dbo].[CustomerClassSiteManagement_UAT] cm WITH(NOLOCK)
			CROSS APPLY (SELECT TOP (@n) cc.DiffBalanceRatio, 
								cc.BetDelay,
								cc.NextBetInterval, 
								cc.SuperBetInterval, 
								cc.SiteBetInterval,
								cc.RepeatedBets,
								cc.DisableParlay, 
								cc.PeakHourSpreadAdjustment, 
								cc.SeizeBetTicket,
								cc.MinBet, 
								cc.MaxBet, 
								cc.MaxPerMatch,  
								cc.AgentBetInterval,
								clg.LeagueGroupID
							FROM CustomerClassRule_UAT cc WITH(NOLOCK) 
								INNER JOIN CustomerClassPolicyRule_UAT cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
								INNER JOIN CustomerClassPolicyManagement_UAT cpm WITH(NOLOCK) ON cp.RuleID = cc.RuleID 
								INNER JOIN CustomerClassRuleLeagueGroup_UAT clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
							WHERE cm.PolicyID = cpm.PolicyID
									AND cc.CustomerClass = @CustomerClass
									AND cc.SportType = @SportType 
									AND clg.LeagueGroupID IN (@LeagueGroupID, -1)
									AND cpm.IsTest = @IsTest 
									AND cc.IsLive IN (2, @liveindicator))cc
								
		WHERE cm.Site IN ('All', @SiteNew, @Site)
			AND cm.Currency IN (@Currency, 0)
			AND cm.Platform IN (0, @Platform)
		 OPTION(OPTIMIZE FOR (@n =1), FORCE ORDER)
	 END
	 ELSE
	 BEGIN		
		SELECT
			CASE WHEN MAX(LeagueGroupID) IS NOT NULL THEN @CustomerClass ELSE NULL END AS ReturnedCustomerClass,
			@site AS ReturnedSite, 
			@Currency AS ReturnedCurrency, 
			@Platform AS ReturnedPlatform, 
			@SportType AS ReturnedSportType, 
			ISNULL(MAX(cc.DiffBalanceRatio),1) AS ReturnedDiffBalanceRatio, 
			ISNULL(Max(cc.BetDelay),1) AS ReturnedBetDelay,
			Max(cc.NextBetInterval) AS ReturnedNextBetInterval, 
			Max(cc.SuperBetInterval) AS ReturnedSuperBetInterval, 
			Max(cc.SiteBetInterval) AS ReturnedSiteBetInterval,
			Min(cc.RepeatedBets) AS ReturnedRepeatedBets,
			MAX(CASE WHEN cc.DisableParlay  = 0 THEN 0 ELSE 1 END) AS ReturnedDisableParlay, 
			MAX(cc.PeakHourSpreadAdjustment) AS ReturnedPeakHourSpreadAdjustment, 
			Max(cc.SeizeBetTicket) AS ReturnedSeizeBetTicket,
			Max(cc.MinBet) AS ReturnedMinBet, 
			Min(cc.MaxBet) AS ReturnedMaxBet, 
			Min(cc.MaxPerMatch) AS ReturnedMaxPerMatch,  
			Max(cc.AgentBetInterval) AS ReturnedAgentBetInterval, 
			MAX(LeagueGroupID) AS ReturnedLeagueGroupID
		FROM 
			[dbo].[CustomerClassSiteManagement] cm WITH(NOLOCK)
			CROSS APPLY (SELECT TOP (@n) cc.DiffBalanceRatio, 
								cc.BetDelay,
								cc.NextBetInterval, 
								cc.SuperBetInterval, 
								cc.SiteBetInterval,
								cc.RepeatedBets,
								cc.DisableParlay, 
								cc.PeakHourSpreadAdjustment, 
								cc.SeizeBetTicket,
								cc.MinBet, 
								cc.MaxBet, 
								cc.MaxPerMatch,  
								cc.AgentBetInterval,
								clg.LeagueGroupID
							FROM CustomerClassRule cc WITH(NOLOCK) 
								INNER JOIN CustomerClassPolicyRule cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
								INNER JOIN CustomerClassPolicyManagement cpm WITH(NOLOCK) ON cp.RuleID = cc.RuleID 
								INNER JOIN CustomerClassRuleLeagueGroup clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
							WHERE cm.PolicyID = cpm.PolicyID
									AND cc.CustomerClass = @CustomerClass
									AND cc.SportType = @SportType 
									AND clg.LeagueGroupID IN (@LeagueGroupID, -1)
									AND cpm.IsTest = @IsTest 
									AND cc.IsLive IN (2, @liveindicator))cc
								
		WHERE cm.Site IN ('All', @SiteNew, @Site)
			AND cm.Currency IN (@Currency, 0)
			AND cm.Platform IN (0, @Platform)
		 OPTION(OPTIMIZE FOR (@n =1), FORCE ORDER)
	END
END