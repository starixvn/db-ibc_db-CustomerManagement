/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_CustomerLockSuspendUpd
	@CustList	VARCHAR(MAX),
	@Lock		BIT,
	@UserID		INT, 
	@IP			VARCHAR(15),
	@ErrCode	INT	= 0 OUTPUT,	
	@ErrMsg		VARCHAR(MAX) = '' OUTPUT 
AS
/*
	Created: 20200216@Elodie
	Task : Insert customer who upline don''t allow to unsuspend
	DB: DBCUST/CustDB

	Revisions:
		- 20200216@Elodie: Initial SP [Redmine:#128451]
	Param's Explanation:
		@CustIDList: id of customer
		@Lock: 1:Lock, 2:Unlock
	Example: 
	DECLARE @ErrCode	INT	= 0,	
		@ErrMsg		VARCHAR(MAX) = '',
		@CustList	VARCHAR(MAX) = 'supertest1, member01'

	EXEC Acc_CustomerLockSuspendUpd 
		@CustList	= @CustList,
		@Lock		= 1,
		@UserID		= 8, 
		@IP			= '',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg     = @ErrMsg OUTPUT

	SELECT @ErrCode, @ErrMsg

*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #CustList (UserName NVARCHAR(50))
	CREATE TABLE #CustLog  (CustId INT, RoleId TINYINT, IsFinished BIT DEFAULT(0))

	DECLARE @WrongUserName NVARCHAR(50) = '', @CustIdLog INT, @RoleId TINYINT
	DECLARE @StartRun			DATETIME
			,@EndRun			DATETIME
			,@Duration			INT
			,@LogSPData			VARCHAR(MAX)
			,@TrackingValue2	VARCHAR(MAX)
	
	SET @StartRun = GETDATE()

	INSERT INTO #CustList (UserName)
	SELECT LTRIM(RTRIM(val))
	FROM dbo.strSplit(@CustList,',') t
		
	SELECT @WrongUserName = @WrongUserName + ', ' + t.username 
	FROM #CustList t
	WHERE NOT EXISTS (SELECT 1 FROM dbo.custInfo ci WITH (NOLOCK) WHERE t.UserName = ci.username)

	IF @WrongUserName <> ''
	BEGIN
		SELECT	@ErrCode = 100, 
				@ErrMsg= LTRIM(RTRIM(RIGHT(@WrongUserName,LEN(@WrongUserName)-1))) + ' is invalid. Please check username again.' 
		RETURN
	END

	SELECT @WrongUserName = @WrongUserName + ', ' + t.username 
	FROM #CustList t
	WHERE NOT EXISTS (	SELECT 1 
						FROM dbo.custInfo ci WITH (NOLOCK) 
							INNER JOIN Customer c WITH (NOLOCK) ON c.custid = ci.custid
						WHERE t.UserName = ci.username 
							AND c.site <> 'CN88'
							AND ci.srecommend NOT IN (SELECT custid FROM dbo.Dep_CustSuper WITH (NOLOCK))
					)

	IF @WrongUserName <> ''
	BEGIN
		SELECT	@ErrCode = 101, 
				@ErrMsg= LTRIM(RTRIM(RIGHT(@WrongUserName,LEN(@WrongUserName)-1))) + ' is invalid. Please enter only username of credit sites (except for china credit site).' 
		RETURN
	END

	IF @Lock = 1
	BEGIN
		INSERT INTO CustSuspendLockUpd (CustId) OUTPUT INSERTED.CustId, ci.roleid, 0 AS IsFinished INTO #CustLog
		SELECT ci.custid
		FROM #CustList t
			INNER JOIN dbo.custInfo ci ON t.UserName = ci.username 
		WHERE NOT EXISTS (SELECT 1 FROM CustSuspendLockUpd cs WHERE cs.custid = ci.custid)
	END
	ELSE
	BEGIN
		DELETE CustSuspendLockUpd OUTPUT DELETED.CustId, NULL AS roleID, 0 AS IsFinished INTO #CustLog
		WHERE custid IN (	SELECT custid 
							FROM #CustList t
								INNER JOIN dbo.custInfo ci ON t.UserName = ci.username)
	END

	IF(@@ERROR<>0)
	BEGIN
		SELECT	@ErrCode = 102, @ErrMsg = 'Updated unsuccessfully'
		RETURN
	END	

	-- Write log and mard direct suspend	
	SELECT @LogSPData = '<R Lock="'+ CASE WHEN @Lock = 1 THEN '1' ELSE '0' END + '" ' +
						'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" />'

	SELECT @TrackingValue2 = '<R Lock="'+ CASE WHEN @Lock = 1 THEN '0' ELSE '1' END + '" ' +
						'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" />'

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (1) #CustLog
		SET IsFinished = 1
			,@CustIdLog = CustId
			,@RoleId = RoleId			
		WHERE IsFinished = 0
	
		IF @@ROWCOUNT = 0 BREAK

		UPDATE	cs 
		SET	SuspendInfo = (SELECT suspendinfo FROM dbo.f_GenerateSuspendInfo(@roleid,1,ISNULL(SuspendInfo,0)))	
		FROM CustProductStatus cs WITH (ROWLOCK, UPDLOCK)			
		WHERE custid = @CustIdLog
	
		IF @RoleID BETWEEN 2 AND 4 
		BEGIN
			EXEC Acc_DynamicCustomerInfo_04
				@CustID		= @CustIdLog
				,@RoleID	= @RoleID
				,@Action	= 'SuspendInfo'
				,@Suspended	= 1					
		END

		SET @EndRun = GETDATE()
		SET @Duration  = DATEDIFF(MILLISECOND,@startRun,@endRun)

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
			@UserID = @UserID,
			@CustID = @CustIdLog,
			@ActionID = 1173,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @Duration		
	END			
END

