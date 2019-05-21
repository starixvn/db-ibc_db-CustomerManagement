/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitSummary_Update
	@GameRound      VARCHAR(50)
   , @SportType      SMALLINT
   , @BetType        INT
   , @BetCount       INT
   , @NoOfPlayers    INT
AS
/*	Creator: 20190313@Robert
	Task:  When sent an email to the admin successfully, need to update status and other infomation related to that bet.
	DB: DBTXN/bodb02	
	Revisions: 
		 - 20190313@Robert: #109866 - Risk & Control - Implement Global Game Round Bet Limit Setting and Report/Notification
		
*/

BEGIN
    SET NOCOUNT ON;

    UPDATE g
		 SET
			g.BetCount = @BetCount
		   , g.NoOfPlayers = @NoOfPlayers
		   , g.IsNotified = 1
    FROM GameRoundBetLimitSummary g WITH (ROWLOCK, UPDLOCK)
    WHERE g.GameRound = @GameRound
		AND g.SportType = @SportType
		AND g.BetType = @BetType;
END;
GO