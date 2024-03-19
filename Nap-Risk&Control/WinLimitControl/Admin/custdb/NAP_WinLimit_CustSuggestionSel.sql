USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSuggestionSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSuggestionSel];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSuggestionSel]
	@CustName	VARCHAR(50)
AS
	/*
		Created: Phillip	
		Date: 2015-10-14
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBCust/CustDB
		
		Revisions:
			- 20160421@Patrick: Update pattern search like 'abc%'
			
		Parameters Explanation:	
			@CustName	: Part or full customer name.
			- Only get Members (RoleId = 1)
			- Exclude test/unused Currencies (20, 27, 28)
	*/
BEGIN
	SET NOCOUNT ON;
	IF (LEN(@CustName) < 3)
	BEGIN
		SELECT	NULL AS CustID,
				NULL AS UserName
	END
	ELSE
	BEGIN
		SELECT TOP 10 CustId, Username
			FROM dbo.CustInfo ci WITH (NOLOCK)
			WHERE ci.roleid = 1
				AND ci.username LIKE @CustName + '%'
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSuggestionSel] TO [bodbAdminNet,wsv_nap]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSuggestionSel] TO [vnteam]
GO