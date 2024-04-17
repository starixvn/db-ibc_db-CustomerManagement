/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyUpd]
	@PolicyID		  INT
	, @PolicyTitle 	VARCHAR(500)
	, @SportType	SMALLINT
	, @RuleIDs		VARCHAR(MAX)= ''
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
	* @Policys:
		'<ROOT><r 
				PolicyID=1 
				PolicyTitle="200"
				RuleIDs="111,222,333,444,555"/> 
			   <r 
				PolicyID=2 
				PolicyTitle="300"
				RuleIDs="123,234,345,456,567"/>
		</ROOT>'

	Example: NAP_LM_CustomerClassPolicyUpd @Policys ='<ROOT><r PolicyID=1 PolicyTitle="200" RuleIDs="111,222,333,444,555"/> <r PolicyID=2 PolicyTitle="300" RuleIDs="123,234,345,456,567"/> </ROOT>' , @SportType = 1 ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @logSpData_Old  NVARCHAR(MAX)
		, @xml			  XML
		, @PolicyTitle_old 	VARCHAR(500)
		, @RuleTitleErr	    VARCHAR(500)	
		, @RuleIDs_old		VARCHAR(MAX)
		, @LastModifiedTime DATETIME
	
	SELECT @StartRun = GETDATE() , @LastModifiedTime = GETDATE()
	CREATE TABLE #CustomerClassRule( RuleID INT)
	CREATE TABLE #CustomerClassPolicyManagement_History(PolicyID INT, PolicyTitle VARCHAR(500), SportType SMALLINT, RuleIDs VARCHAR(MAX),
			LastModifiedUser INT, LastModifiedTime DATETIME)
	CREATE TABLE #CustomerClassPolicyRule_History( PolicyID INT, RuleID INT)

	IF ISNULL(@RuleIDs,'') <> ''
	BEGIN
		INSERT INTO #CustomerClassRule( RuleID)
		SELECT VALUE AS RuleID 
		FROM STRING_SPLIT(@RuleIDs,',') WHERE VALUE <> ''
	END

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					WHERE a.PolicyTitle = @PolicyTitle AND a.PolicyID <> @PolicyID)
	BEGIN
		SELECT @ErrCode = 104 , @ErrMsg = 'The Policy Title is existed' 
		RETURN
	END	 	

	IF 	ISNULL(@SportType,0) = 0
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'The sporttype is not existed' 
		RETURN
	END	 	
	
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK)
					WHERE PolicyID = @PolicyID AND a.IsTest <> @IsTest)
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	
	
	UPDATE a	
	SET a.PolicyTitle 		= @PolicyTitle 
		,a.LastModifiedUser = @UserID
		,a.LastModifiedTime = @LastModifiedTime
		,a.SportType	= @SportType
	OUTPUT	deleted.PolicyTitle 				
		,	deleted.LastModifiedUser 					    
		,	deleted.LastModifiedTime 
		,	deleted.SportType
	INTO #CustomerClassPolicyManagement_History(PolicyTitle 				
			 ,	LastModifiedUser 					    
			 ,	LastModifiedTime 
			 ,	SportType)
	FROM CustomerClassPolicyManagement a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID
	
	DELETE FROM CustomerClassPolicyRule WITH (ROWLOCK)
	OUTPUT	deleted.PolicyID,	deleted.RuleID 
	INTO #CustomerClassPolicyRule_History(PolicyID, RuleID )
	WHERE PolicyID = @PolicyID

	INSERT INTO CustomerClassPolicyRule(PolicyID ,  RuleID)	
	SELECT @PolicyID ,RuleID 
	FROM #CustomerClassRule

	SELECT @RuleIDs_old = (SELECT STRING_AGG(CAST(RuleID AS VARCHAR(20)), ',') 
						WITHIN GROUP (ORDER BY RuleID)
						FROM #CustomerClassPolicyRule_History  WITH(NOLOCK))
	
	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',
					@IsTest					AS '@IsTest',
					@PolicyID				AS '@PolicyID',
					PolicyTitle				AS '@PolicyTitle',
					SportType				AS '@SportType',
					LastModifiedUser		AS '@LastModifiedUser',
					CONVERT(VARCHAR(10), LastModifiedTime, 120) AS '@LastModifiedTime',
					RuleIDs					AS '@RuleIDs' ,
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FROM	#CustomerClassPolicyManagement_History AS cs	
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',	
					@IsTest					AS '@IsTest',
					@PolicyID				AS '@PolicyID',
					@PolicyTitle			AS '@PolicyTitle',
					@SportType				AS '@SportType',
					CONVERT(VARCHAR(10), @LastModifiedTime, 120) AS '@LastModifiedUser',
					@UserID					AS '@LastModifiedTime',
					@RuleIDs				AS '@RuleIDs' ,		
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
				@ActionID = 31904,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration
END
GO
