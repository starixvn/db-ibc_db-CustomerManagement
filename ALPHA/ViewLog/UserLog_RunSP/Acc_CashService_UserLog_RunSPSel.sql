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
		  - 20250724@Helios: Agency Cash Service - Customer Setting Sprint 8 [redmine: #235266] 
	  Example:
		 EXEC Acc_CashService_UserLog_RunSPSel_UAT2 
							 @CustId	  =249550999
						     , @CustName	  ='AGENT03001'
						     , @LoginUserId =249550999
						     , @ActionTypeId=-1
						     , @FromDate	  ='2025-08-12 00:00:00'
						     , @ToDate	  ='2025-08-14 23:59:59'
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

	-- Calculate lower and upper bounds for pagination
	SET @lbound = @PageIndex * @PageSize;
	SET @ubound = @lbound + @PageSize;
	IF (@PageIndex > 0)
		SET @lbound = @lbound + 1;

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

	-- Create temp table to collect log result
	CREATE TABLE #TmpResult
	(
		LogDate DATETIME,
		logid INT,
		userid INT,
		username NVARCHAR(256),
		TrackingValue NVARCHAR(MAX),
		TrackingValue2 NVARCHAR(MAX),
		logdate2 DATETIME,
		ActionID INT,
		ActionTypeID INT,
		SPName VARCHAR(50),
		IsInternal TINYINT,
		custid INT,
		CustName VARCHAR(50),
		ActionNameEN NVARCHAR(256)
	);

	INSERT INTO #TmpResult
	(
		LogDate, logid, userid, username, TrackingValue, TrackingValue2, logdate2, ActionID, ActionTypeID, SPName, IsInternal, custid, CustName, ActionNameEN
	)
	SELECT
		LogDate,
		logid,
		userid,
		cs.username,
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
	LEFT JOIN bodb02.dbo.CustInfo cs WITH (NOLOCK) ON c.userid = cs.custid
	INNER JOIN #tmp_LogAction la ON c.ActionID = la.ActionID
	WHERE c.custid = @CustId
	AND logdate BETWEEN @FromDate AND @ToDate
	AND la.IsInternal <= @IsInternal
	AND la.Indirectly_Upline = 0

	UNION ALL

	SELECT
		LogDate,
		logid,
		userid,
		cs.username,
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
	LEFT JOIN bodb02.dbo.CustInfo cs WITH (NOLOCK) ON c.userid = cs.custid
	INNER JOIN #tmp_LogAction la ON c.ActionID = la.ActionID
	WHERE c.custid = @LoginUserId
	AND logdate BETWEEN @FromDate AND @ToDate
	AND la.IsInternal <= @IsInternal
	AND la.Indirectly_Upline = 1

	SELECT
		logid,
		userid,
		Username,
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
			Username,
			TrackingValue,
			TrackingValue2,
			logdate,
			ActionID,
			ActionTypeID,
			SPName,
			IsInternal,
			Custid,	
			ActionNameEN
		FROM #TmpResult
	) AS MyTable
	WHERE RowNum BETWEEN @lbound AND @ubound;

	-- Drop temporary table to release resources
	DROP TABLE #tmp_LogAction;
	DROP TABLE #TmpResult
END

