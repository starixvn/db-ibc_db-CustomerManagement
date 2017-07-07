USE [bodb02];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_Winlimit_DebitGameReset]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_Winlimit_DebitGameReset];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_Winlimit_DebitGameReset] @CustId  INT,
                                                     @GroupId INT
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #38608 - Implement function to control Player's Win Limit on specific Product

DB: DBCust/bodb02

Revisions:
20170313@Jacob: Risk & Control - Phase 3A [#72604].

Parameters Explanation:	
EXEC [NAP_Winlimit_DebitGameReset] 
   @CustId = 662531, 
   @GroupId=1
	
*/

     SET NOCOUNT ON;
     BEGIN -- UPDATE
         BEGIN TRY
             UPDATE cg
               SET
                   cg.WinLost = 0
             FROM dbo.Winlimit_DebitGame cg WITH (ROWLOCK, UPDLOCK)
             WHERE cg.CustId = @CustId
                   AND cg.BetType IN
             (
                 SELECT BetTypeId
                 FROM DBCUST.CustDB.dbo.Winlimit_GameGroupSetting WITH (NOLOCK)
                 WHERE GroupId = @GroupId
             );
         END TRY
         BEGIN CATCH
             SELECT 1 AS ErrorCode,
                    'The debit win limit cannot be reseted because of an database internal error.' AS ErrorMessage;
             RETURN;
         END CATCH;
     END;
     SELECT 0 AS ErrorCode,
            '' AS ErrorMessage;
GO
GRANT EXECUTE ON [dbo].[NAP_Winlimit_DebitGameReset] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_Winlimit_DebitGameReset] TO [vnteam];
GO