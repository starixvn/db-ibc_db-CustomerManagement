USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingUpd]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd];
GO
USE [CustDB];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd] @ProductId         INT,
                                                         @GroupId           INT,
                                                         @CurrencyId        INT,
                                                         @SiteId            INT,
                                                         @LevelId           INT,
                                                         @MaxWinLimit       MONEY         = 0,
                                                         @IsBlockedPlaceBet BIT           = 0,
                                                         @IsBlockedTransfer BIT           = 0,
                                                         @UserID            INT           = 0,
                                                         @IP                VARCHAR(20)   = '',
                                                         @ErrorCode         INT           = 0 OUTPUT,
                                                         @ErrorMessage      NVARCHAR(500) = '' OUTPUT
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].

Parameters Explanation:	
   @ProductId: Product ID.
   @GroupId: Bettype ID.
   @CurrencyId: Currency ID.
   @SiteId: Site or Licensee ID.
   @LevelId: Level ID.
   @MaxWinLimit: Max Win Limit amount.
   @IsBlockedPlaceBet: Is block place bet.
   @IsBlockedTransfer: Is block transfer.
   @UserID: User making this action.
   @IP: IP of the machine making this action.
   @ErrorCode: Error Code.
   @ErrorMessage: Error Message.
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @TrackingValue1 VARCHAR(500);
     SELECT @StartRun = GETDATE();
     IF EXISTS
     (
         SELECT 1
         FROM dbo.WinLimit_ProductSettingDetail WITH (NOLOCK)
         WHERE ProductID = @ProductId
               AND GroupId = @GroupId
               AND ExchangeID = @CurrencyId
               AND SiteID = @SiteId
               AND LevelID = @LevelId
     )
         BEGIN -- Update
             DECLARE @OldMaxWinLimit MONEY, @OldIsBlockedPlaceBet BIT, @OldIsBlockedTransfer BIT;
             SELECT @OldMaxWinLimit = MaxWinLimit_RM,
                    @OldIsBlockedPlaceBet = IsBlockedPlaceBet,
                    @OldIsBlockedTransfer = IsBlockedTransfer
             FROM dbo.WinLimit_ProductSettingDetail WITH (NOLOCK)
             WHERE ProductID = @ProductId
                   AND GroupId = @GroupId
                   AND ExchangeID = @CurrencyId
                   AND SiteID = @SiteId
                   AND LevelID = @LevelId;
             BEGIN TRY
                 UPDATE s
                   SET
                       s.MaxWinLimit_RM = @MaxWinLimit,
                       s.IsBlockedPlaceBet = @IsBlockedPlaceBet,
                       s.IsBlockedTransfer = @IsBlockedTransfer
                 FROM dbo.WinLimit_ProductSettingDetail s WITH (ROWLOCK)
                 WHERE s.ProductID = @ProductId
                       AND s.GroupId = @GroupId
                       AND s.ExchangeID = @CurrencyId
                       AND s.SiteID = @SiteId
                       AND s.LevelID = @LevelId;
                 EXEC Task_Winlimit_CurrencyMaxWinLimitUpd
                      @IsCurrencySetting = 1,
                      @ProductID = @ProductId,
                      @GroupId = @GroupId,
                      @CurrencyId = @CurrencyId,
                      @SiteID = @SiteId,
                      @LevelID = @LevelId;
             END TRY
             BEGIN CATCH
                 SELECT @ErrorCode = 500,
                        @ErrorMessage = 'There is an error while processing, please try again!';
                 RETURN;
             END CATCH;
             BEGIN -- Write Log
                 SELECT @EndRun = GETDATE(),
                        @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
                 SET @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd ';
                 SET @TrackingValue1 = @TrackingValue1+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
                 SET @TrackingValue1 = @TrackingValue1+'" GroupId="'+CONVERT(VARCHAR(20), @GroupId);
                 SET @TrackingValue1 = @TrackingValue1+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId);
                 SET @TrackingValue1 = @TrackingValue1+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId);
                 SET @TrackingValue1 = @TrackingValue1+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId);
                 SET @TrackingValue1 = @TrackingValue1+'" MaxWinLimit_RM="'+CONVERT(VARCHAR(20), @OldMaxWinLimit);
                 SET @TrackingValue1 = @TrackingValue1+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @OldIsBlockedPlaceBet);
                 SET @TrackingValue1 = @TrackingValue1+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @OldIsBlockedTransfer);
                 SET @TrackingValue1 = @TrackingValue1+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
                 SET @TrackingValue1 = @TrackingValue1+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                 DECLARE @TrackingValue2 VARCHAR(500);
                 SET @TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd ';
                 SET @TrackingValue2 = @TrackingValue2+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
                 SET @TrackingValue2 = @TrackingValue2+'" GroupId="'+CONVERT(VARCHAR(20), @GroupId);
                 SET @TrackingValue2 = @TrackingValue2+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId);
                 SET @TrackingValue2 = @TrackingValue2+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId);
                 SET @TrackingValue2 = @TrackingValue2+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId);
                 SET @TrackingValue2 = @TrackingValue2+'" MaxWinLimit_RM="'+CONVERT(VARCHAR(20), @MaxWinLimit);
                 SET @TrackingValue2 = @TrackingValue2+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @IsBlockedPlaceBet);
                 SET @TrackingValue2 = @TrackingValue2+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @IsBlockedTransfer);
                 SET @TrackingValue2 = @TrackingValue2+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
                 SET @TrackingValue2 = @TrackingValue2+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                 BEGIN TRY
                     EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                          @UserID = @UserID,
                          @ActionID = 31201,
                          @TrackingValue = @TrackingValue1,
                          @TrackingValue2 = @TrackingValue2,
                          @Duration = @Duration;
                 END TRY
                 BEGIN CATCH
                 END CATCH;
             END;
         END;
     ELSE
         BEGIN -- Insert data
             BEGIN TRY
                 INSERT INTO dbo.WinLimit_ProductSettingDetail
                 (ProductID,
                  GroupId,
                  ExchangeID,
                  SiteID,
                  LevelID,
                  MaxWinLimit_RM,
                  IsBlockedPlaceBet,
                  IsBlockedTransfer
                 )
                 VALUES
                 (@ProductId,
                  @GroupId,
                  @CurrencyId,
                  @SiteId,
                  @LevelId,
                  @MaxWinLimit,
                  @IsBlockedPlaceBet,
                  @IsBlockedTransfer
                 );
                 EXEC Task_Winlimit_CurrencyMaxWinLimitUpd
                      @IsCurrencySetting = 1,
                      @ProductID = @ProductId,
                      @GroupId = @GroupId,
                      @CurrencyId = @CurrencyId,
                      @SiteID = @SiteId,
                      @LevelID = @LevelId;
             END TRY
             BEGIN CATCH
                 SELECT @ErrorCode = 500,
                        @ErrorMessage = 'There is an error while processing, please try again!';
                 RETURN;
             END CATCH;
             BEGIN -- Write log
                 SELECT @EndRun = GETDATE(),
                        @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
                 SET @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd ';
                 SET @TrackingValue1 = @TrackingValue1+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
                 SET @TrackingValue1 = @TrackingValue1+'" GroupId="'+CONVERT(VARCHAR(20), @GroupId);
                 SET @TrackingValue1 = @TrackingValue1+'" ExchangeID="'+CONVERT(VARCHAR(20), @CurrencyId);
                 SET @TrackingValue1 = @TrackingValue1+'" SiteID="'+CONVERT(VARCHAR(20), @SiteId);
                 SET @TrackingValue1 = @TrackingValue1+'" LevelID="'+CONVERT(VARCHAR(20), @LevelId);
                 SET @TrackingValue1 = @TrackingValue1+'" MaxWinLimit_RM="'+CONVERT(VARCHAR(20), @MaxWinLimit);
                 SET @TrackingValue1 = @TrackingValue1+'" IsBlockedPlaceBet="'+CONVERT(VARCHAR(20), @IsBlockedPlaceBet);
                 SET @TrackingValue1 = @TrackingValue1+'" IsBlockedTransfer="'+CONVERT(VARCHAR(20), @IsBlockedTransfer);
                 SET @TrackingValue1 = @TrackingValue1+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
                 SET @TrackingValue1 = @TrackingValue1+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
                 BEGIN TRY
                     EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                          @UserID = @UserID,
                          @ActionID = 31201,
                          @TrackingValue = @TrackingValue1,
                          @Duration = @Duration;
                 END TRY
                 BEGIN CATCH
                 END CATCH;
             END;
         END;
     SELECT @ErrorCode = 0,
            @ErrorMessage = '';
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingUpd] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingUpd] TO [vnteam];
GO