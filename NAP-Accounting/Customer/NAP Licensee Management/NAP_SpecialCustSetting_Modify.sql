
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Modify    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Modify    Script Date: 10/23/2014 12:48:25 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSetting_Modify    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE NAP_SpecialCustSetting_Modify
	@Licensee NVARCHAR(100),
	@CurrencyID INT,
	@AgentID INT = NULL,
	@Settings XML,
	@ErrCode INT = 0  OUTPUT,
	@ErrMsg NVARCHAR(MAX)=''  OUTPUT,
	@IP NVARCHAR(20),
	@UserID INT
AS
BEGIN
	IF(
		NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimit_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND ( (@AgentID IS NULL AND AgentID IS NULL) OR (AgentID = @AgentID)) ) AND
		NOT EXISTS(SELECT TOP 1 1 FROM [Dep_CustBetLimitGameType_Special] cbs WITH(NOLOCK) WHERE cbs.[Site] = @Licensee AND cbs.CurrencyID=@CurrencyID AND @AgentID IS NULL)
	)
	BEGIN
								EXEC [NAP_SpecialCustSetting_Add]
			@Licensee = @Licensee,
			@CurrencyID = @CurrencyID,
			@AgentID = @AgentID,
			@Settings = @Settings,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@IP = @IP,
			@UserID = @UserID
	END
	ELSE 
	BEGIN
								EXEC [NAP_SpecialCustSetting_Upd]
			@Licensee = @Licensee,
			@CurrencyID = @CurrencyID,
			@AgentID = @AgentID,
			@Settings = @Settings,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT,
			@IP = @IP,
			@UserID = @UserID
	END
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSetting_Modify] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSetting_Modify] TO [bodbLicenseeNet]
GO 
