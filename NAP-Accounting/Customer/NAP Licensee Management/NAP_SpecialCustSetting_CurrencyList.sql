
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_CurrencyList    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_CurrencyList    Script Date: 10/23/2014 12:48:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_CurrencyList    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_CurrencyList]
AS
/*
Created: Dom
		Date: 2014-08-29
		Task: Currency List
		DB: DBTXN/CustDB
		
		Revisions:

*/
BEGIN
	SELECT exchangeid,currency FROM Exchange WITH(NOLOCK)
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_CurrencyList] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_CurrencyList] TO [bodbLicenseeNet]
GO 
