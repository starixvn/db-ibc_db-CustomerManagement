/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelVirtualRateHistory]	
	@CustID INT,
	@ViewType TINYINT = 0
AS
/*
Created: 
Task : View change history of virtual rate
DB: DBLOG.bodb_CustomerLog
Original: 
Revisions:	
	- 20091106@Simon: View change history of virtual rate
	- 20100512@Kiwi: Retrieve data from TrackingValue rather than doing.
	- 20110923@Henry: show logs that updated from LRF
	- 20141231@Johnson: separate virtual rate settings by sporttype bettype [Redmine: #25840]
	- 20190405@Patrick: Support archive date range [Redmine: #111476]
	- 20190814@Winnie: NAP - UI did not show history of Virtual Rate with CN88 account. [Redmine: #118631]
	- 20200115@Johnson: add new logaction for auto update VR [redmine:#126998]
	- 20210224@Eden: Implement Lock for VR update [Redmine:#149370]
	- 20230418@Luke: Separate log for Lock function & increase log data to top 50 [Redmine: #186897]
	- 20230711@Helios: VR Accumulate Balance [Redmine: #189649]
	- 20231129@Luke: NAP - Virtual rate - Enhance VR [Redmine: #194939]
Explanations:
ActionID: 801, SPName: Acc_CustomerUpdVirtualMultiplier
ActionID: 802, SPName: Acc_VirtualRateMulUpd
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Site VARCHAR(10)
	SELECT @Site= Site FROM bodb02.dbo.Customer c WITH(NOLOCK) WHERE custid = @CustID
	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	DECLARE @actionID AS TABLE
	(
		ActionID INT
		)

	CREATE TABLE #__tempDataCN88
	(
		logdate DATETIME,
		ActionID INT,
		TrackingValue NVARCHAR(MAX),
		Username NVARCHAR(50)
		)
	CREATE TABLE #__tempData_ArchiveCN88
	(
		logdate DATETIME,
		ActionID INT,
		TrackingValue NVARCHAR(MAX),
		Username NVARCHAR(50)
		)
	CREATE TABLE #__tempData
	(
		logdate DATETIME,
		ActionID INT,
		TrackingValue NVARCHAR(MAX),
		Username NVARCHAR(50)
		)
	CREATE TABLE #__tempData_Archive
	(
		logdate DATETIME,
		ActionID INT,
		TrackingValue NVARCHAR(MAX),
		Username NVARCHAR(50)
		)

	IF (@ViewType = 1)	--View Lock Status log
	BEGIN
		INSERT INTO @actionID(actionID) 
		VALUES
			(829)
			,(830)
			,(837)
			,(844)
			,(845)
			,(846)
	END
	ELSE IF (@ViewType = 2) --View VR log, VR status (except Lock Status log)
	BEGIN
		INSERT INTO @actionID(actionID) 
		VALUES
			(801)
			,(802)
			,(806)
			,(807)
			,(810)
			,(2800)
			,(2802)
			,(839)
			,(847)
			,(95116)
			,(95117)
			,(95118)
			,(2803)
			,(2804)
			,(2805)
	END
	ELSE --View all log
	BEGIN
		INSERT INTO @actionID(actionID) 
		VALUES
			(801)
			,(802)
			,(806)
			,(807)
			,(810)
			,(829)
			,(830)
			,(837)
			,(2800)
			,(2802)
			,(839)
			,(844)
			,(845)
			,(846)
			,(847)
			,(95116)
			,(95117)
			,(95118)
			,(2803)
			,(2804)
			,(2805)
	END
	IF @Site='CN88'
	BEGIN
		INSERT INTO #__tempDataCN88 (logdate, ActionID, TrackingValue, Username)
		SELECT TOP 50 logdate,	
			u.ActionID,	
			TrackingValue,
			Username =	
			CASE 
							when (u.ActionID IN (2800,2802,2803,2804,2805)) then 'LRF Admin'
							ELSE c.Username
						END
		FROM dbo.CS_UserLog_RunSP u WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
			INNER JOIN @actionID a ON a.ActionID = u.ActionID
		WHERE u.custid = @CustID
			AND logdate >= @__archiveDate
		ORDER BY logdate DESC

		IF @@ROWCOUNT >= 50
		BEGIN
			SELECT logdate, ActionID, TrackingValue, Username
			FROM #__tempDataCN88
			ORDER BY logdate DESC
				
			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO #__tempData_ArchiveCN88 (logdate, ActionID, TrackingValue, Username)
			SELECT TOP 50 logdate,	
				u.ActionID,	
				TrackingValue,
				Username =	
				CASE 
								when (u.ActionID IN (2800,2802,2803,2804,2805)) then 'LRF Admin'
								ELSE c.Username
							END
			FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP u WITH(NOLOCK)
				LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
				INNER JOIN @actionID a ON a.ActionID = u.ActionID
			WHERE u.custid = @CustID
				AND u.logdate < @__archiveDate
			ORDER BY logdate DESC

			SELECT TOP 50 logdate, ActionID, TrackingValue, Username
			FROM (
				SELECT logdate, ActionID, TrackingValue, Username
				FROM #__tempDataCN88

				UNION ALL
				SELECT logdate, ActionID, TrackingValue, Username
				FROM #__tempData_ArchiveCN88
			)t ORDER BY logdate DESC
		END
	END
	ELSE
	BEGIN
		INSERT INTO #__tempData (logdate, ActionID, TrackingValue, Username)
		SELECT TOP 50 logdate,	
			u.ActionID,	
			TrackingValue,
			Username =	
			CASE 
							when (u.ActionID IN (2800,2802,2803,2804,2805)) then 'LRF Admin'
							ELSE c.Username
						END
		FROM dbo.UserLog_RunSP u WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
			INNER JOIN @actionID a ON a.ActionID = u.ActionID
		WHERE u.custid = @CustID
			AND logdate >= @__archiveDate
		ORDER BY logdate DESC

		IF @@ROWCOUNT >= 50
		BEGIN
			SELECT logdate, ActionID, TrackingValue, Username
			FROM #__tempData
			ORDER BY logdate DESC
		
			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO #__tempData_Archive (logdate, ActionID, TrackingValue, Username)
			SELECT TOP 50 logdate,	
				u.ActionID,	
				TrackingValue,
				Username =	
				CASE 
								when (u.ActionID IN (2800,2802,2803,2804,2805)) then 'LRF Admin'
								ELSE c.Username
							END
			FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP u WITH(NOLOCK)
				LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
				INNER JOIN @actionID a ON a.ActionID = u.ActionID
			WHERE u.custid = @CustID
				AND u.logdate < @__archiveDate
			ORDER BY logdate DESC

			SELECT TOP 50 logdate, ActionID, TrackingValue, Username
			FROM (
				SELECT logdate, ActionID, TrackingValue, Username
				FROM #__tempData

				UNION ALL
				SELECT logdate, ActionID, TrackingValue, Username
				FROM #__tempData_Archive
			)t ORDER BY logdate DESC
		END
	END
	DROP TABLE #__tempDataCN88
	DROP TABLE #__tempData_ArchiveCN88
	DROP TABLE #__tempData
	DROP TABLE #__tempData_Archive
END
GO
