/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].NAP_WinLimit_CustSettingUpd @CustID       INT,
                                                   @ProductID    INT,
                                                   @GroupId      INT,
                                                   @LevelID      INT,
                                                   @MaxWinLimit  MONEY         = 0,
                                                   @UserID       INT           = 0,
                                                   @IP           VARCHAR(20)   = ''
AS
	
/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
20170808@Jacob: Risk & Control - Phase 4 [#72870]
20240809@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
Parameters Explanation:
	
	
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @MaxWinLimitOld MONEY;
     SELECT @StartRun = GETDATE();
     BEGIN -- SAVE State

         SELECT @MaxWinLimitOld = MaxWinLimit_RM
         FROM dbo.WinLimit_CustGameSetting WITH (NOLOCK)
         WHERE CustID = @CustID
               AND ProductID = @ProductID
               AND GroupId = @GroupId
               AND LevelId = @LevelId;
     END;
     UPDATE dbo.WinLimit_CustGameSetting WITH(ROWLOCK, UPDLOCK)
	   SET
		   MaxWinLimit_RM = @MaxWinLimit,
		   RepUpdateTime = SYSDATETIME()
	 WHERE CustID = @CustID
		   AND ProductID = @ProductID
		   AND Groupid = @GroupId
		   AND LevelId = @LevelId;
		   
	 EXEC Task_Winlimit_CurrencyMaxWinLimitUpd
		  @IsCurrencySetting = 0,
		  @CustID = @CustID,
		  @ProductID = @ProductId,
		  @GroupId = @GroupId,
		  @LevelID = @LevelId;
     BEGIN -- LOG
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
         DECLARE @TrackingValue VARCHAR(300), @TrackingValue2 VARCHAR(300);
         SET @TrackingValue = '<NAP_WinLimit_CustSettingUpd ';
         SET @TrackingValue = @TrackingValue+'" CustID ="'+CONVERT(VARCHAR(20), @CustID);
         SET @TrackingValue = @TrackingValue+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID);
         SET @TrackingValue = @TrackingValue+'" GroupId="'+CONVERT(VARCHAR(20), @GroupId);
         SET @TrackingValue = @TrackingValue+'" LevelID="'+CONVERT(VARCHAR(20), @LevelID);
         SET @TrackingValue = @TrackingValue+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimit);
         SET @TrackingValue = @TrackingValue+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
         SET @TrackingValue = @TrackingValue+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         SET @TrackingValue2 = '<NAP_WinLimit_CustSettingUpd ';
         SET @TrackingValue2 = @TrackingValue2+'" CustID ="'+CONVERT(VARCHAR(20), @CustID);
         SET @TrackingValue2 = @TrackingValue2+'" ProductID="'+CONVERT(VARCHAR(20), @ProductID);
         SET @TrackingValue2 = @TrackingValue2+'" GroupId="'+CONVERT(VARCHAR(20), @GroupId);
         SET @TrackingValue2 = @TrackingValue2+'" LevelID="'+CONVERT(VARCHAR(20), @LevelID);
         SET @TrackingValue2 = @TrackingValue2+'" MaxWinLimit="'+CONVERT(VARCHAR(20), @MaxWinLimitOld);
         SET @TrackingValue2 = @TrackingValue2+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
         SET @TrackingValue2 = @TrackingValue2+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
         SELECT @EndRun = GETDATE(),
                @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);
         BEGIN TRY
             EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                  @UserID = @UserID,
                  @CustID = @CustID,
                  @ActionID = 31204,
                  @TrackingValue = @TrackingValue,
                  @TrackingValue2 = @TrackingValue2,
                  @Duration = @Duration;
         END TRY
         BEGIN CATCH
         END CATCH;
     END;
GO
