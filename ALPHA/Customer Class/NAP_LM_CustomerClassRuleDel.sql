/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassRuleDel] 
	  @RuleIDs		VARCHAR(MAX)
	, @UserID		INT
	, @IsTest		TINYINT	
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20231101
	Task : [NAP CM] Support to delete settings [#188590]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231101@Winfred: [NAP CM] Customer Class - Support to delete settings [RedmineID: #188590] 

	Param's Explanation:
	* @RuleIDs: List ID Rule

	Example: NAP_LM_CustomerClassRuleDel @@RuleIDs = '1,2,3,4,5,6,9,7,8,11' , @ErrCode = 0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML
	CREATE TABLE #RuleTemp( RuleID INT) 
	INSERT INTO #RuleTemp(RuleID)
	SELECT VALUE AS RuleID FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE <> ''
	SELECT @StartRun = GETDATE()

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK) 
					CROSS APPLY ( SELECT  TOP 1 RuleID FROM #RuleTemp WHERE RuleID = a.RuleID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	
	
	CREATE TABLE #CustomerClassRule_History( RuleID INT PRIMARY KEY, CustomerClass SMALLINT, RuleTitle VARCHAR(500),
			SportType SMALLINT, IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2),
			NextBetInterval SMALLINT, SuperBetInterval SMALLINT, SiteBetInterval SMALLINT,
			MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT,
			DisableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, 
			LeagueGroupIDs VARCHAR(MAX),Policies VARCHAR(MAX), Enable BIT, IsTest TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME)

	INSERT INTO #CustomerClassRule_History( RuleID, CustomerClass, RuleTitle, SportType, IsLive, DiffBalanceRatio, BetDelay, NextBetInterval, SuperBetInterval, SiteBetInterval, 
				MinBet, MaxBet, MaxPerMatch, RepeatedBets, SeizeBetTicket, DisableParlay, PeakHourSpreadAdjustment, AgentBetInterval, LeagueGroupIDs, Policies, Enable, IsTest, LastModifiedUser, LastModifiedTime)
	SELECT a.RuleID,
			a.CustomerClass,
			a.RuleTitle,
			a.SportType,
			a.IsLive,
			a.DiffBalanceRatio,
			a.BetDelay,
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
			b.LeagueGroupIDs,
			p.Policies,
			a.Enable,
			a.IsTest,
			a.LastModifiedUser,
			a.LastModifiedTime  
	FROM CustomerClassRule a WITH(NOLOCK)
		OUTER APPLY(
				SELECT STRING_AGG(CAST(LeagueGroupID AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY LeagueGroupID)  AS LeagueGroupIDs
				FROM CustomerClassRuleLeagueGroup b WITH(NOLOCK)
					WHERE a.RuleID = b.RuleID
			) b (LeagueGroupIDs)
		OUTER APPLY(
				SELECT STRING_AGG(CAST(PolicyID AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY PolicyID)  AS Policies
				FROM CustomerClassPolicyRule b WITH(NOLOCK)
					WHERE a.RuleID = b.RuleID
			) p (Policies)
		CROSS APPLY ( SELECT TOP 1 RuleID FROM #RuleTemp WHERE RuleID = a.RuleID ) c
	WHERE a.IsTest <= @IsTest
	
	DELETE a FROM CustomerClassRule a WITH (ROWLOCK)
		INNER JOIN #RuleTemp b ON a.RuleID = b.RuleID

	DELETE a FROM CustomerClassRuleLeagueGroup a WITH (ROWLOCK)
		INNER JOIN #RuleTemp b ON a.RuleID = b.RuleID

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT cs.RuleID					AS '@RuleID',
							cs.CustomerClass					AS '@CustomerClass',
							cs.RuleTitle						AS '@RuleTitle',
							cs.SportType						AS '@SportType',
							cs.IsLive							AS '@isLive',
							cs.DiffBalanceRatio					AS '@DiffBalanceRatio',
							cs.NextBetInterval					AS '@NextBetInterval',
							cs.SuperBetInterval					AS '@SuperBetInterval',
							cs.SiteBetInterval					AS '@SiteBetInterval',
							cs.MinBet							AS '@MinBet',
							cs.MaxBet							AS '@MaxBet',
							cs.MaxPerMatch						AS '@MaxPerMatch',
							cs.RepeatedBets						AS '@RepeatedBets',
							cs.SeizeBetTicket					AS '@SeizeBetTicket',
							cs.DisableParlay					AS '@DisableParlay',
							cs.PeakHourSpreadAdjustment			AS '@PeakHourSpreadAdjustment',
							cs.AgentBetInterval					AS '@AgentBetInterval',
							cs.LeagueGroupIDs					AS '@LeagueGroupIDs',
							cs.Policies							AS '@Policies',
							cs.IsTest							AS '@IsTest',
							cs.LastModifiedUser		AS '@LastModifiedUser',
							CONVERT(VARCHAR(10), cs.LastModifiedTime, 120) AS '@LastModifiedTime',	
							cs.Enable							AS '@Enable'
						FROM	#CustomerClassRule_History AS cs	
						ORDER BY cs.RuleID
						FOR XML PATH('ClassRule'),
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31915,
				@TrackingValue = '',
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassRule_History
	DROP TABLE #RuleTemp
END
GO
