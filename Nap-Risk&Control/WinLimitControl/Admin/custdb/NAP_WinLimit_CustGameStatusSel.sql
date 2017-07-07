USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustGameStatusSel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusSel];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusSel] @CustId    INT,
                                                        @ProductId INT,
                                                        @BetTypeId INT
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #38608 - Implement function to control Player's Win Limit on specific Product

DB: DBCust/CustDB

Revisions:

Parameters Explanation:	

    EXEC [NAP_WinLimit_CustGameStatusSel]
    @CustId = 662531,
    @ProductId = 22,
    @BetTypeId = 4001
	
*/


     SET NOCOUNT ON;
     SELECT IsBlockedPlaceBet,
            IsBlockedTransfer
     FROM dbo.WinLimit_CustGameStatus WITH (NOLOCK)
     WHERE CustID = @CustId
           AND ProductID = @ProductId
           AND BettypeID = @BetTypeId;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustGameStatusSel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustGameStatusSel] TO [vnteam];
GO