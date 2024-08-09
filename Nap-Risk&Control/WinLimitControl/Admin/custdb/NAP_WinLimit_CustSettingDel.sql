/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_CustSettingDel] @CustID    INT,
                                                     @ProductID TINYINT,
                                                     @GroupId   INT,
                                                     @UserID    INT         = 0,
                                                     @IP        VARCHAR(20) = ''
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
20170808@Jacob: Risk & Control - Phase 4 [#72870]
20240808@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
Parameters Explanation:	

Example: 	
EXEC [NAP_WinLimit_CustSettingDel] @CustId = 1, @ProductId = 1, @GroupId = 1, @UserId = 0, @IP = ''
*/
BEGIN
     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT;
     DECLARE @MaxWinLimitOld1 MONEY, @MaxWinLimitOld2 MONEY, @MaxWinLimitOld3 MONEY;
     SELECT @StartRun = GETDATE();
     BEGIN -- SAVE Old State
         DECLARE @OldState TABLE
         (LevelId        INT,
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
         DELETE dbo.WinLimit_CustGameSetting
		 OUTPUT DELETED.CustID, DELETED.ProductID, DELETED.GroupID, DELETED.LevelID, SYSDATETIME()
		 INTO WinLimit_CustGameSetting_Del_Inhouse(CustID,ProductID,GroupID,LevelID,RepUpdateTime)
         WHERE CustID = @CustID
               AND ProductID = @ProductID
               AND GroupId = @GroupId;
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
                 WHERE LevelId = @LevelId;
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
END
GO
