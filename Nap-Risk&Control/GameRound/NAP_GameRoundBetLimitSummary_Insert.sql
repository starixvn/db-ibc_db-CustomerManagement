/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,wsv_nap,Dot_Intg" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitSummary_Insert
	@GameRound            VARCHAR(50)
   , @SportType            SMALLINT
   , @BetType              INT
   , @ProductID            TINYINT
   , @GameRoundBetLimit    MONEY
   , @TotalStake           MONEY
   , @ReachedLimitTime     DATETIME
   , @IsTest               BIT = 0
AS
/*	Creator: 20190313@Robert
	Task:  When a game round has been reached a limit, need to capture infomation related to it.
	DB: DBTXN/bodb02	
	Revisions: 
		 - 20190313@Robert: #109866 - Risk & Control - Implement Global Game Round Bet Limit Setting and Report/Notification
		
*/
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
		    (
			   SELECT 1
			   FROM GameRoundBetLimitSummary WITH (NOLOCK)
			   WHERE GameRound = @GameRound
				    AND SportType = @SportType
				    AND BetType = @BetType
		    )
	   RETURN;

    INSERT INTO dbo.GameRoundBetLimitSummary(GameRound
								   , SportType
								   , BetType
								   , ProductID
								   , GameRoundBetLimit
								   , BetCount
								   , NoOfPlayers
								   , TotalStake
								   , ReachedLimitTime
								   , IsNotified
								   , IsTest)
		 (
			SELECT @GameRound AS GameRound
				, @SportType AS SportType
				, @BetType AS BetType
				, @ProductID AS ProductID
				, @GameRoundBetLimit AS GameRoundBetLimit
				, 0 AS BetCount
				, 0 AS NoOfPlayers
				, @TotalStake AS TotalStake
				, @ReachedLimitTime AS ReachedLimitTime
				, 0 AS IsNotified
				, @IsTest AS IsTest
		 );
END;
GO