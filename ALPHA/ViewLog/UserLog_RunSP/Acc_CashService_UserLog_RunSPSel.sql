/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_CashService,wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_CashService_UserLog_RunSPSel
(
	@CustId INT,
	@LoginUserId INT = 0,
	@CustName VARCHAR(50) = '',
	@FromDate DATETIME,
	@ToDate DATETIME,
	@ActionTypeId INT = -1,
	@IsInternal TINYINT,
	@LowerActionId INT = NULL,
	@UpperActionId INT = NULL,
	@PageIndex INT,
	@PageSize INT
) 
AS
/*
	  Created:      20250728@Helios
	  Task:		  Log Cash Service – Create stored procedure to query operation log for CashService [#233474] 
	  DB:           DBLOG-bodb_CustomerLog
	  Revisions:
		  - 20250728@Helios: Initial create for CashService log [redmine: 233474] 

	  Example:
		 EXEC Acc_CashService_UserLog_RunSPSel_UAT2 
							 @CustId	  =16297291
						     , @CustName	  ='AGENT03001'
						     , @LoginUserId =14373905
						     , @ActionTypeId=-1
						     , @FromDate	  ='2025-08-01 00:00:00'
						     , @ToDate	  ='2025-08-03 23:59:59'
						     , @IsInternal  =0
						     , @PageIndex	  =0
						     , @PageSize	  =50
*/
BEGIN
	SET NOCOUNT ON;

	-- Ensure page index and size are positive integers
	SET @PageIndex = ABS(@PageIndex);
	SET @PageSize  = ABS(@PageSize);

	-- Declare variables for pagination and date tracking
	DECLARE
		@lbound      INT,
		@ubound      INT,
		@creatdate   DATETIME;

	-- Get customer creation date to ensure proper date range
	SELECT @creatdate = creatdate
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
	WHERE custid = @CustId;

	-- Adjust @FromDate if it is earlier than @creatdate (backward 30 seconds to ensure log coverage)
	-- IF @FromDate < @creatdate
	-- 	SELECT @FromDate = DATEADD(SECOND, -30, @creatdate); -- Backward 30s to get log [#97633]

	-- Calculate lower and upper bounds for pagination
	SET @lbound = @PageIndex * @PageSize;
	SET @ubound = @lbound + @PageSize;
	IF (@PageIndex > 0)
		SET @lbound = @lbound + 1;

	-- (Optional) Archive date logic, currently commented out
	--DECLARE @__archiveDate DATETIME;
	--SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate());

	-- Create temporary table to store filtered LogAction records
	CREATE TABLE #tmp_LogAction
	(
		ActionID        INT,
		ActionTypeID    INT,
		SPName          VARCHAR(50),
		ActionNameEN    NVARCHAR(256),
		IsInternal      TINYINT
	);

	-- Populate #tmp_LogAction with relevant actions based on ActionTypeId
	-- IF (@LowerActionId IS NOT NULL AND @UpperActionId IS NOT NULL)
	-- BEGIN
	-- 	-- If action range is specified, filter by ActionID range
	-- 	INSERT INTO #tmp_LogAction
	-- 	(
	-- 		ActionID,
	-- 		ActionTypeID,
	-- 		SPName,
	-- 		ActionNameEN,
	-- 		IsInternal
	-- 	)
	-- 	SELECT
	-- 		ActionID,
	-- 		ActionTypeID,
	-- 		SPName,
	-- 		ActionNameEN,
	-- 		IsInternal
	-- 	FROM dbo.LogAction WITH (NOLOCK)
	-- 	WHERE ActionID BETWEEN @LowerActionId AND @UpperActionId;
	-- END
	-- ELSE 
	IF @ActionTypeId = -1
	BEGIN
		-- If ActionTypeId = -1, select all standard action types for CashService
		INSERT INTO #tmp_LogAction
		(
			ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal
		)
		SELECT
			ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal
		FROM dbo.LogAction WITH (NOLOCK)
		WHERE ActionTypeID IN (100, 101, 102, 103, 104, 105);
	END
	ELSE
	BEGIN
		-- Otherwise, select only actions matching the provided ActionTypeId
		INSERT INTO #tmp_LogAction
		(
			ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal
		)
		SELECT
			ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal
		FROM dbo.LogAction WITH (NOLOCK)
		WHERE ActionTypeID = @ActionTypeId;
	END

	-- Query all log data for ActionID list and join with user info
	SELECT
		logid,
		userid,
		username,
		TrackingValue,
		TrackingValue2 AS TrackingValueOld,
		logdate,
		ActionID,
		ActionTypeID,
		SPName,
		IsInternal,
		Custid,
		ActionNameEN
	FROM(
		SELECT
			ROW_NUMBER() OVER ( ORDER BY LogDate DESC) AS RowNum,
			logid,
			userid,
			i.username,
			ISNULL(TrackingValueMask, c.TrackingValue) AS TrackingValue,
			ISNULL(TrackingValueMask2, c.TrackingValue2) AS TrackingValue2,
			logdate,
			c.ActionID,
			la.ActionTypeID,
			la.SPName,
			la.IsInternal,
			c.custid,
			ISNULL(@CustName, '') AS CustName,
			la.ActionNameEN
		FROM dbo.Cash_UserLog_RunSP c WITH (NOLOCK)
		INNER JOIN #tmp_LogAction la ON c.ActionID = la.ActionID
		LEFT JOIN bodb02.dbo.custInfo i WITH (NOLOCK) ON c.userid = i.custid 
		WHERE c.userid = @LoginUserId
		AND c.custid IN (@LoginUserId, @CustId)
		AND logdate BETWEEN @FromDate AND @ToDate
		AND la.IsInternal <= @IsInternal
	) AS MyTable
	WHERE RowNum BETWEEN @lbound AND @ubound;

	-- Drop temporary table to release resources
	DROP TABLE #tmp_LogAction;
END

