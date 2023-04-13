/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassRuleEnable] 
	  @RuleID INT
	, @Enable BIT
	, @UserID		INT
	, @IsTest		TINYINT	
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
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
	* @RuleID: ID Rule

	Example: NAP_LM_CustomerClassRuleEnable @RuleID = 11 , @Enable = 1 ,@ErrCode = 0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @iDoc			INT
		, @logSpData		 NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML
  
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND RuleID = @RuleID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	

	UPDATE a	
	SET a.Enable 				=   @Enable 
	FROM CustomerClassRule a WITH (ROWLOCK, UPDLOCK)
	WHERE a.RuleID = @RuleID
	

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
	SET @xml = (
			SELECT	@RuleID						AS '@RuleID',	
					@UserID						AS '@UserID',
					@IP							AS '@IP',
					CASE WHEN @Enable = 1 
						THEN 0 ELSE 1 END		AS '@Enable',
					@IsTest						AS '@IsTest',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31906,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

END
GO
