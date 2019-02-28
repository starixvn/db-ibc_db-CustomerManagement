/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_Rpt_PTSettingHistorySel
	@CustID INT,
	@FromDate DATETIME,
	@ToDate DATETIME,
	@IsTest BIT = 0
AS
/*
	Created: 20181212@Elodie
	Task : Get PT info history to show on legency report
	DB: DBLOG/bodb_CustomerLog
	Original:

	Revisions:
		- 20181212@Elodie: Initial SP [Redmine:#105338]
		
	Param's Explanation:
				
	Example: 
		EXEC CS_Rpt_PTSettingHistorySel @CustID = 34109850, @IsTest = 1, @FromDate = '2019-02-27 02:31:54.380', @ToDate = '2019-02-28 02:31:54.380'
*/

BEGIN
	SET NOCOUNT ON
	CREATE TABLE #Log (LogId BIGINT, LogDate DATETIME, NewValue XML, OldValue XML)
	
	--SELECT DISTINCT ProductID, SportType,Bettype,IsLive, SettingType 
	--INTO #SportBettypeFilter1
	--FROM DBACC.bodb02.dbo.CS_ProductSettingDetail WITH(NOLOCK)
	--WHERE SettingType = 1 AND SettingStatus <= @IsTest

	--Expectation: Use Clustering Index IX_UserLog_RunSP
	SELECT LogId, ActionID, LogDate, ul.TrackingValue, ul.TrackingValue2 INTO #LogTmp
	FROM dbo.UserLog_RunSP ul WITH (NOLOCK)
	WHERE ul.custid = @CustID
		AND ul.logdate BETWEEN @FromDate AND @ToDate

	INSERT INTO #Log (LogId, LogDate, NewValue, OldValue)
	SELECT ul.LogId, ul.LogDate, ul.TrackingValue, ul.TrackingValue2
	FROM dbo.LogAction l WITH (NOLOCK)
		INNER JOIN dbo.LogActionDetail ld WITH (NOLOCK) ON ld.ActionID = l.ActionID	
		INNER JOIN #LogTmp ul WITH (NOLOCK) ON l.ActionID = ul.ActionID
	WHERE l.SPName = 'CS_CustSetting_PTSetting_Upd' AND ld.Level = 2
		--AND DATEADD(HOUR,7,DATEADD(DAY, (DATEDIFF(DAY, 0, LogDate) / 7) * 7 + 7, 0)) BETWEEN @FromDate AND @ToDate

	--SELECT * FROM #Log 

	SELECT LogId, LogDate
			, n.value('./@SportType','SMALLINT') AS SportType
			, n.value('./@BetType','SMALLINT') AS BetType
			, n.value('./@IsLive','BIT') AS IsLive									
			, n.value('./@ProductID','SMALLINT') AS ProductID
			, n.value('./@MasterPT','SMALLMONEY') AS MasterPT	
	INTO #NewData
	FROM #Log
		CROSS APPLY NewValue.nodes('//R') AS RECORDS(n)
	
	SELECT LogId, o.value('./@MasterPT','SMALLMONEY') AS MasterPT		
	INTO #OldData
	FROM #Log
		CROSS APPLY OldValue.nodes('//R') AS RECORDS(o)
	
	SELECT DATEADD(HOUR,7,DATEADD(DAY, (DATEDIFF(DAY, 0, n.LogDate) / 7) * 7 + 7, 0)) AS EffectiveDate,
		n.SportType, n.BetType, n.ProductID, 
		n.MasterPT AS NewPT, o.MasterPT AS OldPT 
	FROM #NewData n 
		INNER JOIN #OldData o ON o.LogId = n.LogId
	WHERE n.MasterPT <> o.MasterPT

	DROP TABLE #Log
	DROP TABLE #LogTmp
	DROP TABLE #OldData
	DROP TABLE #NewData
	--DROP TABLE #SportBettypeFilter1
END
GO
