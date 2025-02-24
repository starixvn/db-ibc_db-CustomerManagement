/*<info serverAlias="DBCUST-CUSTDB" executers="Dot_Admin,Dot_Member,svc_tig" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Dot_Member_CustomerClassSettingSel] 
	@Site NVARCHAR(50), 
	@Currency INT,
	@IsTest BIT = 0,
	@CustomerClass SMALLINT,
	@SportType SMALLINT,
	@LeagueGroupID SMALLINT,
	@Platform TINYINT = 0,
	@liveindicator BIT,
	@IsDeposit BIT,
	@SportsCC SMALLINT = 0
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
		- 20240823@Winfred: [NAP CM] CCMgt - Integrate for Sport CC - Saba Sport [RedmineID: #209775] 
		- 20240827@Winfred: [NAP CM] NAP CM - SP Dot_Member_CustomerClassSettingSel return data although rule is disabled [RedmineID: #209939] 
		- 20240925@Winfred: [NAP CM] Customer Class - Allow licensees to bypass any restrict rules [188589]
		- 2050224@Winfred: [NAP CM] Risk Setting - Sportsbook CC Management - No Restriction on Other Sports [218259]

	Param's Explanation:
	Example: Dot_Member_CustomerClassSettingSel @Site = '766666', @Currency = 20 , @IsTest=1, @CustomerClass =901, @SportType=1,
	@LeagueGroupID=6, @Platform =1, @liveindicator= 0 , @IsDeposit = 1, @SportsCC = 0	
	* @LeagueGroup : -1 All
	* @liveindicator : 2 All , 1 live, 0 Non Live
*/ 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ModeTest BIT, @SiteNew nvarchar(50), @n INT = 2000000 ,@SportTypeSetting SMALLINT = @SportType,
		@ReturnedCustomerClass SMALLINT, 
		@ReturnedSportsCC SMALLINT, 
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
	
	SELECT  @SiteNew = CASE WHEN @IsDeposit = 0 THEN 'AllCredit' ELSE 'AllDeposit' END
		
	IF @IsTest = 1
	BEGIN
		SELECT @IsTest = dbo.f_CheckSPVersion(@@PROCID)
	END

	SELECT @ModeTest = [dbo].[f_GetModeCustomerClass]()

	 IF @ModeTest = 1 
	 BEGIN
		
		IF EXISTS (SELECT TOP 1 1 FROM CustomerClassPolicyManagement_UAT cc WITH (NOLOCK) WHERE SportType = @SportType)
		BEGIN
			SET @SportTypeSetting = @SportType
		END
		ELSE IF @SportType <= 99 AND @SportType NOT IN (13, 52, 54, 55, 56)
		BEGIN
			SET @SportTypeSetting = 99
		END

		SELECT TOP 1	@ReturnedCustomerClass           =CASE WHEN ReturnedLeagueGroupID IS NOT NULL THEN @CustomerClass ELSE NULL END                     , 
						@ReturnedSportsCC                =CASE WHEN ReturnedLeagueGroupID IS NOT NULL THEN @SportsCC ELSE NULL END                          , 
						@ReturnedDiffBalanceRatio        =ReturnedDiffBalanceRatio					, 
						@ReturnedBetDelay                =ReturnedBetDelay							, 
						@ReturnedNextBetInterval         =ReturnedNextBetInterval                   , 
						@ReturnedSuperBetInterval        =ReturnedSuperBetInterval                  ,
						@ReturnedSiteBetInterval         =ReturnedSiteBetInterval                   , 
						@ReturnedRepeatedBets            =ReturnedRepeatedBets                      , 
						@ReturnedDisableParlay           =ReturnedDisableParlay                     , 
						@ReturnedPeakHourSpreadAdjustment=ReturnedPeakHourSpreadAdjustment          , 
						@ReturnedSeizeBetTicket          =ReturnedSeizeBetTicket                    , 
						@ReturnedMinBet                  =ReturnedMinBet                            , 
						@ReturnedMaxBet                  =ReturnedMaxBet                            , 
						@ReturnedMaxPerMatch             =ReturnedMaxPerMatch                       , 
						@ReturnedAgentBetInterval        =ReturnedAgentBetInterval                  , 
						@ReturnedLeagueGroupID			 =ReturnedLeagueGroupID 
		FROM (
			SELECT
				MAX(cc.DiffBalanceRatio) AS ReturnedDiffBalanceRatio, 
				Max(cc.BetDelay) AS ReturnedBetDelay,
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
				MAX(LeagueGroupID) AS ReturnedLeagueGroupID,
				cc.TopPriority
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
									clg.LeagueGroupID,
									cc.TopPriority
								FROM CustomerClassRule_UAT cc WITH(NOLOCK) 
									INNER JOIN CustomerClassPolicyRule_UAT cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
									INNER JOIN CustomerClassPolicyManagement_UAT cpm WITH(NOLOCK) ON cp.RuleID = cc.RuleID 
									INNER JOIN CustomerClassRuleLeagueGroup_UAT clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
								WHERE cm.PolicyID = cpm.PolicyID
										AND cc.CustomerClass IN ( @CustomerClass, 0)
										AND ISNULL(cc.CustomerClassDetail,0) IN ( @SportsCC, 0)
										AND cc.SportType = @SportTypeSetting 
										AND clg.LeagueGroupID IN (@LeagueGroupID, -1)
										AND cpm.IsTest = @IsTest 
										AND cc.IsLive IN (2, @liveindicator)
										AND cc.Enable = 1 )cc
								
			WHERE cm.Site IN ('All', @SiteNew, @Site)
				AND cm.Currency IN (@Currency, 0)
				AND cm.Platform IN (0, @Platform)
				GROUP BY cc.TopPriority) KQ
		ORDER BY TopPriority DESC
		OPTION(OPTIMIZE FOR (@n =1), FORCE ORDER)
	 END
	 ELSE
	 BEGIN
		
		IF EXISTS (SELECT TOP 1 1 FROM CustomerClassPolicyManagement cc WITH (NOLOCK) WHERE SportType = @SportType)
		BEGIN
			SET @SportTypeSetting = @SportType
		END
		ELSE IF @SportType <= 99 AND @SportType NOT IN (13, 52, 54, 55, 56)
		BEGIN
			SET @SportTypeSetting = 99
		END

			
		SELECT TOP 1	@ReturnedCustomerClass           =CASE WHEN ReturnedLeagueGroupID IS NOT NULL THEN @CustomerClass ELSE NULL END                     , 
						@ReturnedSportsCC                =CASE WHEN ReturnedLeagueGroupID IS NOT NULL THEN @SportsCC ELSE NULL END                          , 
						@ReturnedDiffBalanceRatio        =ReturnedDiffBalanceRatio					, 
						@ReturnedBetDelay                =ReturnedBetDelay							, 
						@ReturnedNextBetInterval         =ReturnedNextBetInterval                   , 
						@ReturnedSuperBetInterval        =ReturnedSuperBetInterval                  ,
						@ReturnedSiteBetInterval         =ReturnedSiteBetInterval                   , 
						@ReturnedRepeatedBets            =ReturnedRepeatedBets                      , 
						@ReturnedDisableParlay           =ReturnedDisableParlay                     , 
						@ReturnedPeakHourSpreadAdjustment=ReturnedPeakHourSpreadAdjustment          , 
						@ReturnedSeizeBetTicket          =ReturnedSeizeBetTicket                    , 
						@ReturnedMinBet                  =ReturnedMinBet                            , 
						@ReturnedMaxBet                  =ReturnedMaxBet                            , 
						@ReturnedMaxPerMatch             =ReturnedMaxPerMatch                       , 
						@ReturnedAgentBetInterval        =ReturnedAgentBetInterval                  , 
						@ReturnedLeagueGroupID			 =ReturnedLeagueGroupID 
		FROM (
			SELECT
				MAX(cc.DiffBalanceRatio) AS ReturnedDiffBalanceRatio, 
				Max(cc.BetDelay) AS ReturnedBetDelay,
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
				MAX(LeagueGroupID) AS ReturnedLeagueGroupID,
				cc.TopPriority
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
									clg.LeagueGroupID,
									cc.TopPriority
								FROM CustomerClassRule cc WITH(NOLOCK) 
									INNER JOIN CustomerClassPolicyRule cp WITH(NOLOCK) ON cm.PolicyID = cp.PolicyID 
									INNER JOIN CustomerClassPolicyManagement cpm WITH(NOLOCK) ON cp.RuleID = cc.RuleID 
									INNER JOIN CustomerClassRuleLeagueGroup clg WITH(NOLOCK) ON clg.RuleID = cc.RuleID AND cc.IsTest = cpm.IsTest
								WHERE cm.PolicyID = cpm.PolicyID
										AND cc.CustomerClass IN ( @CustomerClass, 0)
										AND ISNULL(cc.CustomerClassDetail,0) IN ( @SportsCC, 0)
										AND cc.SportType = @SportTypeSetting 
										AND clg.LeagueGroupID IN (@LeagueGroupID, -1)
										AND cpm.IsTest = @IsTest 
										AND cc.IsLive IN (2, @liveindicator)
										AND cc.Enable = 1 )cc
								
			WHERE cm.Site IN ('All', @SiteNew, @Site)
				AND cm.Currency IN (@Currency, 0)
				AND cm.Platform IN (0, @Platform) 
			GROUP BY cc.TopPriority) KQ
		ORDER BY TopPriority DESC
		OPTION(OPTIMIZE FOR (@n =1), FORCE ORDER)
	END

	SELECT @ReturnedCustomerClass              AS ReturnedCustomerClass            , 
		   @ReturnedSportsCC                   AS ReturnedSportsCC                 , 
		   @site							   AS ReturnedSite					   ,
		   @Currency						   AS ReturnedCurrency                 , 
		   @Platform						   AS ReturnedPlatform                 , 
		   @SportType						   AS ReturnedSportType                , 
		   ISNULL(@ReturnedDiffBalanceRatio,1) AS ReturnedDiffBalanceRatio         , 
		   ISNULL(@ReturnedBetDelay,1)         AS ReturnedBetDelay                 , 
		   @ReturnedNextBetInterval            AS ReturnedNextBetInterval          , 
		   @ReturnedSuperBetInterval           AS ReturnedSuperBetInterval         ,
		   @ReturnedSiteBetInterval            AS ReturnedSiteBetInterval          , 
		   @ReturnedRepeatedBets               AS ReturnedRepeatedBets             , 
		   @ReturnedDisableParlay              AS ReturnedDisableParlay            , 
		   @ReturnedPeakHourSpreadAdjustment   AS ReturnedPeakHourSpreadAdjustment , 
		   @ReturnedSeizeBetTicket             AS ReturnedSeizeBetTicket           , 
		   @ReturnedMinBet                     AS ReturnedMinBet                   , 
		   @ReturnedMaxBet                     AS ReturnedMaxBet                   , 
		   @ReturnedMaxPerMatch                AS ReturnedMaxPerMatch              , 
		   @ReturnedAgentBetInterval           AS ReturnedAgentBetInterval         , 
		   @ReturnedLeagueGroupID			   AS ReturnedLeagueGroupID 
END