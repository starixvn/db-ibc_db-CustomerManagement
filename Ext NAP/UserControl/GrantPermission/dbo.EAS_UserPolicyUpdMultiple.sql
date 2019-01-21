/*<info serverAlias="DBEAS-bodb_EAS" executers="bodbExtAccNet" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserPolicyUpdMultiple]
    @FuncID             INT,
	@Policy				VARCHAR(MAX),
	@UserID				INT,
	@IP					VARCHAR(50),
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Kan
		Date: 2019-01-21
		Task: Grant permission to multiple users
		DB: DBEAS/bodb_EAS
		
		Revisions:
            - 20190121@Kan: Grant permission to multiple users [Redmine Id: 106667]
			
		Parameter's Explanation:
	*/
BEGIN
    SET NOCOUNT ON

	DECLARE @StartRun DATETIME,
        @EndRun DATETIME,
        @Duration INT		
	
	SET @StartRun = GETDATE()
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @UserID, @FuncKey = 'GrantPermission', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
		
	CREATE TABLE #UserPolicyTable(UserID INT, Policy TINYINT)
		
	INSERT INTO #UserPolicyTable(UserID, Policy)
	SELECT funcid, policy
	FROM dbo.f_EAS_PolicySplit(@Policy, ';', ',')
		
	UPDATE u WITH (ROWLOCK, UPDLOCK)
	SET u.Policy = t.Policy
	FROM dbo.eaUserPolicy u
        INNER JOIN #UserPolicyTable t ON u.FuncID = @FuncID AND u.userid = t.UserID
	
	INSERT INTO dbo.eaUserPolicy(UserID, FuncID, Policy)
    SELECT t.UserID, @FuncID, t.Policy 
    FROM #UserPolicyTable t
        LEFT JOIN dbo.eaUserPolicy u WITH(NOLOCK) ON u.FuncID = @FuncID AND u.UserID = t.UserID
    WHERE u.FuncID IS NULL		
	
	/**************Write to Log table for each action********************/
	
	DECLARE @LogData NVARCHAR(MAX)
	
	SELECT @LogData =	'<EAS_UserPolicyUpdMultiple>'+
							'<FuncID>' + ISNULL(CONVERT(VARCHAR(20),@FuncID), '') + '</FuncID>' +
							'<IP>' + COALESCE(@IP, '') + '</IP>' +
							'<UserPolicy>' + @Policy + '</GroupPolicy>' +
						'</EAS_UserPolicyUpdMultiple>'				

	SET @EndRun = GETDATE()  
	SET @Duration  = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC DBLOG.bodb_CustomerLog.[dbo].[EAS_WriteLog_UserLog_UserControl] 
		@custID = @FuncID, 
		@TrackingValue = @LogData, 
		@userid = @UserID, 
		@TypeID = 1, 
		@actionid = 20007, 
		@duration = @duration

	DROP TABLE #UserPolicyTable
END
GO