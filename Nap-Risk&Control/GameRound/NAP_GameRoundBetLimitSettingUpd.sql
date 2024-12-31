/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_GameRoundBetLimitSettingUpd] 
	@ProductID         INT,
    @SportType         INT,
    @BetType           INT,
    @GameRoundBetLimit MONEY,
    @UserID            INT         = 0,
    @IP                VARCHAR(20) = ''
AS

/*
	Created: Jacob	
	Date: 2019-03-12
	Task: #109866 - Implement Game Ground Bet Limit Control

	DB: DBCUST/CustDB

	Revisions:
		- 20190312@Jacob: Implement Game Ground Bet Limit Control [#109866].
		- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
*/

     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @TrackingValue1 VARCHAR(500);
     SELECT @StartRun = GETDATE();
     IF EXISTS
(
    SELECT 1
    FROM dbo.GameRoundBetLimitSettings WITH (NOLOCK)
    WHERE ProductID = @ProductId
          AND SportType = @SportType
          AND BetType = @BetType
)
         BEGIN -- Update
             DECLARE @OldGameRoundBetLimit MONEY;
             SELECT @OldGameRoundBetLimit = GameRoundBetLimit
             FROM dbo.GameRoundBetLimitSettings WITH (NOLOCK)
             WHERE ProductID = @ProductId
                   AND SportType = @SportType
                   AND BetType = @BetType;
            
			UPDATE dbo.GameRoundBetLimitSettings WITH(ROWLOCK)
               SET
                   GameRoundBetLimit = @GameRoundBetLimit
                  ,RepUpdateTime = dbo.f_GetDateTime2()
			 WHERE ProductID = @ProductId
                   AND SportType = @SportType
                   AND BetType = @BetType;
             
			 SELECT @EndRun = GETDATE(),
                    @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
             SET @TrackingValue1 = '<NAP_GameRoundBetLimitSettingUpd ';
             SET @TrackingValue1 = @TrackingValue1+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
             SET @TrackingValue1 = @TrackingValue1+'" SportType="'+CONVERT(VARCHAR(20), @SportType);
             SET @TrackingValue1 = @TrackingValue1+'" BetType="'+CONVERT(VARCHAR(20), @BetType);
             SET @TrackingValue1 = @TrackingValue1+'" GameRoundBetLimit="'+CONVERT(VARCHAR(20), @OldGameRoundBetLimit);
             SET @TrackingValue1 = @TrackingValue1+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
             SET @TrackingValue1 = @TrackingValue1+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
             DECLARE @TrackingValue2 VARCHAR(500);
             SET @TrackingValue2 = '<NAP_GameRoundBetLimitSettingUpd ';
             SET @TrackingValue2 = @TrackingValue2+'" ProductID ="'+CONVERT(VARCHAR(20), @ProductId);
             SET @TrackingValue2 = @TrackingValue2+'" SportType="'+CONVERT(VARCHAR(20), @SportType);
             SET @TrackingValue2 = @TrackingValue2+'" BetType="'+CONVERT(VARCHAR(20), @BetType);
             SET @TrackingValue2 = @TrackingValue2+'" GameRoundBetLimit="'+CONVERT(VARCHAR(20), @GameRoundBetLimit);
             SET @TrackingValue2 = @TrackingValue2+'" UserId="'+CONVERT(VARCHAR(20), @UserId);
             SET @TrackingValue2 = @TrackingValue2+'" IP="'+COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1))+'" />';
             BEGIN TRY
                 EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
                      @UserID = @UserID,
                      @ActionID = 31601,
                      @TrackingValue = @TrackingValue1,
                      @TrackingValue2 = @TrackingValue2,
                      @Duration = @Duration;
             END TRY
             BEGIN CATCH
             END CATCH;
         END;
        
GO
