
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingGameType_Sel    Script Date: 10/28/2014 9:45:19 AM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingGameType_Sel    Script Date: 10/23/2014 12:48:25 PM ******/
/****** Object:  Stored Procedure dbo.NAP_SpecialCustSettingGameType_Sel    Script Date: 10/23/2014 8:38:07 AM ******/
CREATE PROCEDURE NAP_SpecialCustSettingGameType_Sel
AS
/*
	Created: Dom
		Date: 2014-09-03
		Task: Get gametypename of Keno
		DB: DBTXN/CustDB
		
		Revisions:
		20150609@Alex: Separate CustDB to DBCUST server (Use temp table for sports, bettype, GameType table)

*/
BEGIN
SET NOCOUNT ON
DECLARE @tmp_GameType TABLE (GameTypeID INT, GameTypeName NVARCHAR(50), IsDisabled BIT, IBCBettypeID INT)
	BEGIN TRY		
	INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
	SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBAGE.bodb02.dbo.GameType WITH (NOLOCK)
	END TRY
	BEGIN CATCH		
		INSERT INTO @tmp_GameType (GameTypeID, GameTypeName, IsDisabled, IBCBettypeID)
		SELECT GameTypeID, GameTypeName, IsDisabled, IBCBettypeID FROM DBTXN.bodb02.dbo.GameType WITH (NOLOCK)
	END CATCH
SELECT * FROM @tmp_GameType
END
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[NAP_SpecialCustSettingGameType_Sel] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[NAP_SpecialCustSettingGameType_Sel] TO [bodbLicenseeNet]
GO 
