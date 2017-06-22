SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LicenseeList    Script Date: 10/28/2014 9:45:18 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LicenseeList    Script Date: 10/23/2014 12:48:23 PM ******/

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_LicenseeList    Script Date: 10/22/2014 8:48:56 AM ******/
CREATE PROCEDURE NAP_SpecialCustSetting_LicenseeList
AS
/*
		Created: Dom
		Date: 2014-08-29
		Task: Licesee List
		DB: DBLIC/bodb_Licensee
		
		Revisions:
*/ 
BEGIN
	SELECT [site].SiteName,[site].SiteID 
	FROM bodb02.dbo.[Site] ibcsite 
		LEFT JOIN bodb_Licensee.dbo.view_site_list [site] (NOLOCK) ON ibcsite.siteid=[site].IbcSiteID
	WHERE islicensee=1
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_LicenseeList] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_LicenseeList] TO [bodbLicenseeNet]
GO 
