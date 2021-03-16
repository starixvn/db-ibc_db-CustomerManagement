/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelVirtualRateHistory]	
	@CustID INT
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
Explanations:
ActionID: 801, SPName: Acc_CustomerUpdVirtualMultiplier
ActionID: 802, SPName: Acc_VirtualRateMulUpd
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Site VARCHAR(10)
	SELECT @Site=Site FROM bodb02.dbo.Customer c WITH(NOLOCK) WHERE custid=@CustID
	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

	IF @Site='CN88'
	BEGIN
		
		SELECT TOP 10 logdate,	
			ActionID,	
			TrackingValue,
			Username =	CASE 
							when (ActionID IN (2800,2802)) then 'LRF Admin'
							ELSE c.Username
						END
		INTO #__tempDataCN88
		FROM dbo.CS_UserLog_RunSP u WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
		WHERE u.custid = @CustID
			AND ActionID IN (801,802,806,807,2800,2802,829,830)
			AND logdate >= @__archiveDate
		ORDER BY logdate DESC

		IF @@ROWCOUNT >= 10
		BEGIN
			SELECT *
			FROM #__tempDataCN88
			ORDER BY logdate DESC
		
			RETURN
		END
		ELSE
		BEGIN
			SELECT TOP 10 logdate,	
				ActionID,	
				TrackingValue,
				Username =	CASE 
								when (ActionID IN (2800,2802)) then 'LRF Admin'
								ELSE c.Username
							END
			INTO #__tempData_ArchiveCN88
			FROM bodb_CustomerLog_Archive.dbo.CS_UserLog_RunSP u WITH(NOLOCK)
				LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
			WHERE u.custid = @CustID
				AND ActionID IN (801,802,806,807,2800,2802,829,830)
				AND u.logdate < @__archiveDate
			ORDER BY logdate DESC

			SELECT TOP 10 *
			FROM (
				SELECT *
				FROM #__tempDataCN88

				UNION ALL
				SELECT *
				FROM #__tempData_ArchiveCN88
			)t ORDER BY logdate DESC
		END
	END
	ELSE
	BEGIN
		SELECT TOP 10 logdate,	
			ActionID,	
			TrackingValue,
			Username =	CASE 
							when (ActionID IN (2800,2802)) then 'LRF Admin'
							ELSE c.Username
						END
		INTO #__tempData
		FROM dbo.UserLog_RunSP u WITH(NOLOCK)
			LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
		WHERE u.custid = @CustID
			AND ActionID IN (801,802,806,807,810,2800,2802,829,830)
			AND logdate >= @__archiveDate
		ORDER BY logdate DESC

		IF @@ROWCOUNT >= 10
		BEGIN
			SELECT *
			FROM #__tempData
			ORDER BY logdate DESC
		
			RETURN
		END
		ELSE
		BEGIN
			SELECT TOP 10 logdate,	
				ActionID,	
				TrackingValue,
				Username =	CASE 
								when (ActionID IN (2800,2802)) then 'LRF Admin'
								ELSE c.Username
							END
			INTO #__tempData_Archive
			FROM bodb_CustomerLog_Archive.dbo.UserLog_RunSP u WITH(NOLOCK)
				LEFT JOIN bodb02.dbo.CustInfo c WITH(NOLOCK) ON c.custid = u.userid
			WHERE u.custid = @CustID
				AND ActionID IN (801,802,806,807,810,2800,2802,829,830)
				AND u.logdate < @__archiveDate
			ORDER BY logdate DESC

			SELECT TOP 10 *
			FROM (
				SELECT *
				FROM #__tempData

				UNION ALL
				SELECT *
				FROM #__tempData_Archive
			)t ORDER BY logdate DESC
		END
	END

	
END
GO
