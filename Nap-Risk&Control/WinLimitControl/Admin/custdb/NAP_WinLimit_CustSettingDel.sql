USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_CustSettingDel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_CustSettingDel];
GO
USE [CustDB];
GO

/****** Object:  StoredProcedure [dbo].[NAP_WinLimit_CustSettingDel]    Script Date: 07/07/2015 16:09:41 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_CustSettingDel] @CustID       INT,
                                                     @ProductID    TINYINT,
                                                     @GroupId      INT,
                                                     @UserID       INT           = 0,
                                                     @IP           VARCHAR(20)   = '',
                                                     @ErrorCode    INT           = 0 OUTPUT,
                                                     @ErrorMessage NVARCHAR(200) = '' OUTPUT
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
EXEC [NAP_WinLimit_CustSettingDel] @CustId = 1, @ProductId = 1, @GroupId = 1, @UserId = 0, @IP = ''
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT;
     DECLARE @MaxWinLimitOld1 MONEY, @MaxWinLimitOld2 MONEY, @MaxWinLimitOld3 MONEY;
     SELECT @StartRun = GETDATE();
     BEGIN -- SAVE Old State
         DECLARE @OldState TABLE
         (LevelId     INT,
          MaxWinLimit_RM MONEY
         );
         INSERT INTO @OldState
                SELECT LevelId,
                       MaxWinLimit_RM
                FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
                WHERE CustID = @CustID
                      AND ProductID = @ProductID
                      AND GroupId = @GroupId;
     END;
     BEGIN -- Delete
         BEGIN TRY
             DELETE dbo.WinLimit_CustGameSetting
             WHERE CustID = @CustID
                   AND ProductID = @ProductID
                   AND GroupId = @GroupId;
         END TRY
         BEGIN CATCH
             SELECT @ErrorCode = 2,
                    @ErrorMessage = 'This setting cannot be deleted because of an database internal error.';
             RETURN;
         END CATCH;
     END;
     BEGIN -- Log
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         DECLARE @LogSPData VARCHAR(300);
         DECLARE @LevelId INT, @MaxWinLimitOld MONEY;
         SET @LogSPData = '<NAP_WinLimit_CustSettingDel ';
         SET @LogSPData = @LogSPData+'" CustID ="'+CONVERT(VARCHAR(20), @CustID);
         SET @LogSPData = @LogSPData+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID);
         SET @LogSPData = @LogSPData+'" GroupId="'+CONVERT(VARCHAR(20), @GroupId);
         WHILE EXISTS
         (
             SELECT 1
             FROM @OldState
         )
             BEGIN
                 SELECT @LevelId = LevelId,
                        @MaxWinLimitOld = MaxWinLimit_RM
                 FROM @OldState;
                 SET @LogSPData = @LogSPData+'" MaxWinLimitLevel'+CONVERT(VARCHAR(20), @LevelId)+'="'+CONVERT(VARCHAR(20), @MaxWinLimitOld);
                 DELETE @OldState
                 WHERE LevelId = @LevelId
             END;
         SET @LogSPData = @LogSPData+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
         SET @LogSPData = @LogSPData+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31206,
                  @TrackingValue = @LogSPData,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
     SELECT @ErrorCode = 0,
            @ErrorMessage = '';
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_CustSettingDel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_CustSettingDel] TO [vnteam];
GO