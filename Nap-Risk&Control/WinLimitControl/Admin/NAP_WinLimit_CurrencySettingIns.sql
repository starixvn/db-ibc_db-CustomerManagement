USE [bodb02];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CurrencySettingIns]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingIns];
GO
USE [bodb02];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CurrencySettingIns]    Script Date: 07/07/2015 16:10:28 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingIns] @ExchangeID  INT           = 0,
                                                         @ProductID   TINYINT       = 0,
                                                         @MaxWinLimit MONEY,
                                                         @UserID      INT           = 0,
                                                         @IP          VARCHAR(20)   = '',
                                                         @ErrCode     INT           = 0 OUTPUT,
                                                         @ErrMsg      NVARCHAR(500) = '' OUTPUT
AS
	
/*
		Created: Phillip	
		Date: 2015-06-26
		Task: #38608 - Implement function to control Player's Win Limit on specific Product
		
		DB: DBPRO/bodb02
		
		Revisions:
		
		Parameters Explanation:	
			@ExchangeID	: Currency ID.
			@ProductID	: Product ID.
			@MaxWinLimit: Max Win Limit amount.
			@UserID		: User making this action.
			@IP			: IP of the machine making this action.
			@ErrCode	: Error Code.
			@ErrMsg		: Error Message.
	*/

     BEGIN
         SET NOCOUNT ON;
         DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300);
         SELECT @StartRun = GETDATE();
         IF @MaxWinLimit <= 0
             BEGIN
                 SELECT @MaxWinLimit = 0;
             END;
         IF @ExchangeID = 0
            OR @ProductID = 0
             BEGIN
                 SELECT @ErrCode = 5,
                        @ErrMsg = 'Invalid input. ExchangeID = 0 or ProductID = 0.';
                 RETURN;
             END;
         IF EXISTS
         (
             SELECT 1
             FROM dbo.WinLimit_GlobalSetting WITH (NOLOCK)
             WHERE ExchangeID = @ExchangeID
                   AND ProductID = @ProductID
         )
             BEGIN
                 SELECT @ErrCode = 1,
                        @ErrMsg = 'This setting is already set.';
                 RETURN;
             END;
         BEGIN TRY
             INSERT INTO dbo.WinLimit_GlobalSetting
             (ProductID,
              ExchangeID,
              MaxWinLimit
             )
             VALUES
             (@ProductID,
              @ExchangeID,
              @MaxWinLimit
             );
         END TRY
         BEGIN CATCH
             IF @@ERROR <> 0
                 BEGIN
                     SELECT @ErrCode = 1,
                            @ErrMsg = ERROR_MESSAGE();
                     RETURN;
                 END;
         END CATCH;
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         SELECT @LogSPData = '<NAP_WinLimit_CurrencySettingIns '+'" ExchangeID ="'+CONVERT( VARCHAR(20), @ExchangeID)+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @ActionID = 31201,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
             SELECT @LogSPData = '<NAP_WinLimit_CurrencySettingIns '+'" ExchangeID ="'+CONVERT( VARCHAR(20), @ExchangeID)+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID)+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit)+'" UserId="'+CONVERT(VARCHAR(20), @UserId)+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" ErrMsg="'+COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(400)), SPACE(1))+'" />';
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @ActionID = 31201,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END CATCH;
     END;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CurrencySettingIns] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CurrencySettingIns] TO [vnteam];
GO