/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyIns]
	@PolicyTitle 	VARCHAR(500)
	, @SportType	SMALLINT
	, @RuleIDs		VARCHAR(MAX) = ''
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
	* @PolicyID=1 
	  @PolicyTitle="200"
	  @RuleIDs="111,222,333,444,555"

	Example: NAP_LM_CustomerClassPolicyIns @PolicyID=1 , @PolicyTitle="200" , @RuleIDs="111,222,333,444,555" ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @RuleTitleErr	  VARCHAR(500)	
		, @PolicyID		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @xml			  XML
	CREATE TABLE #CustomerClassRule( RuleID INT)
	
	IF ISNULL(@RuleIDs,'') <> ''
	BEGIN
		INSERT INTO #CustomerClassRule( RuleID)
		SELECT VALUE AS RuleID 
		FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE <> ''
	END

	SELECT @StartRun = GETDATE()
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					WHERE a.PolicyTitle = @PolicyTitle )
	BEGIN
		SELECT @ErrCode = 104 , @ErrMsg = 'The Policy Title is existed' 
		RETURN
	END	 

	IF 	ISNULL(@SportType,0) = 0
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'The sporttype is not existed' 
		RETURN
	END	 	

	INSERT INTO CustomerClassPolicyManagement(
			PolicyTitle 
		,  SportType
		,  IsTest
		,  LastModifiedUser
		,  LastModifiedTime)	
	SELECT @PolicyTitle, @SportType, @IsTest, @UserID, GETDATE()
		
	SET @PolicyID = SCOPE_IDENTITY()

	INSERT INTO CustomerClassPolicyRule(PolicyID ,  RuleID)	
	SELECT @PolicyID ,RuleID 
	FROM #CustomerClassRule
	
	-- Log new updated data
	SET @xml = (
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',
					@PolicyID					AS '@PolicyID',
					CAST(@SportType AS 	VARCHAR(20)) AS '@SportType',
					@IsTest						AS '@IsTest',
					@PolicyTitle				AS '@PolicyTitle',
					@RuleIDs					AS '@RuleIDs',
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
				@ActionID = 31903,
				@TrackingValue = @LogSPData,
				@duration = @Duration
END
GO
