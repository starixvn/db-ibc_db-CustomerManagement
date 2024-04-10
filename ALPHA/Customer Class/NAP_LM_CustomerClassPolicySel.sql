/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySel]
	@IsTest	TINYINT,
	@PolicyID		INT = 0,
	@LeagueGroups VARCHAR(MAX),
	@PolicyTitle	VARCHAR(500) = '',
	@SportTypes VARCHAR(2000)
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
		- 20231118@Winfred: [NAP CM] Allow to choose overwriting policy or creating new assign setting [RedmineID: #196932] 
		- 20240122@Winfred: NAPCM - Support for Saba [RedmineID: #193809] 
		- 20240314@Winfred: [NAP CM] Customer Class - Grant permission for each Sport type [RedmineID: #199465] 

	Param's Explanation:
	Example: NAP_LM_CustomerClassPolicySel @IsTest = 1,	@PolicyID = 0
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

	IF @PolicyID = 0 
	BEGIN
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
			c.DisableParlay,
			c.PeakHourSpreadAdjustment,
			c.IsTest,
			c.LastModifiedUser,
			c.LastModifiedTime,
			d.LeagueGroupNames 
		FROM CustomerClassPolicyManagement a WITH(NOLOCK)
			LEFT JOIN CustomerClassPolicyRule b WITH(NOLOCK) ON a.PolicyID = b.PolicyID
			OUTER APPLY( SELECT TOP 1 RuleID
									,CustomerClass
									,RuleTitle
									,SportType
									,IsLive
									,DiffBalanceRatio
									,BetDelay
									,NextBetInterval
									,SuperBetInterval
									,SiteBetInterval
									,MinBet
									,MaxBet
									,MaxPerMatch
									,RepeatedBets
									,SeizeBetTicket
									,EnableParlay
									,PeakHourSpreadAdjustment
									,AgentBetInterval
									,Enable
									,IsTest
									,LastModifiedUser
									,LastModifiedTime
									,DisableParlay	
					FROM CustomerClassRule WITH(NOLOCK) WHERE RuleID = b.RuleID) c
			CROSS APPLY(
				SELECT STRING_AGG(CAST((CASE WHEN lg.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
					FROM CustomerClassRuleLeagueGroup lg WITH(NOLOCK)
						LEFT JOIN #LeagueGroup ps ON lg.LeagueGroupID = ps.GroupID 
					WHERE lg.RuleID = b.RuleID
			) d
		WHERE  a.SportType IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@SportTypes ,',') WHERE VALUE <> '')
		  AND a.IsTest <= @IsTest AND a.PolicyTitle like '%' + @PolicyTitle + '%' 
	END
	ELSE
	BEGIN

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
			c.DisableParlay,
			c.PeakHourSpreadAdjustment,
			c.IsTest,
			c.LastModifiedUser,
			c.LastModifiedTime,
			d.LeagueGroupNames 
		FROM CustomerClassPolicyManagement a WITH(NOLOCK)
			LEFT JOIN CustomerClassPolicyRule b WITH(NOLOCK) ON a.PolicyID = b.PolicyID
			OUTER APPLY( SELECT TOP 1 RuleID
									,CustomerClass
									,RuleTitle
									,SportType
									,IsLive
									,DiffBalanceRatio
									,BetDelay
									,NextBetInterval
									,SuperBetInterval
									,SiteBetInterval
									,MinBet
									,MaxBet
									,MaxPerMatch
									,RepeatedBets
									,SeizeBetTicket
									,EnableParlay
									,PeakHourSpreadAdjustment
									,AgentBetInterval
									,Enable
									,IsTest
									,LastModifiedUser
									,LastModifiedTime
									,DisableParlay	
					FROM CustomerClassRule WITH(NOLOCK) WHERE RuleID = b.RuleID) c
			CROSS APPLY(
				SELECT STRING_AGG(CAST((CASE WHEN lg.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
					FROM CustomerClassRuleLeagueGroup lg WITH(NOLOCK)
						LEFT JOIN #LeagueGroup ps ON lg.LeagueGroupID = ps.GroupID 
					WHERE lg.RuleID = b.RuleID
			) d
		WHERE a.SportType IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@SportTypes ,',') WHERE VALUE <> '') AND a.IsTest <= @IsTest AND a.PolicyID = @PolicyID

	END
	
	DROP TABLE #LeagueGroup
END
GO
