USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustGameStatusPlaceBetUnblock]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusPlaceBetUnblock];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustGameStatusPlaceBetUnblock] @CustId    INT,
                                                                    @ProductId INT,
                                                                    @GroupId   INT,
                                                                    @UserID    INT         = 0,
                                                                    @IP        VARCHAR(20) = ''
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #38608 - Implement function to control Player's Win Limit on specific Product

DB: DBCust/CustDB

Revisions:
20170313@Jacob: Risk & Control - Phase 3A [#72604].
20170808@Jacob: Risk & Control - Phase 4 [#72870]
Parameters Explanation:	

    EXEC [NAP_WinLimit_CustGameStatusPlaceBetUnblock]
    @CustId = 662531,
    @ProductId = 22,
    @GroupId = 1,    
    @UserId = 1,
    @IP = '127.0.0.1';
	
*/


     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300);
     SELECT @StartRun = GETDATE();
     BEGIN -- UPDATE
         UPDATE s
           SET
               s.IsBlockedPlaceBet = 0,
               s.ActionId = 2,
               s.ModifiedDate = GETDATE()
         FROM dbo.WinLimit_CustGameStatus s WITH (ROWLOCK, UPDLOCK)
              INNER JOIN dbo.Winlimit_GameGroupSetting g WITH (NOLOCK) ON s.BettypeID = g.BettypeID
                                                                          AND s.ProductID = g.ProductID
         WHERE s.CustId = @CustId
               AND s.ProductId = @ProductId
               AND g.GroupId = @GroupId;
     END;
     BEGIN --LOG

         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SET @LogSPData = '<NAP_WinLimit_CustGameStatusPlaceBetUnblock ';
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
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustGameStatusPlaceBetUnblock] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustGameStatusPlaceBetUnblock] TO [vnteam];
GO