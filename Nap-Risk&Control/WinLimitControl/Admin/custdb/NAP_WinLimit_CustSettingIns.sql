USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingIns]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingIns] @CustId       INT,
                                                     @ProductId    INT,
                                                     @GroupId      INT,
                                                     @SiteId       INT,
                                                     @CurrencyId   INT,
                                                     @LevelId      INT,
                                                     @MaxWinLimit  MONEY,
                                                     @UserID       INT           = 0,
                                                     @IP           VARCHAR(20)   = '',
                                                     @ErrorCode    INT           = 0 OUTPUT,
                                                     @ErrorMessage NVARCHAR(500) = '' OUTPUT
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
Parameters Explanation:

Example:	
EXEC [NAP_WinLimit_CustSettingIns] 
   @CustId = 662531, 
   @ProductId =22,
   @GroupId=1,
   @SiteId=16,
   @CurrencyId=1,
   @MaxWinLimit=1000,
   @UserId=1, 
   IP='127.0.0.1'
	
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT;
     SELECT @StartRun = GETDATE();
     BEGIN -- INSERT
         BEGIN TRY
             INSERT INTO dbo.WinLimit_CustGameSetting
             (CustID,
              ProductID,
              GroupId,
              LevelID,
              MaxWinLimit_RM
             )
             VALUES
             (@CustId,
              @ProductId,
              @GroupId,
              @LevelId,
              @MaxWinLimit
             );
             SELECT @ErrorCode = 0,
                    @ErrorMessage = '';
             EXEC dbo.Task_Winlimit_CurrencyMaxWinLimitUpd
                  @IsCurrencySetting = 0,
                  @CustID = @CustID,
                  @ProductID = @ProductId,
                  @GroupId = @GroupId,
                  @LevelID = @LevelId;
         END TRY
         BEGIN CATCH
             SELECT @ErrorCode = 5,
                    @ErrorMessage = 'This setting cannot be inserted because of an database internal error.';
             RETURN;
         END CATCH;
     END;
     BEGIN --LOG
         DECLARE @LogSPData VARCHAR(300);
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SELECT @LogSPData = '<NAP_WinLimit_CustSettingIns ';
         SET @LogSPData = @LogSPData+'"CustId ="'+CONVERT(VARCHAR(20), @CustId);
         SET @LogSPData = @LogSPData+'" ProductId ="'+CONVERT(VARCHAR(20), @ProductId);
         SET @LogSPData = @LogSPData+'" BetTypeId ="'+CONVERT(VARCHAR(20), @GroupId);
         SET @LogSPData = @LogSPData+'" SiteId ="'+CONVERT(VARCHAR(20), @SiteId);
         SET @LogSPData = @LogSPData+'" CurrencyId ="'+CONVERT(VARCHAR(20), @CurrencyId);
         SET @LogSPData = @LogSPData+'" LevelId'+CONVERT(VARCHAR(20), @LevelId);
         SET @LogSPData = @LogSPData+'" MaxWinLimit'+CONVERT(VARCHAR(20), @MaxWinLimit);
         SET @LogSPData = @LogSPData+'" UserID ="'+CONVERT(VARCHAR(20), @UserID);
         SET @LogSPData = @LogSPData+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31203,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
     SELECT @ErrorCode = 0,
            @ErrorMessage = '';
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingIns] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingIns] TO [vnteam];
GO