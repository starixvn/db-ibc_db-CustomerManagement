/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_CustomerClassRuleSel] 
	@RuleID INT, 
	@IsTest TINYINT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20230802@Winfred: [NAP CM] Customer Class - Enhance for CC [RedmineID: #187368] 
		- 20240402@Winfred: [NAP CM] Customer Class - Support to add CC by Sport Detail [199679]
		- 20240925@Winfred: [NAP CM] Customer Class - Allow licensees to bypass any restrict rules [188589]

	Param's Explanation:
	Example: NAP_CM_CustomerClassRuleSel @RuleID = 1	
*/ 
BEGIN
	SET NOCOUNT ON;
	SELECT a.RuleID,
			   a.CustomerClass,
			   a.CustomerClassDetail,
			   a.RuleTitle,
			   a.SportType,
			   a.IsLive,
			   (a.DiffBalanceRatio - 1) * 100 AS DiffBalanceRatio,
			   (a.BetDelay - 1) * 100 AS BetDelay,
			   a.NextBetInterval,
			   a.SuperBetInterval,
			   a.SiteBetInterval,
			   a.MinBet,
			   a.MaxBet,
			   a.MaxPerMatch,
			   a.RepeatedBets,
			   a.SeizeBetTicket,
			   a.DisableParlay,
			   a.PeakHourSpreadAdjustment,
			   a.AgentBetInterval,
			   b.LeagueGroupIDs ,
			   a.TopPriority ,
			   a.Enable
		FROM CustomerClassRule a WITH(NOLOCK)
		OUTER APPLY(
				SELECT STRING_AGG(CAST(LeagueGroupID AS VARCHAR(20)), ',') WITHIN GROUP (ORDER BY LeagueGroupID)  AS LeagueGroupIDs
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					WHERE a.RuleID = b.RuleID
			) b (LeagueGroupIDs)
		WHERE a.RuleID = @RuleID AND a.IsTest <= @IsTest
		ORDER BY a.CustomerClass, a.CustomerClassDetail

END
GO
