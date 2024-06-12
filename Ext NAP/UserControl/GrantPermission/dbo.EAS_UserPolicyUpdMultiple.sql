/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserPolicyUpdMultiple]
    @FuncID             INT,
	@Policy				VARCHAR(MAX),
	@OldPolicy			VARCHAR(MAX) = '',
	@UserID				INT,
	@IP					VARCHAR(50),
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Kan
		Date: 2019-01-21
		Task: Grant permission to multiple users
		DB: DBPOL/NAP_UserControl
		
		Revisions:
            - 20190121@Kan: Grant permission to multiple users [Redmine Id: 106667]
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20240603@Tacy: Ext NAP - Grant permission of child functions and permission of parent functions [Redmine: #205415]
			
		Parameter's Explanation:
	*/
BEGIN
    SET NOCOUNT ON

	DECLARE @StartRun	DATETIME,
			@EndRun		DATETIME,
			@Duration	INT,
			@ParentID	INT
	
	SET @StartRun = GETDATE()
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @UserID, @FuncKey = 'GrantPermission', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN

	SELECT @ParentID=ISNULL(f.ParentID,0)
	FROM dbo.eaFunction f WITH (NOLOCK)
	WHERE f.FuncID=@FuncID	
	
	CREATE TABLE #UserPolicyTable(UserID INT, Policy TINYINT)
		
	INSERT INTO #UserPolicyTable(UserID, Policy)
	SELECT funcid, policy
	FROM dbo.f_EAS_PolicySplit(@Policy, ';', ',')

	--DELETE: Unchange policy
	DELETE t
	FROM #UserPolicyTable t
	INNER JOIN dbo.eaUserPolicy u WITH (NOLOCK)	
			ON t.UserID=u.UserID AND u.FuncID = @FuncID 
	WHERE t.Policy=u.Policy

	--UPDATE: permission of child functions
	UPDATE u WITH (ROWLOCK, UPDLOCK)
	SET u.Policy = t.Policy
	FROM dbo.eaUserPolicy u
        INNER JOIN #UserPolicyTable t ON u.userid = t.UserID
		INNER JOIN (SELECT @ParentID AS FuncID
					UNION ALL 
					SELECT @FuncID) f ON u.FuncID = f.FuncID

	INSERT INTO dbo.eaUserPolicy(UserID, FuncID, Policy)
    SELECT t.UserID, @ParentID, t.Policy 
    FROM #UserPolicyTable t
        LEFT JOIN dbo.eaUserPolicy u WITH(NOLOCK) ON u.FuncID = @ParentID AND u.UserID = t.UserID
    WHERE u.FuncID IS NULL AND @ParentID<>0
	UNION
	SELECT t.UserID, @FuncID, t.Policy 
    FROM #UserPolicyTable t
        LEFT JOIN dbo.eaUserPolicy u WITH(NOLOCK) ON u.FuncID = @FuncID AND u.UserID = t.UserID
    WHERE u.FuncID IS NULL	

	--UPDATE: permission of parent functions
	IF @ParentID<>0
	BEGIN
		;WITH cte_ChildPolicy AS (
			SELECT u.UserID, f.ParentID, MAX(u.Policy) Max_ChildPolicy
			FROM eaUserPolicy u WITH (NOLOCK)
			INNER JOIN eaFunction f WITH (NOLOCK) ON f.FuncID=u.FuncID
			INNER JOIN #UserPolicyTable t ON t.UserID=u.UserID
			WHERE f.ParentID=@ParentID
			GROUP BY u.UserID, f.ParentID
		)
		UPDATE u 
		SET u.Policy = t.Max_ChildPolicy
		FROM dbo.eaUserPolicy u WITH (ROWLOCK, UPDLOCK)
		INNER JOIN cte_ChildPolicy t ON t.UserID=u.UserID
									AND t.ParentID=u.FuncID
		WHERE u.Policy<>t.Max_ChildPolicy
	END
	

	/**************Write to Log table for each action********************/
	
	DECLARE @LogData NVARCHAR(MAX)
	
	SELECT @LogData =	'<EAS_UserPolicyUpdMultiple>'+
							'<ParentID>' + ISNULL(CONVERT(VARCHAR(20),@ParentID), '') + '</ParentID>' +
							'<FuncID>' + ISNULL(CONVERT(VARCHAR(20),@FuncID), '') + '</FuncID>' +
							'<IP>' + COALESCE(@IP, '') + '</IP>' +
							'<Permission>' +
								'<Old>' + ISNULL(@OldPolicy, '') + '</Old>' +
								'<New>' + ISNULL(@Policy, '') + '</New>' +
							'</Permission>' +
						'</EAS_UserPolicyUpdMultiple>'				

	SET @EndRun = GETDATE()  
	SET @Duration  = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper] 
		@custID = @FuncID, 
		@TrackingValue = @LogData, 
		@userid = @UserID, 
		@TypeID = 1, 
		@actionid = 20007, 
		@duration = @duration

	DROP TABLE #UserPolicyTable
END
GO