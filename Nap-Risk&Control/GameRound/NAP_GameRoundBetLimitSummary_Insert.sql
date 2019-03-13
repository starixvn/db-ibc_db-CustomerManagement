/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitSummary_Insert
	@GameRound           VARCHAR(50)
   , @SportType           SMALLINT
   , @BetType             INT
   , @ProductID           TINYINT
   , @TotalStake          MONEY
   , @ReachedLimitTime    DATETIME
AS
/*	Creator: 20190313@Robert
	Task:  When a game round has been reached a limit, need to capture infomation related to it.
	DB: DBTXN/bodb02	
	Revisions: 
		 - 20190313@Robert: #109866 - Risk & Control - Implement Global Game Round Bet Limit Setting and Report/Notification
		
*/
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.GameRoundBetLimitSummary(GameRound
								   , SportType
								   , BetType
								   , ProductID
								   , BetCount
								   , NoOfPlayers
								   , TotalStake
								   , ReachedLimitTime
								   , IsNotified)
		 SELECT @GameRound AS GameRound
			 , @SportType AS SportType
			 , @BetType AS BetType
			 , @ProductID AS ProductID
			 , 0 AS BetCount
			 , 0 AS NoOfPlayers
			 , @TotalStake AS TotalStake
			 , @ReachedLimitTime AS ReachedLimitTime
			 , 0 AS IsNotified;
END;
GO