/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassSportGet] 
	@SportType SMALLINT,
	@LeagueGroups VARCHAR(MAX),
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
		- 20230802@Winfred: [NAP CM] Customer Class - Enhance for CC [RedmineID: #187368]
		- 20240122@Winfred: NAPCM - Support for Saba [RedmineID: #193809]  

	Param's Explanation:
	Example: NAP_LM_CustomerClassSportGet @SportType = 1, @IsTest = 1	
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
			a.DisableParlay,
			a.PeakHourSpreadAdjustment,
			a.Enable,
			a.LastModifiedUser,
			a.LastModifiedTime, c.LeagueGroupNames 
	FROM CustomerClassRule a WITH(NOLOCK)
		CROSS APPLY(
			SELECT STRING_AGG(CAST((CASE WHEN b.LeagueGroupID = -1 THEN 'All' ELSE ps.GroupName END) AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY GroupName)  AS LeagueGroupNames
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					LEFT JOIN #LeagueGroup ps ON b.LeagueGroupID = ps.GroupID 
				WHERE a.RuleID = b.RuleID
		) c
	WHERE (a.SportType = @SportType OR a.SportType = 0) AND a.IsTest <= @IsTest

	DROP TABLE #LeagueGroup
END
GO
