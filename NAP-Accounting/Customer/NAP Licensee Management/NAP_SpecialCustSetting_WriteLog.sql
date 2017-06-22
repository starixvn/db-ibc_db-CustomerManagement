
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_WriteLog    Script Date: 10/28/2014 9:45:18 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_WriteLog    Script Date: 10/23/2014 12:48:24 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_WriteLog    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE [dbo].[NAP_SpecialCustSetting_WriteLog]
    @UserId int,
	@IP varchar(15),
    @LicenseeID int,
    @CurrencyID int,
    @SPName varchar(50),
    @CustId int,
    @ActionId int,
    @Duration int,
    @Data XML,
    @OldData XML
AS
/*
        Created: Dom
        Date: 2014-08-29
        Task: Insert log customer setting
        DB: DBLOG/bodb_CustomerLog
        
        Revisions:
*/ 
BEGIN
	SET NOCOUNT ON;

	INSERT INTO Userlog_LicenseeSetting(UserId,IP,LicenseeID,CurrencyID,SPName,CustId,ActionId,Duration,Data,OldData)
	VALUES(@UserId,@IP,@LicenseeID,@CurrencyID,@SPName,@CustId,@ActionId,@Duration,@Data,@OldData)
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_WriteLog] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_WriteLog] TO [bodbLicenseeNet]
GO 
