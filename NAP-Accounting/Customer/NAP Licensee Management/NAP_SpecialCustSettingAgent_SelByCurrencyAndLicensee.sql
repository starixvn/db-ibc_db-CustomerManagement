
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingAgent_SelByCurrencyAndLicensee    Script Date: 10/28/2014 9:45:18 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingAgent_SelByCurrencyAndLicensee    Script Date: 10/23/2014 12:48:23 PM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSettingAgent_SelByCurrencyAndLicensee]
	@Licensee NVARCHAR(100),
	@CurrencyID INT
AS
/*
Created: Dom
		Date: 2014-09-03
		Task: Get List of Agent by Licensee and currency
		DB: DBLIC/bodb_licensee
		
		Revisions:

*/
BEGIN
	DECLARE @LicenseeID INT 
	SELECT @LicenseeID = [site].SiteID
	FROM bodb02.dbo.[Site] ibcsite (NOLOCK)
     LEFT JOIN view_site_list [site] WITH(NOLOCK) ON ibcsite.siteid=site.IbcSiteID
	 WHERE ibcsite.[Site] = @licensee

	DECLARE @Agent TABLE(AgentID INT)
	INSERT INTO @Agent 
	SELECT CustID FROM dbo.licenseecust WITH(NOLOCK) WHERE LicenseeID = @LicenseeID AND Currency = @CurrencyID

	SELECT CustID AgentID, UserName AgentName FROM bodb02.dbo.CustInfo WITH(NOLOCK) WHERE CustID IN(SELECT AgentID from @Agent)
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSettingAgent_SelByCurrencyAndLicensee] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSettingAgent_SelByCurrencyAndLicensee] TO [bodbLicenseeNet]
GO 
