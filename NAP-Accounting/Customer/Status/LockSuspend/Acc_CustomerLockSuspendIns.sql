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
		@@CustIDList: id of customer
		@Lock: 1:Lock, 2:Unlock
*/
BEGIN
	SET NOCOUNT ON
	CREATE TABLE #CustList (UserName NVARCHAR(50))
	DECLARE @WrongUserName NVARCHAR(50) = '', @CustIdLog INT
	DECLARE @StartRun			DATETIME
			,@EndRun			DATETIME
			,@Duration			INT
			,@LogSPData			VARCHAR(MAX)
			,@TrackingValue2	VARCHAR(MAX)
	
	SET @StartRun = GETDATE()

	INSERT INTO #CustList (UserName)
	SELECT val 
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

	IF @Lock = 1
	BEGIN
		INSERT INTO CustSuspendLockUpd (CustId)
		SELECT ci.custid OUTPUT INSERTED.CustId, 0 AS IsFinished #CustLog
		FROM #CustList t
			INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON t.UserName = ci.username 
		WHERE NOT EXISTS (SELECT 1 FROM CustSuspendLockUpd cs WHERE cs.custid = ci.custid)
	END
	ELSE
	BEGIN
		DELETE CustSuspendLockUpd OUTPUT DELETED.CustId, 0 AS IsFinished #CustLog
		WHERE custid IN (SELECT custid FROM #CustList)
	END

	IF(@@ERROR<>0)
	BEGIN
		SELECT	@ErrCode = 100, @ErrMsg = 'Insert unsuccessfully'
		RETURN
	END

	-- Write log
	SET @EndRun = GETDATE()
	SET @Duration  = DATEDIFF(MILLISECOND,@startRun,@endRun)

	SELECT @LogSPData = '<R Lock="'+ CASE WHEN @Lock = 1 THEN '1' ELSE '0' END + '" ' +
						'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" />'

	SELECT @TrackingValue2 = '<R Lock="'+ CASE WHEN @Lock = 1 THEN '0' ELSE '1' END + '" ' +
						'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" />'

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (1) #CustLog
		SET IsFinished = 1
			,@CustIdLog = CustId			
		WHERE IsFinished = 0
	
		IF @@ROWCOUNT = 0 BREAK

		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper 
			@UserID = @UserID,
			@CustID = @CustIdLog,
			@ActionID = 1173,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @Duration		
	END			
END

