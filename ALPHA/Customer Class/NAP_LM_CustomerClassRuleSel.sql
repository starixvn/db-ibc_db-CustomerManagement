/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassRuleSel] 
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
		- 20230613@Luke: Option to apply Seize Bet if reach risk balance

	Param's Explanation:
	Example: NAP_LM_CustomerClassRuleSel @RuleID = 1	
*/ 
BEGIN
	SET NOCOUNT ON;
	SELECT a.RuleID,
			   a.CustomerClass,
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
			   CASE WHEN ISNULL(a.SeizeBetAccumulateBal,0) = 0 THEN 0 ELSE 1 END AS SeizeBetAccumulateBal,
			   a.EnableParlay,
			   a.PeakHourSpreadAdjustment,
			   a.AgentBetInterval,
			   b.LeagueGroupIDs 
		FROM CustomerClassRule a WITH(NOLOCK)
		OUTER APPLY(
				SELECT STRING_AGG(CAST(LeagueGroupID AS VARCHAR(20)), ',') WITHIN GROUP (ORDER BY LeagueGroupID)  AS LeagueGroupIDs
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					WHERE a.RuleID = b.RuleID
			) b (LeagueGroupIDs)
		WHERE a.RuleID = @RuleID AND a.IsTest <= @IsTest

END
GO
