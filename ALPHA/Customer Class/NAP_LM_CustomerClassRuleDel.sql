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
		, @iDoc			INT
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK) 
					CROSS APPLY ( SELECT  TOP 1 VALUE FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE = a.RuleID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	EXEC NAP_LM_CustomerClassRuleCheck @RuleIDs = @RuleIDs, @IsTest = @IsTest, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
	BEGIN
		RETURN 	
	END

	CREATE TABLE #CustomerClassRule_History( RuleID INT, CustomerClass SMALLINT, RuleTitle VARCHAR(500),
			SportType SMALLINT, IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2),
			NextBetInterval SMALLINT, SuperBetInterval SMALLINT, SiteBetInterval SMALLINT,
			MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT,
			DisableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, LeagueGroupIDs VARCHAR(MAX), IsTest TINYINT)



	-- Log new updated data
	SET @xml = (
			SELECT	@RuleID						AS '@RuleID',	
					@UserID						AS '@UserID',
					@IP							AS '@IP',
					@Enable						AS '@Enable',
					@IsTest						AS '@IsTest',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31906,
				@TrackingValue = '',
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassRule_History
END
GO
