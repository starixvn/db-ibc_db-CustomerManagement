/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassPolicyDel] 
	  @Policies		VARCHAR(MAX)
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

	Example: NAP_LM_CustomerClassPolicyDel @Policies = '1,2,3,4,5,6,9,7,8,11' , @ErrCode = 0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML
	CREATE TABLE #PolicyTemp(PolicyID INT) 
	INSERT INTO #PolicyTemp(PolicyID)
	SELECT VALUE AS PolicyID FROM STRING_SPLIT(@Policies,',') WHERE VALUE <> ''
	SELECT @StartRun = GETDATE()

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassPolicyManagement a WITH(NOLOCK) 
					CROSS APPLY ( SELECT  TOP 1 PolicyID FROM #PolicyTemp WHERE PolicyID = a.PolicyID ) b
				WHERE a.IsTest <> @IsTest ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	EXEC NAP_LM_CustomerClassPolicyCheck @Policies = @Policies, @IsTest = @IsTest, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
	BEGIN
		RETURN 	
	END

	CREATE TABLE #CustomerClassPolicy_History( PolicyID INT PRIMARY KEY, PolicyTitle VARCHAR(500),RuleIDs VARCHAR(MAX),
			SportType SMALLINT, IsTest TINYINT,LastModifiedUser INT, LastModifiedTime DATETIME)

	INSERT INTO #CustomerClassPolicy_History( PolicyID, PolicyTitle, SportType, IsTest, RuleIDs, LastModifiedUser, LastModifiedTime)
	SELECT a.PolicyID, a.PolicyTitle, a.SportType, a.IsTest, b.RuleIDs, a.LastModifiedUser, a.LastModifiedTime  
	FROM CustomerClassPolicyManagement a WITH(NOLOCK)
		OUTER APPLY(
				SELECT STRING_AGG(CAST(RuleID AS VARCHAR(20)), ',') WITHIN GROUP (ORDER BY RuleID)  AS RuleIDs
				FROM CustomerClassPolicyRule b WITH(NOLOCK)
					WHERE a.PolicyID = b.PolicyID
			) b (RuleIDs)
		CROSS APPLY ( SELECT TOP 1 PolicyID FROM #PolicyTemp WHERE PolicyID = a.PolicyID ) c
	WHERE a.IsTest <= @IsTest
	
	DELETE a FROM CustomerClassPolicyManagement a WITH (ROWLOCK)
		INNER JOIN #PolicyTemp b ON a.PolicyID = b.PolicyID

	DELETE a FROM CustomerClassPolicyRule a WITH (ROWLOCK)
		INNER JOIN #PolicyTemp b ON a.PolicyID = b.PolicyID

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT cs.PolicyID		 AS '@PolicyID',
							cs.PolicyTitle				 AS '@PolicyTitle',
							cs.SportType				 AS '@SportType',
							cs.RuleIDs					 AS '@RuleIDs',
							cs.IsTest					 AS '@IsTest',
							cs.LastModifiedUser			 AS '@LastModifiedUser',
							CONVERT(VARCHAR(10), cs.LastModifiedTime, 120) AS '@LastModifiedTime'
						FROM	#CustomerClassPolicy_History AS cs	
						ORDER BY cs.PolicyID
						FOR XML PATH('CP'),
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
				@ActionID = 31916,
				@TrackingValue = '',
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #CustomerClassPolicy_History
	DROP TABLE #PolicyTemp
END
GO
