/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassRuleSearch] 
	@CustomerClass SMALLINT
	,@SportType SMALLINT
	,@LeagueGroup VARCHAR(MAX)
	,@Islive TINYINT = 0 
	,@IsTest TINYINT
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
	Example: NAP_LM_CustomerClassRuleSearch @CustomerClass = 200 , @SportType = 2,  @LeagueGroup = '1,2,4,5,6', @Islive = 1	
	* @LeagueGroup : 0 All
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
			   a.Enable,
			   a.LastModifiedUser,
			   a.LastModifiedTime ,c.LeagueGroupNames
		FROM CustomerClassRule a WITH(NOLOCK)
			CROSS APPLY(
						SELECT STRING_AGG(CAST((CASE WHEN b.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
							FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
								LEFT JOIN DBACC.BODB02.DBO.LeagueGroup ps  WITH(NOLOCK) ON b.LeagueGroupID = ps.GroupID 
							WHERE a.RuleID = b.RuleID
					) c
		WHERE a.SportType = @SportType AND (@Islive = 2 OR a.IsLive = @Islive)
			AND (@CustomerClass = 0 OR a.CustomerClass = @CustomerClass)
			AND a.IsTest <= @IsTest
			AND a.RuleID IN (SELECT RuleID 
							 FROM CustomerClassRuleLeagueGroup 
							 WHERE (@LeagueGroup = '' OR LeagueGroupID = -1 OR LeagueGroupID  IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@LeagueGroup,',') WHERE VALUE <> '')))

END
GO
