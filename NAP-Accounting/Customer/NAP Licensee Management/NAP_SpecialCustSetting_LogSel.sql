
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LogSel    Script Date: 10/28/2014 9:45:18 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LogSel    Script Date: 10/23/2014 12:48:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LogSel    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_LogSel]
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
*/ 
BEGIN
	SET NOCOUNT ON;

	IF(@AgentID IS NULL)
	BEGIN
		SELECT lg.LogDate, 
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
			AND lg.CustId IS NULL
			AND lg.LogDate >= @FromDate 
			AND lg.LogDate < DATEADD(dd,1,@ToDate)
		ORDER BY lg.LogDate DESC
	END
	ELSE
	BEGIN
		SELECT lg.LogDate, 
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
			AND lg.LogDate >= @FromDate 
			AND lg.LogDate < DATEADD(dd,1,@ToDate)
		ORDER BY lg.LogDate DESC
	END
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_LogSel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_LogSel] TO [bodbLicenseeNet]
GO 
