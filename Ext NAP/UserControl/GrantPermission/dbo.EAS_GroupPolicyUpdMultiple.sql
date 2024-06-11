/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupPolicyUpdMultiple]
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
		Task: Grant permission to multiple groups
		DB: DBPOL/NAP_UserControl
		
		Revisions:
            - 20190121@Kan: Grant permission to multiple groups [Redmine Id: 106667]
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
		
	SELECT @ParentID=g.ParentID
	FROM dbo.eaFunction g WITH (NOLOCK)
	WHERE g.FuncID=@FuncID

	CREATE TABLE #GroupPolicyTable(GroupID INT, Policy TINYINT)
		
	INSERT INTO #GroupPolicyTable(GroupID, Policy)
	SELECT funcid, policy
	FROM dbo.f_EAS_PolicySplit(@Policy, ';', ',')
		
	--DELETE: Unchange policy
	DELETE t
	FROM #GroupPolicyTable t
	INNER JOIN dbo.eaGroupPolicy u WITH (NOLOCK)	
			ON t.GroupID=u.GroupID AND u.FuncID = @FuncID 
	WHERE t.Policy=u.Policy
	
	--revoke parent permission
	IF EXISTS (SELECT TOP 1 1 FROM #GroupPolicyTable WHERE Policy=0)
		AND @ParentID<>0
	BEGIN
		DECLARE @RevokeTable TABLE (GroupID INT)

		INSERT INTO @RevokeTable (GroupID)
		SELECT g.GroupID 
		FROM eaGroupPolicy g WITH (NOLOCK)
			INNER JOIN eaFunction f WITH (NOLOCK) ON f.FuncID=g.FuncID
			INNER JOIN #GroupPolicyTable t ON g.GroupID = t.GroupID AND t.Policy=0
		WHERE f.ParentID=@ParentID AND g.Policy<>0
		GROUP BY g.GroupID
		HAVING COUNT(1)=1

		UPDATE g WITH (ROWLOCK, UPDLOCK)
		SET g.Policy = CASE WHEN r.GroupID IS NULL AND f.IsParent=1 
								THEN g.Policy
								ELSE t.Policy
						END
		FROM dbo.eaGroupPolicy g
			INNER JOIN #GroupPolicyTable t ON g.GroupID = t.GroupID 
			INNER JOIN (SELECT @ParentID AS FuncID, 1 AS IsParent
						UNION ALL 
						SELECT @FuncID, 0) f ON g.FuncID = f.FuncID
			LEFT JOIN @RevokeTable r ON r.GroupID=g.GroupID
		WHERE t.Policy=0

		DELETE FROM #GroupPolicyTable WHERE Policy=0
	END

	UPDATE gp WITH (ROWLOCK, UPDLOCK)
	SET gp.Policy = t.Policy
	FROM dbo.eaGroupPolicy gp
        INNER JOIN #GroupPolicyTable t ON  gp.groupid = t.GroupID
		INNER JOIN (SELECT @ParentID AS FuncID
					UNION ALL 
					SELECT @FuncID) f ON gp.FuncID = f.FuncID

	INSERT INTO dbo.eaGroupPolicy(GroupID, FuncID, Policy)
    SELECT t.GroupID, @ParentID, t.Policy 
    FROM #GroupPolicyTable t
        LEFT JOIN dbo.eaGroupPolicy gp WITH(NOLOCK) ON gp.FuncID = @ParentID AND gp.groupID = t.GroupID
    WHERE gp.FuncID IS NULL	AND @ParentID<>0	
	UNION ALL
	SELECT t.GroupID, @FuncID, t.Policy 
    FROM #GroupPolicyTable t
        LEFT JOIN dbo.eaGroupPolicy gp WITH(NOLOCK) ON gp.FuncID = @FuncID AND gp.groupID = t.GroupID
    WHERE gp.FuncID IS NULL		
	

	/**************Write to Log table for each action********************/
	
	DECLARE @LogData NVARCHAR(MAX)
	
	SELECT @LogData =	'<EAS_GroupPolicyUpdMultiple>' +
							'<ParentID>' + ISNULL(CONVERT(VARCHAR(20),@ParentID), '') + '</ParentID>' +
							'<FuncID>' + ISNULL(CONVERT(VARCHAR(20),@FuncID), '') + '</FuncID>' +
							'<IP>' + COALESCE(@IP, '') + '</IP>' +
							'<Permission>' +
								'<Old>' + ISNULL(@OldPolicy, '') + '</Old>' +
								'<New>' + ISNULL(@Policy, '') + '</New>' +
							'</Permission>' +
						'</EAS_GroupPolicyUpdMultiple>'

	SET @EndRun = GETDATE()  
	SET @Duration  = DATEDIFF(MILLISECOND, @StartRun, @EndRun)   

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper] 
		@custID = @FuncID, 
		@TrackingValue = @LogData, 
		@userid = @UserID, 
		@TypeID = 0, 
		@actionid = 20003, 
		@duration = @Duration

	DROP TABLE #GroupPolicyTable
END
GO