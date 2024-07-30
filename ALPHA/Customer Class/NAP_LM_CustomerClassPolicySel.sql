/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
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
		- 20240402@Winfred: [NAP CM] Customer Class - Support to add CC by Sport Detail [199679]

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
	SELECT	Data.GroupID AS GroupID				
		,	CASE WHEN Data.GroupName = '' THEN null ELSE Data.GroupName END 
			AS GroupName 					    
		,	Data.SportType AS SportType 
	FROM OPENXML(@iDoc, '/ROOT/r', 1) 
	WITH (     
			GroupID 	 SMALLINT,       
			GroupName 	 VARCHAR(500),       
			SportType 	 SMALLINT
	) AS Data;
	EXECUTE	sp_xml_removedocument @iDoc;

	IF @PolicyID = 0 
	BEGIN
		SELECT  c.PolicyID
				,d.PolicyTitle 
				,RuleID
				,Enable
				,CustomerClass
				,CustomerClassDetail
				,RuleTitle
				,SportType
				,IsLive
				,(DiffBalanceRatio - 1) * 100 AS DiffBalanceRatio
				,(BetDelay - 1) * 100 AS BetDelay
				,NextBetInterval
				,SuperBetInterval
				,SiteBetInterval
				,MinBet
				,MaxBet
				,MaxPerMatch
				,RepeatedBets
				,SeizeBetTicket
				,DisableParlay
				,PeakHourSpreadAdjustment
				,IsTest
				,LastModifiedUser
				,LastModifiedTime
				,b.LeagueGroupNames
		FROM CustomerClassRule a WITH(NOLOCK)
			CROSS APPLY(
				SELECT STRING_AGG(CAST((CASE WHEN lg.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
					FROM CustomerClassRuleLeagueGroup lg WITH(NOLOCK)
						LEFT JOIN #LeagueGroup ps ON lg.LeagueGroupID = ps.GroupID 
					WHERE lg.RuleID = a.RuleID
			) b
			CROSS APPLY(SELECT PolicyID FROM CustomerClassPolicyRule lg WITH(NOLOCK) WHERE lg.RuleID = a.RuleID ) c
			CROSS APPLY(SELECT TOP 1 PolicyTitle FROM CustomerClassPolicyManagement WITH(NOLOCK) WHERE PolicyID = c.PolicyID AND PolicyTitle like '%' + @PolicyTitle + '%' ) d
		WHERE  a.SportType IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@SportTypes ,',') WHERE VALUE <> '')
		  AND a.IsTest <= @IsTest


	END
	ELSE
	BEGIN
		SELECT  c.PolicyID
				,d.PolicyTitle 
				,RuleID
				,Enable
				,CustomerClass
				,CustomerClassDetail
				,RuleTitle
				,SportType
				,IsLive
				,(DiffBalanceRatio - 1) * 100 AS DiffBalanceRatio
				,(BetDelay - 1) * 100 AS BetDelay
				,NextBetInterval
				,SuperBetInterval
				,SiteBetInterval
				,MinBet
				,MaxBet
				,MaxPerMatch
				,RepeatedBets
				,SeizeBetTicket
				,DisableParlay
				,PeakHourSpreadAdjustment
				,IsTest
				,LastModifiedUser
				,LastModifiedTime
				,b.LeagueGroupNames
		FROM CustomerClassRule a WITH(NOLOCK)
			CROSS APPLY(
				SELECT STRING_AGG(CAST((CASE WHEN lg.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
					FROM CustomerClassRuleLeagueGroup lg WITH(NOLOCK)
						LEFT JOIN #LeagueGroup ps ON lg.LeagueGroupID = ps.GroupID 
					WHERE lg.RuleID = a.RuleID
			) b
			CROSS APPLY(SELECT PolicyID FROM CustomerClassPolicyRule lg WITH(NOLOCK) WHERE lg.RuleID = a.RuleID AND PolicyID = @PolicyID ) c
			CROSS APPLY(SELECT TOP 1 PolicyTitle FROM CustomerClassPolicyManagement WITH(NOLOCK) WHERE PolicyID = c.PolicyID AND PolicyTitle like '%' + @PolicyTitle + '%' ) d
		WHERE  a.SportType IN ( SELECT CAST(VALUE AS INT) FROM STRING_SPLIT(@SportTypes ,',') WHERE VALUE <> '')
		  AND a.IsTest <= @IsTest

	END
	
	DROP TABLE #LeagueGroup
END
GO
