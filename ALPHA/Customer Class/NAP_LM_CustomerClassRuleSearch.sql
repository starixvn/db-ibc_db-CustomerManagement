/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassRuleSearch] 
	@CustomerClass SMALLINT
	,@SportTypes VARCHAR(2000)
	,@LeagueGroup VARCHAR(MAX)
	,@LeagueGroups VARCHAR(MAX)
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
		- 20230802@Winfred: [NAP CM] Customer Class - Enhance for CC [RedmineID: #187368] 
		- 20231101@Winfred: [NAP CM] Customer Class - Support to delete settings [RedmineID: #188590] 
		- 20240122@Winfred: NAPCM - Support for Saba [RedmineID: #193809] 
		- 20240314@Winfred: [NAP CM] Customer Class - Grant permission for each Sport type [RedmineID: #199465] 

	Param's Explanation:
	Example: NAP_LM_CustomerClassRuleSearch @CustomerClass = 200 , @SportType = 2,  @LeagueGroup = '1,2,4,5,6', @Islive = 1	
	* @LeagueGroup : 0 All
*/ 
BEGIN
	SET NOCOUNT ON;

	DECLARE @iDoc INT, @xml XML
	CREATE TABLE #LeagueGroup( GroupID SMALLINT, GroupName VARCHAR(200), SportType SMALLINT)   
	--Check if XML is null or empty
	IF @LeagueGroups IS NULL OR @LeagueGroups = ''
		RETURN
	
	EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT, @LeagueGroups;
	INSERT INTO #LeagueGroup(GroupID, GroupName, SportType)
	SELECT	CAST(Data.GroupID AS SMALLINT) AS GroupID				
		,	CASE WHEN Data.GroupName = '' THEN null ELSE CAST(Data.GroupName AS VARCHAR(200)) END 
			AS GroupName 					    
		,	 CAST(Data.SportType AS SMALLINT)  AS SportType 
	FROM OPENXML(@iDoc, '/ROOT/r', 1) 
	WITH (     
			GroupID 	 SMALLINT,       
			GroupName 	 VARCHAR(500),       
			SportType 	 VARCHAR(20)
	) AS Data;
	EXECUTE	sp_xml_removedocument @iDoc;
  
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
			   a.DisableParlay,
			   a.PeakHourSpreadAdjustment,
			   a.AgentBetInterval,
			   a.Enable,
			   a.LastModifiedUser,
			   a.LastModifiedTime,
			   c.LeagueGroupNames,
			   d.PolicyTitles
		FROM CustomerClassRule a WITH(NOLOCK)
			CROSS APPLY(
						SELECT STRING_AGG(CAST((CASE WHEN b.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
							FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
								LEFT JOIN #LeagueGroup ps ON b.LeagueGroupID = ps.GroupID 
							WHERE a.RuleID = b.RuleID
					) c
			OUTER APPLY(
						SELECT STRING_AGG(CAST(PolicyTitle AS VARCHAR(MAX)), ', ') WITHIN GROUP (ORDER BY PolicyTitle)  AS PolicyTitles
							FROM CustomerClassPolicyRule r WITH(NOLOCK)
									CROSS APPLY ( SELECT TOP 1 PolicyTitle FROM CustomerClassPolicyManagement WHERE PolicyID = r.PolicyID ) b
							WHERE r.RuleID = a.RuleID
					) d
		WHERE a.SportType IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@SportTypes ,',') WHERE VALUE <> '')
			AND @CustomerClass IN (0, a.CustomerClass) 
			AND (@Islive = 2 OR a.IsLive = @Islive)
			AND a.IsTest <= @IsTest
			AND a.RuleID IN (SELECT RuleID 
							 FROM CustomerClassRuleLeagueGroup WITH(NOLOCK)
							 WHERE (@LeagueGroup = '' OR LeagueGroupID = -1 OR LeagueGroupID  IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@LeagueGroup,',') WHERE VALUE <> '')))

	DROP TABLE #LeagueGroup
END
GO
