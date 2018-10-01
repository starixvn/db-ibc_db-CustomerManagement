/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbLicenseeNet" viewers="vnteam" isFunction="0"></info>*/
USE bodb_licensee 
GO

ALTER PROCEDURE [dbo].[NAP_SpecialCustSettingAgent_SelByCurrencyAndLicensee]
	@Licensee NVARCHAR(100),
	@CurrencyID INT
AS
/*
	Created: Dom
	Date: 2014-09-03
	Task: Get List of Agent by Licensee and currency
	DB: DBCUST/bodb_licensee
		
	Revisions:

*/
BEGIN
	DECLARE @LicenseeID INT 
	SELECT @LicenseeID = [site].SiteID
	FROM dbo.[Site] ibcsite (NOLOCK)
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
