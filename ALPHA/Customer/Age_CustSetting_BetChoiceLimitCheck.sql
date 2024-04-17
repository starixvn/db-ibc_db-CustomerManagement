USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustSetting_BetChoiceLimitCheck]    Script Date: 09/26/2016 16:14:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_CustSetting_BetChoiceLimitCheck]
(
	@CustID INT = 0 -- FOR SMA ONLY
)
AS
/*
	Created: 20160812@Helen
	Task: Check if Betchoice Limit Link is showed- [redmine: 61873]
	Database: DBCUST/CustDB
	
	Description:
		ONLY hardcode Product offer betchoice limit 
			- SportType 211: Allbet
	Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON
	
	DECLARE @IsShowed INT = 0
	
	IF EXISTS (SELECT TOP 1 1 
			   FROM ProductStatusProfile PSP WITH (NOLOCK) 
					INNER JOIN CustProductStatus CPS WITH (NOLOCK) ON CPS.CustID = @CustID AND PSP.Sporttype IN (211)
				WHERE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(CPS.bitmapIsHidden, PSP.bitmapOrder)) = 0 
					  
			   )	
	BEGIN			
		SET @IsShowed = 1
	END			

	SELECT @IsShowed AS IsShowed
	
	SET NOCOUNT OFF
END


GO 
GRANT EXECUTE ON [dbo].Age_CustSetting_BetChoiceLimitCheck TO [bodbDownlineNetView,wsv_alpv]
GO 
GRANT EXECUTE ON [dbo].Age_CustSetting_BetChoiceLimitCheck TO [wsv_alp]