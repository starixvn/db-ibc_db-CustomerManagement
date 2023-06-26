/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_SpecialCustSetting_LogSel]
	@LicenseeID INT,
	@CurrencyID INT = NULL,
	@AgentID INT = NULL,
	@FromDate DATETIME,
	@ToDate DATETIME
AS

/*
	Created: Dom
	Date: 2014-08-29
	Task: Get log customer setting
	DB: DBLOG/bodb_CustomerLog
        
	Revisions:
		 - 20230224@Winfred: NAP LM - Enhance Bet Setting function for AM to use [redmine:#178105]
*/ 
BEGIN
	SET NOCOUNT ON;

	IF(@AgentID IS NULL)
	BEGIN
		SELECT lg.LogId, lg.LogDate, 
			Ad.UserName EditedBy,
			'' AgentName,
			la.ActionName,
			la.ActionId,
			lg.Data,
			lg.OldData,
			la.Items
		FROM [Userlog_LicenseeSetting] lg WITH(NOLOCK) 
		INNER JOIN LogAction_Lic la WITH(NOLOCK) ON la.ActionId = lg.ActionId
		INNER JOIN bodb02.dbo.CustInfo ad WITH(NOLOCK) ON ad.CustID = lg.UserID
		WHERE lg.LicenseeID = @LicenseeID
			AND lg.CurrencyID = @CurrencyID
			--AND lg.CustId IS NULL
			AND lg.LogDate BETWEEN @FromDate AND @ToDate
		ORDER BY lg.LogDate DESC
	END
	ELSE
	BEGIN
		SELECT lg.LogId, lg.LogDate, 
				Ad.UserName EditedBy,
				ci.UserName AgentName,
				la.ActionName,
				la.ActionId,
				lg.Data,
				lg.OldData,
				la.Items
		FROM [Userlog_LicenseeSetting] lg WITH(NOLOCK) 
		INNER JOIN LogAction_Lic la WITH(NOLOCK) ON la.ActionId = lg.ActionId
		INNER JOIN bodb02.dbo.CustInfo ci WITH(NOLOCK) ON ci.CustID = lg.CustID
		INNER JOIN bodb02.dbo.CustInfo ad WITH(NOLOCK) ON ad.CustID = lg.UserID
		WHERE lg.LicenseeID = @LicenseeID
			AND lg.CurrencyID = @CurrencyID
			AND lg.CustId = @AgentID
			AND lg.LogDate BETWEEN @FromDate AND @ToDate
		ORDER BY lg.LogDate DESC
	END
END
GO
