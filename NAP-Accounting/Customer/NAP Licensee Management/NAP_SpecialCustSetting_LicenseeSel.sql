
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LicenseeSel    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LicenseeSel    Script Date: 10/23/2014 12:48:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LicenseeSel    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE NAP_SpecialCustSetting_LicenseeSel
	@Licensee NVARCHAR(100)
	,@CurrencyID INT
	,@AgentID INT = NULL
AS
/*
Created: Dom
		Date: 2014-09-03
		Task: Get Product Hardcode setting by licensee and currency
		DB: DBTXN/CustDB
		
		Revisions:

*/
BEGIN
	-------Get Basic product-------------
	SELECT CASE WHEN cbs.SportType =99 AND cbs.Bettype=9 THEN 'Mix Sports Parlay' ELSE s.SportName END SportName
		,cbs.Bettype
		,cbs.SportType
		,MaxBet
		,MaxPerMatch
		,MaxPerBall
	FROM [dbo].[Dep_CustBetLimit_Special] cbs WITH(NOLOCK)
	INNER JOIN bodb02.dbo.Sports s WITH(NOLOCK) ON s.SportType = cbs.SportType
	WHERE CurrencyID = @CurrencyID
		AND (@AgentID IS NULL OR AgentID = @AgentID)
		AND [Site] = @Licensee
	ORDER BY cbs.SportType

	-------Get Keno product-------------
	SELECT bt.GameTypeName GameType
		,cbs.gametypeid
		,maxbet
		,maxpergametype MaxPerMatch
	FROM [dbo].[Dep_CustBetLimitGameType_Special] cbs WITH(NOLOCK)
	INNER JOIN [bodb02].[dbo].[GameType] bt WITH(NOLOCK) ON bt.GameTypeID = cbs.gametypeid
	WHERE  CurrencyID = @CurrencyID
		AND [Site] = @Licensee
		AND @AgentID IS NULL
	ORDER BY cbs.gametypeid
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_LicenseeSel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_LicenseeSel] TO [bodbLicenseeNet]
GO 
