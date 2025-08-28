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
		ActionID			INT,
		ActionTypeID		INT,
		SPName			VARCHAR(50),
		ActionNameEN		NVARCHAR(256),
		IsInternal			TINYINT,
		Indirectly_Upline		TINYINT DEFAULT 0
	);

	CREATE NONCLUSTERED INDEX IX_tmp_LogAction_ActionID ON #tmp_LogAction(ActionID);

	IF @ActionTypeId = -1
	BEGIN
		-- If ActionTypeId = -1, select all standard action types for CashService
		INSERT INTO #tmp_LogAction
		(
			ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal,
			Indirectly_Upline
		)
		SELECT
			la.ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal,
			CASE WHEN lad.Level IS NULL THEN 0 ELSE 1 END AS Indirectly_Upline
		FROM dbo.LogAction la WITH (NOLOCK)
		LEFT JOIN LogActionDetail lad WITH (NOLOCK) ON la.ActionID = lad.ActionID
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
			IsInternal,
			Indirectly_Upline
		)
		SELECT
			la.ActionID,
			ActionTypeID,
			SPName,
			ActionNameEN,
			IsInternal,
			CASE WHEN lad.Level IS NULL THEN 0 ELSE 1 END AS Indirectly_Upline
		FROM dbo.LogAction la WITH (NOLOCK)
		LEFT JOIN LogActionDetail lad WITH (NOLOCK) ON la.ActionID = lad.ActionID
		WHERE ActionTypeID = @ActionTypeId;
	END

	
	DECLARE @Total INT = 0,
			@Total_Indirect INT = 0;

	SELECT @Total = COUNT(1)
	FROM dbo.Cash_UserLog_RunSP c WITH (NOLOCK)
	LEFT JOIN bodb02.dbo.CustInfo cs WITH (NOLOCK) ON c.userid = cs.custid
	INNER JOIN #tmp_LogAction la ON c.ActionID = la.ActionID
	WHERE c.custid = @CustId
		AND logdate BETWEEN @FromDate AND @ToDate
		AND la.IsInternal <= @IsInternal
		AND la.Indirectly_Upline = 0;

	SELECT @Total_Indirect = COUNT(1)
	FROM dbo.Cash_UserLog_RunSP c WITH (NOLOCK)
	LEFT JOIN bodb02.dbo.CustInfo cs WITH (NOLOCK) ON c.userid = cs.custid
	INNER JOIN #tmp_LogAction la ON c.ActionID = la.ActionID
	WHERE c.custid = @LoginUserId
		AND logdate BETWEEN @FromDate AND @ToDate
		AND la.IsInternal <= @IsInternal
		AND la.Indirectly_Upline = 1;

	SELECT (@Total + @Total_Indirect) AS TotalRecords;

	-- Drop temporary table to release resources
	DROP TABLE #tmp_LogAction;
END
