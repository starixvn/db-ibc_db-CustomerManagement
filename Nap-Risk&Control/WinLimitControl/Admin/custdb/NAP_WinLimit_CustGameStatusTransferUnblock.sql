USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustGameStatusTransferUnblock]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock] @CustId       INT,
                                                                    @ProductId    INT,
                                                                    @GroupId      INT,
                                                                    @UserID       INT           = 0,
                                                                    @IP           VARCHAR(20)   = '',
                                                                    @ErrorCode    INT           = 0 OUTPUT,
                                                                    @ErrorMessage NVARCHAR(500) = '' OUTPUT
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #38608 - Implement function to control Player's Win Limit on specific Product

DB: DBCust/CustDB

Revisions:
20170313@Jacob: Risk & Control - Phase 3A [#72604].

Parameters Explanation:	

    EXEC [NAP_WinLimit_CustGameStatusTransferUnblock]
    @CustId = 662531,
    @ProductId = 22,
    @GroupId = 1,
    @UserId = 1,
    @IP = '127.0.0.1';
	
*/


     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300), @IsBlockedTransferOld BIT;
     SELECT @StartRun = GETDATE();
     BEGIN -- UPDATE
         BEGIN TRY
             UPDATE s
               SET
                   s.IsBlockedTransfer = 0,
                   s.ActionId = 4,
                   s.ModifiedDate = GETDATE()
             FROM dbo.WinLimit_CustGameStatus s WITH (ROWLOCK, UPDLOCK)
                  INNER JOIN dbo.Winlimit_GameGroupSetting g WITH (NOLOCK) ON s.BettypeID = g.BettypeID
                                                                              AND s.ProductID = g.ProductID
             WHERE s.CustId = @CustId
                   AND s.ProductId = @ProductId
                   AND g.GroupId = @GroupId;
         END TRY
         BEGIN CATCH
             SELECT @ErrorCode = 1,
                    @ErrorMessage = 'The setting of Transfer/Withdraw cannot be changed because of an database internal error.';
             RETURN;
         END CATCH;
     END;
     BEGIN --LOG
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SET @LogSPData = '<NAP_WinLimit_CustGameStatusTransferUnblock ';
         SET @LogSPData = @LogSPData+'"CustId ="'+CONVERT(VARCHAR(20), @CustId);
         SET @LogSPData = @LogSPData+'" ProductId ="'+CONVERT(VARCHAR(20), @ProductId);
         SET @LogSPData = @LogSPData+'" GroupId ="'+CONVERT(VARCHAR(20), @GroupId);
         SET @LogSPData = @LogSPData+'" UserID ="'+CONVERT(VARCHAR(20), @UserID);
         SET @LogSPData = @LogSPData+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31207,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
     SELECT @ErrorCode = 0,
            @ErrorMessage = '';
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustGameStatusTransferUnblock] TO [vnteam];
GO