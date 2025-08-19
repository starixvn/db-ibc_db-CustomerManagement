/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_CashService,wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_CashService_UserLog_RunSPSelTotalRecords
(
    @CustId INT,
    @LoginUserId INT = 0,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @ActionTypeId INT = -1,
    @IsInternal TINYINT,
    @LowerActionId INT = NULL,
    @UpperActionId INT = NULL
)
AS
/*
      Created:      20250728@Helios
      Task:         Log Cash Service – Create SP to count total log records for CashService [#233474] 
      DB:           DBLOG-bodb_CustomerLog
      Revisions:
          - 20250728@Helios: Initial create for CashService log [redmine: 233474]
	    - 20250724@Helios: Agency Cash Service -Customer Setting Sprint 8 [redmine: #235266] 
      Example:
          EXEC dbo.Acc_CashService_UserLog_RunSPSelTotalRecords @CustId = 1, @LoginUserId = 2, @FromDate = '2025-07-01', @ToDate = '2025-07-28', @ActionTypeId = -1, @IsInternal = 0; 
*/
BEGIN
      SET NOCOUNT ON;
    
	-- Create temporary table to store filtered LogAction records 
	CREATE TABLE #tmp_LogAction
	(
		ActionID        INT,
		ActionTypeID    INT,
		SPName          VARCHAR(50),
		ActionNameEN    NVARCHAR(256),
		IsInternal      TINYINT
	);

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
		WHERE ActionTypeID >= 100;
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
		COUNT(1) AS TotalRecords
	FROM dbo.Cash_UserLog_RunSP c WITH (NOLOCK)
	INNER JOIN #tmp_LogAction la ON c.ActionID = la.ActionID
	WHERE c.custid = @CustId
	AND logdate BETWEEN @FromDate AND @ToDate
	AND la.IsInternal <= @IsInternal

	-- Drop temporary table to release resources
	DROP TABLE #tmp_LogAction;
END;
