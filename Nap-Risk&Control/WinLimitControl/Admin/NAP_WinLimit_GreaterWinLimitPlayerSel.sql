USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel];
GO



/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel]    Script Date: 07/07/2015 16:09:58 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel] @ExchangeID  INT,
                                                               @ProductID   TINYINT,
                                                               @MaxWinLimit MONEY
AS
	
/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBCust/CustDB
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID		: Currency ID.
			@ProductID		: Product ID.
			@MaxWinLimit	: Max Win Limit amount.
	*/

     BEGIN
         SET NOCOUNT ON;
         SELECT cs.CustID,
                c.username,
                cs.ProductID,
                cs.MaxWinLimit AS CurrentWinLimit,
                @MaxWinLimit AS NewWinLimit
         FROM dbo.WinLimit_CustSetting cs WITH (NOLOCK)
              LEFT OUTER JOIN dbo.Customer c WITH (NOLOCK) ON cs.CustID = c.custid
         WHERE c.currency = @ExchangeID
               AND cs.ProductID = @ProductID
               AND cs.MaxWinLimit > @MaxWinLimit;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_GreaterWinLimitPlayerSel] TO [vnteam];
GO