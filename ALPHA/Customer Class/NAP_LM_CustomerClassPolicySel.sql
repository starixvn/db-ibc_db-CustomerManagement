/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySel]
	@IsTest	TINYINT,
	@PolicyID	INT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20230613@Luke: Option to apply Seize Bet if reach risk balance [Redmine: #187771]

	Param's Explanation:
	Example: NAP_LM_CustomerClassPolicySel @IsTest = 1,	@PolicyID = 0
*/ 
BEGIN
	SET NOCOUNT ON; 

	SELECT  a.PolicyID, 
			a.PolicyTitle , 
			c.RuleID,
			c.Enable,
			c.CustomerClass,
			c.RuleTitle,
			a.SportType,
			c.IsLive ,
			(c.DiffBalanceRatio - 1) * 100 AS DiffBalanceRatio,
			(c.BetDelay - 1) * 100 AS BetDelay,
			c.NextBetInterval,
			c.SuperBetInterval,
			c.SiteBetInterval,
			c.MinBet,
			c.MaxBet,
			c.MaxPerMatch,
			c.RepeatedBets,
			c.SeizeBetTicket,
			CASE WHEN ISNULL(c.SeizeBetAccumulateBal,0) = 0 THEN 0 ELSE 1 END AS SeizeBetAccumulateBal,
			c.EnableParlay,
			c.PeakHourSpreadAdjustment,
			c.IsTest,
			c.LastModifiedUser,
			c.LastModifiedTime,
			d.LeagueGroupNames 
	FROM CustomerClassPolicyManagement a WITH(NOLOCK)
		LEFT JOIN CustomerClassPolicyRule b WITH(NOLOCK) ON a.PolicyID = b.PolicyID
		LEFT JOIN CustomerClassRule c WITH(NOLOCK) ON b.RuleID = c.RuleID --AND ( c.Enable IS NULL OR c.Enable = 1)
		CROSS APPLY(
			SELECT STRING_AGG(CAST((CASE WHEN lg.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
				FROM CustomerClassRuleLeagueGroup lg WITH(NOLOCK)
					LEFT JOIN DBACC.BODB02.DBO.LeagueGroup ps  WITH(NOLOCK) ON lg.LeagueGroupID = ps.GroupID 
				WHERE lg.RuleID = b.RuleID
		) d
	WHERE  a.IsTest <= @IsTest AND (@PolicyID = 0  OR a.PolicyID = @PolicyID)
END
GO
