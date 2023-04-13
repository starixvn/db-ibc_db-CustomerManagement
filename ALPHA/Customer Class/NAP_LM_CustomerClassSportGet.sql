/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSportGet] 
	@SportType SMALLINT,
	@IsTest	TINYINT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 

	Param's Explanation:
	Example: NAP_LM_CustomerClassSportGet @SportType = 1, @IsTest = 1	
*/ 
BEGIN
	SET NOCOUNT ON;

	SELECT a.RuleID,
			a.CustomerClass,
			a.RuleTitle,
			a.SportType,
			a.isLive,
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
			a.EnableParlay,
			a.PeakHourSpreadAdjustment,
			a.Enable,
			a.LastModifiedUser,
			a.LastModifiedTime, c.LeagueGroupNames 
	FROM CustomerClassRule a WITH(NOLOCK)
		CROSS APPLY(
			SELECT STRING_AGG(CAST((CASE WHEN b.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					LEFT JOIN DBACC.BODB02.DBO.LeagueGroup ps  WITH(NOLOCK) ON b.LeagueGroupID = ps.GroupID 
				WHERE a.RuleID = b.RuleID
		) c
	WHERE (a.SportType = @SportType OR a.SportType = 0) AND a.IsTest <= @IsTest
END
GO
